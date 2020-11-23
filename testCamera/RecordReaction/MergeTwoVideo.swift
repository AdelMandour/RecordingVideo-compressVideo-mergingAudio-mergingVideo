//
//  MergeTwoVideo.swift
//  testCamera
//
//  Created by Adel Mohy on 11/12/20.
//

import Foundation
import AVKit
import Photos
class MergeTwoVideos{
    func newoverlay(video firstAsset: AVURLAsset, withSecondVideo secondAsset: AVURLAsset, audio audioAsset: AVAsset?, compeletionHandeler: @escaping (_ outputURL:URL)->()) {
        
        // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
        let mixComposition = AVMutableComposition()
        
        // 2 - Create two video tracks
        guard let firstTrack = mixComposition.addMutableTrack(withMediaType: .video,
                                                              preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { return }
        do {
            try firstTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: firstAsset.duration),
                                           of: firstAsset.tracks(withMediaType: .video)[0],
                                           at: CMTime.zero)
        } catch {
            print("Failed to load first track")
            return
        }
        
        guard let secondTrack = mixComposition.addMutableTrack(withMediaType: .video,
                                                               preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { return }
        do {
            try secondTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: secondAsset.duration),
                                            of: secondAsset.tracks(withMediaType: .video)[0],
                                            at: CMTime.zero)
        } catch {
            print("Failed to load second track")
            return
        }
        
        // 2.1
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: CMTimeAdd(firstAsset.duration, secondAsset.duration))
        
        // 2.2
        let firstInstruction = MergeTwoVideos.videoCompositionInstruction(firstTrack, asset: firstAsset)
        let scale = CGAffineTransform(scaleX: 0.4, y: 0.5)
        let move = CGAffineTransform(translationX: 120, y: 50)
        firstInstruction.setTransform(scale.rotated(by: CGFloat(90 * CGFloat.pi / 180)).concatenating(move), at: CMTime.zero)
        let secondInstruction = MergeTwoVideos.videoCompositionInstruction(secondTrack, asset: secondAsset)
//        let scale2  = CGAffineTransform(scaleX: 1, y: 1)
//        let move2 = CGAffineTransform(translationX: 10, y: 100)
//        secondInstruction.setTransform(scale2.concatenating(move2), at: .zero)
        // 2.3
        mainInstruction.layerInstructions = [firstInstruction, secondInstruction]
        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        //        let width = max(firstTrack.naturalSize.width, secondTrack.naturalSize.width)
        //        let height = max(firstTrack.naturalSize.height, secondTrack.naturalSize.height)
        
        mainComposition.renderSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        
        mainInstruction.backgroundColor = UIColor.clear.cgColor
        
        if let loadedAudioAsset = audioAsset {
            let audioTrack = mixComposition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: 0)
            do {
                if firstAsset.duration > secondAsset.duration{
                    try audioTrack?.insertTimeRange(
                        CMTimeRangeMake(
                            start: .zero,
                            duration: firstAsset.duration),
                        of: loadedAudioAsset.tracks(withMediaType: .audio)[0],
                        at: .zero)
                }else{
                    try audioTrack?.insertTimeRange(
                        CMTimeRangeMake(
                            start: .zero,
                            duration: secondAsset.duration),
                        of: loadedAudioAsset.tracks(withMediaType: .audio)[0],
                        at: .zero)
                }
            } catch {
                print("Failed to load Audio track")
            }
        }
        // 4 - Get path
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let url = documentDirectory.appendingPathComponent("mergeVideo-.mp4")
        
        // Check exists and remove old file
        FileManager.default.removeItemIfExisted(url as URL)
        
        // 5 - Create Exporter
        guard let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else { return }
        exporter.outputURL = url
        exporter.outputFileType = AVFileType.mp4
        exporter.shouldOptimizeForNetworkUse = true
        exporter.videoComposition = mainComposition
        
        
        // 6 - Perform the Export
        exporter.exportAsynchronously() {
            DispatchQueue.main.async {
                
                print("Movie complete")
                
                //                let videoOutputUrl = url as URL
                
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url as URL)
                }) { saved, error in
                    if saved {
                        print("Saved")
                        compeletionHandeler(url)
                    }
                }
                
            }
        }
    }
    
    static func videoCompositionInstruction(_ track: AVCompositionTrack, asset: AVAsset) -> AVMutableVideoCompositionLayerInstruction {
      // 1
      let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)

      // 2
      let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]

      // 3
      let transform = assetTrack.preferredTransform
      let assetInfo = orientationFromTransform(transform)

      var scaleToFitRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.width
      if assetInfo.isPortrait {
        // 4
        scaleToFitRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.height
        let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
        instruction.setTransform(assetTrack.preferredTransform.concatenating(scaleFactor), at: .zero)
      } else {
        // 5
        let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
        var concat = assetTrack.preferredTransform.concatenating(scaleFactor)
          .concatenating(CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.width / 2))
        if assetInfo.orientation == .down {
          let fixUpsideDown = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
          let windowBounds = UIScreen.main.bounds
          let yFix = assetTrack.naturalSize.height + windowBounds.height
          let centerFix = CGAffineTransform(
            translationX: assetTrack.naturalSize.width,
            y: yFix)
          concat = fixUpsideDown.concatenating(centerFix).concatenating(scaleFactor)
        }
        instruction.setTransform(concat, at: .zero)
      }

      return instruction
    }
    
    static func orientationFromTransform( _ transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false
        let tfA = transform.a
        let tfB = transform.b
        let tfC = transform.c
        let tfD = transform.d
        
        if tfA == 0 && tfB == 1.0 && tfC == -1.0 && tfD == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if tfA == 0 && tfB == -1.0 && tfC == 1.0 && tfD == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if tfA == 1.0 && tfB == 0 && tfC == 0 && tfD == 1.0 {
            assetOrientation = .up
        } else if tfA == -1.0 && tfB == 0 && tfC == 0 && tfD == -1.0 {
            assetOrientation = .down
        }
        return (assetOrientation, isPortrait)
    }
}
extension FileManager {
    func removeItemIfExisted(_ url:URL) -> Void {
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(atPath: url.path)
            }
            catch {
                print("Failed to delete file")
            }
        }
    }
}
