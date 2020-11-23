//
//  MergeTwoAudio.swift
//  testCamera
//
//  Created by Adel Mohy on 11/12/20.
//

import Foundation
import AVKit
import Photos

class MergeTwoAudios{
    var talentVideo:URL!
    var fanVideo:URL!
    var audioMixParams:[AVAudioMixInputParameters]!
    var videoMerger:MergeTwoVideos!
    init() {
        audioMixParams  = [AVAudioMixInputParameters]()
        videoMerger = MergeTwoVideos()
    }
    func mergeTwoAudiosFromVideo(VideoUrl1:String, VideoUrl2:String, compeletionHandeler:@escaping (_ url:URL)->()){
        self.fanVideo = URL(fileURLWithPath: VideoUrl1)
        self.talentVideo = URL(fileURLWithPath: VideoUrl2)
        let name1 = (VideoUrl1 as NSString).lastPathComponent
        let url1 = URL(fileURLWithPath: VideoUrl1)
        let name2 = (VideoUrl2 as NSString).lastPathComponent
        let url2 = URL(fileURLWithPath: VideoUrl2)
        self.extractAudioAndExport(sourceURl: url1, outfileName: name1) { (firstAudioURL) in
            self.extractAudioAndExport(sourceURl: url2, outfileName: name2) { (secondAudioURL) in
                self.saveRecording(urlPath1: firstAudioURL, urlPath2: secondAudioURL) { (recordSourcePath, error) in
                    if error != nil{
                        print(error)
                    }else{
                        let mainAudio = URL(fileURLWithPath: recordSourcePath!)
                        let url1 = URL(fileURLWithPath: VideoUrl1)
                        let url2 = URL(fileURLWithPath: VideoUrl2)
                        let asset1 = AVURLAsset(url: url1)
                        let asset2 = AVURLAsset(url: url2)
                        let audio = AVAsset(url: mainAudio)
                        self.videoMerger.newoverlay(video: asset1, withSecondVideo: asset2, audio: audio, compeletionHandeler: { url in
                            compeletionHandeler(url)
                        })
                    }
                }
            }
        }
    }
   private func setUpAndAddAudioAtPath(_ assetURL: URL?, to composition: AVMutableComposition?) {
        var songAsset: AVURLAsset? = nil
        if let assetURL = assetURL {
            songAsset = AVURLAsset(url: assetURL, options: nil)
        }
        
        let track = composition?.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        let sourceAudioTrack = songAsset?.tracks(withMediaType: .audio)[0]
        
        var _: Error? = nil
        var ok = false
        
        let startTime = CMTimeMakeWithSeconds(Float64(0), preferredTimescale: 1)
        let trackDuration = songAsset?.duration
        //CMTime longestTime = CMTimeMake(848896, 44100); //(19.24 seconds)
        var tRange: CMTimeRange? = nil
        if let trackDuration = trackDuration {
            tRange = CMTimeRangeMake(start: startTime, duration: trackDuration)
        }
        
        //Set Volume
        let trackMix = AVMutableAudioMixInputParameters(track: track)
        if assetURL == talentVideo{
            trackMix.setVolume(0.4, at: startTime)
        }else{
            trackMix.setVolume(0.8, at: startTime)
        }
        audioMixParams.append(trackMix)
        
        //Insert audio into track
        do {
            ok = ((try track?.insertTimeRange(tRange!, of: sourceAudioTrack!, at: CMTimeMake(value: 0, timescale: 44100))) != nil)
        } catch {
        }
    }
  private  func saveRecording(urlPath1:URL, urlPath2:URL,_ completionHandler: @escaping (_ outPutURL:String?, _ error:Error?)->()) {
        let composition = AVMutableComposition()
        audioMixParams = []
        
        //IMPLEMENT FOLLOWING CODE WHEN WANT TO MERGE ANOTHER AUDIO FILE
        //Add Audio Tracks to Composition
        let assetURL1 = URL(fileURLWithPath: urlPath1.absoluteString)
        setUpAndAddAudioAtPath(assetURL1, to: composition)
        
        let assetURL2 = URL(fileURLWithPath: urlPath2.absoluteString)
        setUpAndAddAudioAtPath(assetURL2, to: composition)
        
        let audioMix = AVMutableAudioMix()
        audioMix.inputParameters = audioMixParams
        
        //If you need to query what formats you can export to, here's a way to find out
        print("compatible presets for songAsset: \(AVAssetExportSession.exportPresets(compatibleWith: composition))")
        
        let exporter = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetAppleM4A)
        exporter?.audioMix = audioMix
        exporter?.outputFileType = AVFileType.m4a
        // Create output url
        let currentFileName = "recording-merge.m4a"
        print(currentFileName)
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputUrl = documentsDirectory.appendingPathComponent(currentFileName)
        FileManager.default.removeItemIfExisted(outputUrl as URL)
        exporter?.outputURL = outputUrl
        
        // do the export
        exporter?.exportAsynchronously(completionHandler: {
            let exportStatus = exporter?.status
            let exportError = exporter?.error
            
            switch exportStatus {
            case .failed:
                completionHandler(nil, exportError)
            case .completed:
                completionHandler(exporter?.outputURL?.path, nil)
                print("AVAssetExportSessionStatusCompleted")
            case .unknown:
                print("AVAssetExportSessionStatusUnknown")
            case .exporting:
                print("AVAssetExportSessionStatusExporting")
            case .cancelled:
                print("AVAssetExportSessionStatusCancelled")
            case .waiting:
                print("AVAssetExportSessionStatusWaiting")
            default:
                print("didn't get export status")
            }
        })
    }
    private func extractAudioAndExport(sourceURl:URL, outfileName:String, completion: @escaping (_ outputUrl:URL) -> ()) {
        // Create a composition
        let composition = AVMutableComposition()
        do {
            let asset = AVURLAsset(url: sourceURl)
            guard let audioAssetTrack = asset.tracks(withMediaType: AVMediaType.audio).first else { return }
            guard let audioCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
            try audioCompositionTrack.insertTimeRange(audioAssetTrack.timeRange, of: audioAssetTrack, at: CMTime.zero)
        } catch {
            print(error)
        }
        
        // Get url for output
        let outputUrl = URL(fileURLWithPath: NSTemporaryDirectory() + "\(outfileName).m4a")
        FileManager.default.removeItemIfExisted(outputUrl as URL)
        
        // Create an export session
        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)!
        exportSession.outputFileType = AVFileType.m4a
        exportSession.outputURL = outputUrl
        
        // Export file
        exportSession.exportAsynchronously {
            guard case exportSession.status = AVAssetExportSession.Status.completed else { return }
            
            DispatchQueue.main.async {
                // Present a UIActivityViewController to share audio file
                guard let outputURL = exportSession.outputURL else { return }
                completion(outputURL)
            }
        }
    }
}
