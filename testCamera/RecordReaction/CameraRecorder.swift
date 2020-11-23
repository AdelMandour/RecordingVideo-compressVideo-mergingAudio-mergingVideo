//
//  CameraRecorder.swift
//  testCamera
//
//  Created by Adel Mohy on 11/12/20.
//

import Foundation
import AVKit
import Photos
protocol CameraRecorderDelegate:class {
    func finishedSavingWithURl(outputURL:URL)
}
class CameraRecorder:NSObject, AVCaptureFileOutputRecordingDelegate {
    private  let captureSession = AVCaptureSession()
    
    private  let movieOutput = AVCaptureMovieFileOutput()
    
    private  var previewLayer: AVCaptureVideoPreviewLayer!
    
    private var activeInput: AVCaptureDeviceInput!
    var outputURL: URL!
    var counter:Double!
    
    var camPreview: UIView!
    
    var videoCompression:VideoCompression!
    var delegate:CameraRecorderDelegate!
    var timer : Timer!
    func setupPreview() {
        // Configure previewLayer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = camPreview.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        camPreview.layer.addSublayer(previewLayer)
    }
    //MARK:- Setup Camera
    
    func setupSession() -> Bool {
        captureSession.sessionPreset = AVCaptureSession.Preset.medium
        videoCompression = VideoCompression()
        // Setup Camera
        let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)!
        //        let camera = getDevice(position: .front)
        //            default(for: AVMediaType.video)!
        
        do {
            
            let input = try AVCaptureDeviceInput(device: camera)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                activeInput = input
            }
        } catch {
            print("Error setting device video input: \(error)")
            return false
        }
        
        // Setup Microphone
        let microphone = AVCaptureDevice.default(for: AVMediaType.audio)!
        
        do {
            let micInput = try AVCaptureDeviceInput(device: microphone)
            if captureSession.canAddInput(micInput) {
                captureSession.addInput(micInput)
            }
        } catch {
            print("Error setting device audio input: \(error)")
            return false
        }
        
        
        // Movie output
        movieOutput.movieFragmentInterval = .invalid
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        }
        
        captureSession.commitConfiguration()
        return true
    }
    
    func setupCaptureMode(_ mode: Int) {
        // Video Mode
        
    }
    
    //MARK:- Camera Session
    func startSession() {
        
        if !captureSession.isRunning {
            videoQueue().async {
                self.captureSession.startRunning()
            }
        }
    }
    @objc func updateCounter() {
        //example functionality
        if counter > 0 {
            counter -= 1
        }else{
            self.timer.invalidate()
            stopSession()
            stopRecording()
        }
    }
    
    func stopSession() {
        if captureSession.isRunning {
            videoQueue().async {
                self.captureSession.stopRunning()
            }
        }
    }
    
    func videoQueue() -> DispatchQueue {
        return DispatchQueue.main
    }
    
    func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation
        
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = AVCaptureVideoOrientation.portrait
        case .landscapeRight:
            orientation = AVCaptureVideoOrientation.landscapeLeft
        case .portraitUpsideDown:
            orientation = AVCaptureVideoOrientation.portraitUpsideDown
        default:
            orientation = AVCaptureVideoOrientation.landscapeRight
        }
        
        return orientation
    }
    
    @objc func startCapture() {
        
        startRecording()
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
        
    }
    
    //EDIT 1: I FORGOT THIS AT FIRST
    
    func tempURL() -> URL? {
        let directory = NSTemporaryDirectory() as NSString
        
        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }
        
        return nil
    }
    func startRecording() {
        
        if movieOutput.isRecording == false {
            
            let connection = movieOutput.connection(with: AVMediaType.video)
            
            if (connection?.isVideoOrientationSupported)! {
                connection?.videoOrientation = currentVideoOrientation()
            }
            
            if (connection?.isVideoStabilizationSupported)! {
                connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
            }
            
            let device = activeInput.device
            
            if (device.isSmoothAutoFocusSupported) {
                
                do {
                    try device.lockForConfiguration()
                    device.isSmoothAutoFocusEnabled = false
                    device.unlockForConfiguration()
                } catch {
                    print("Error setting configuration: \(error)")
                }
                
            }
            
            //EDIT2: And I forgot this
            outputURL = tempURL()
            movieOutput.startRecording(to: outputURL, recordingDelegate: self)
            
        }
        else {
            stopRecording()
        }
        
    }
    
    func stopRecording() {
        
        if movieOutput.isRecording == true {
            movieOutput.stopRecording()
        }
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        if (error != nil) {
            
            print("Error recording movie: \(error!.localizedDescription)")
            
        } else {
            
            let videoRecorded = outputURL! as URL
            self.checkFileSize(sizeUrl: videoRecorded, message: "The file size of the original file is: ")
            //            PHPhotoLibrary.shared().performChanges({
            //                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.outputURL)
            //            }) { saved, error in
            //                if saved {
            //                    print("saved")
            //                }
            //            }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
            let date = Date()
            let documentsPath = NSTemporaryDirectory()
            let outputPath = "\(documentsPath)/\(formatter.string(from: date)).mp4"
            let newOutputUrl = URL(fileURLWithPath: outputPath)
            videoCompression.compressFile(urlToCompress: outputURL, outputURL: newOutputUrl) { (url) in
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }) { saved, error in
                    if saved {
                        print("saved")
                        self.delegate.finishedSavingWithURl(outputURL: url)
                    }
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

