//
//  VideoCompression.swift
//  testCamera
//
//  Created by Adel Mohy on 11/12/20.
//

import Foundation
import AVKit
class VideoCompression{
    private var assetWriter:AVAssetWriter?
    private var assetReader:AVAssetReader?
    private let bitrate:NSNumber = NSNumber(value:600000)
    
    func compressFile(urlToCompress: URL, outputURL: URL, completion:@escaping (URL)->Void){
        //video file to make the asset
        
        var audioFinished = false
        var videoFinished = false
        
        
        
        let asset = AVAsset(url: urlToCompress);
        
        //create asset reader
        do{
            assetReader = try AVAssetReader(asset: asset)
        } catch{
            assetReader = nil
        }
        
        guard let reader = assetReader else{
            fatalError("Could not initalize asset reader probably failed its try catch")
        }
        
        let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first!
        let audioTrack = asset.tracks(withMediaType: AVMediaType.audio).first!
        
        let videoReaderSettings: [String:Any] =  [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32ARGB ]
        
        // ADJUST BIT RATE OF VIDEO HERE
        
        let videoSettings:[String:Any] = [
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey:self.bitrate],
            AVVideoCodecKey: AVVideoCodecType.hevc,
            AVVideoHeightKey: videoTrack.naturalSize.height,
            AVVideoWidthKey: videoTrack.naturalSize.width
        ]
        
        
        let assetReaderVideoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderSettings)
        let assetReaderAudioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)
        
        
        if reader.canAdd(assetReaderVideoOutput){
            reader.add(assetReaderVideoOutput)
        }else{
            fatalError("Couldn't add video output reader")
        }
        
        if reader.canAdd(assetReaderAudioOutput){
            reader.add(assetReaderAudioOutput)
        }else{
            fatalError("Couldn't add audio output reader")
        }
        
        //        let audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: nil)
        let videoAsset = AVURLAsset(url: urlToCompress as URL, options: nil)
        let audioTrack2 = videoAsset.tracks(withMediaType: AVMediaType.audio)[0]
        let audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: nil, sourceFormatHint: (audioTrack2.formatDescriptions[0] as! CMFormatDescription))
        let videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        videoInput.transform = videoTrack.preferredTransform
        //we need to add samples to the video input
        
        let videoInputQueue = DispatchQueue(label: "videoQueue")
        let audioInputQueue = DispatchQueue(label: "audioQueue")
        
        do{
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mp4)
        }catch{
            assetWriter = nil
        }
        guard let writer = assetWriter else{
            fatalError("assetWriter was nil")
        }
        
        writer.shouldOptimizeForNetworkUse = true
        writer.add(videoInput)
        writer.add(audioInput)
        
        
        writer.startWriting()
        reader.startReading()
        writer.startSession(atSourceTime: CMTime.zero)
        
        
        let closeWriter:()->Void = {
            if (audioFinished && videoFinished){
                self.assetWriter?.finishWriting(completionHandler: {
                    
                    self.checkFileSize(sizeUrl: (self.assetWriter?.outputURL)!, message: "The file size of the compressed file is: ")
                    
                    completion((self.assetWriter?.outputURL)!)
                    
                })
                
                self.assetReader?.cancelReading()
                
            }
        }
        
        
        audioInput.requestMediaDataWhenReady(on: audioInputQueue) {
            while(audioInput.isReadyForMoreMediaData){
                let sample = assetReaderAudioOutput.copyNextSampleBuffer()
                if (sample != nil){
                    audioInput.append(sample!)
                }else{
                    audioInput.markAsFinished()
                    DispatchQueue.main.async {
                        audioFinished = true
                        closeWriter()
                    }
                    break;
                }
            }
        }
        
        videoInput.requestMediaDataWhenReady(on: videoInputQueue) {
            //request data here
            
            while(videoInput.isReadyForMoreMediaData){
                let sample = assetReaderVideoOutput.copyNextSampleBuffer()
                if (sample != nil){
                    videoInput.append(sample!)
                }else{
                    videoInput.markAsFinished()
                    DispatchQueue.main.async {
                        videoFinished = true
                        closeWriter()
                    }
                    break;
                }
            }
            
        }
    }
    func checkFileSize(sizeUrl: URL, message:String){
        let data = NSData(contentsOf: sizeUrl)!
        print(sizeUrl)
        print(message, (Double(data.length) / 1048576.0), " mb")
    }
}
