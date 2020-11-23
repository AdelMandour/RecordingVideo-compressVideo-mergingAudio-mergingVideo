////
////  ViewController.swift
////  testCamera
////
////  Created by Adel Mohy on 11/9/20.
////
//
//import UIKit
//import AVFoundation
//import Photos
//class ViewController: UIViewController,AVCaptureFileOutputRecordingDelegate {
//    @IBOutlet weak var seconds: UILabel!
//    @IBOutlet weak var resLabel: UILabel!
//    @IBOutlet weak var camPreview: UIView!
//    
//    let cameraButton = UIView()
//    
//    let captureSession = AVCaptureSession()
//    
//    let movieOutput = AVCaptureMovieFileOutput()
//    
//    var previewLayer: AVCaptureVideoPreviewLayer!
//    
//    var activeInput: AVCaptureDeviceInput!
//    
//    var outputURL: URL!
//    var counter = 59
//    var assetWriter:AVAssetWriter?
//    var assetReader:AVAssetReader?
//    let bitrate:NSNumber = NSNumber(value:1500000)
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        // Do any additional setup after loading the view.
//        if setupSession() {
//            setupPreview()
//            startSession()
//        }
//        
//        cameraButton.isUserInteractionEnabled = true
//        
//        let cameraButtonRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.startCapture))
//        
//        cameraButton.addGestureRecognizer(cameraButtonRecognizer)
//        
//        cameraButton.frame = CGRect(x: self.view.center.x, y: self.view.center.y, width: 30, height: 30)
//        
//        cameraButton.backgroundColor = UIColor.red
//        
//        camPreview.addSubview(cameraButton)
//        
//    }
//    func setupPreview() {
//        // Configure previewLayer
//        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//        previewLayer.frame = camPreview.bounds
//        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
//        camPreview.layer.addSublayer(previewLayer)
//    }
//    func getDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
//    //    let devices: NSArray = AVCaptureDevice.devices() as NSArray
//      //  for de in devices {
//        //    let deviceConverted = de as! AVCaptureDevice
//          //  if(deviceConverted.position == position){
//            //    return deviceConverted
//            //}
//        //}
//        return nil
//    }
//    //MARK:- Setup Camera
//    
//    func setupSession() -> Bool {
//        self.resLabel.text = "640x480"
//        captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
//        // Setup Camera
//                let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)!
//       // let camera = getDevice(position: .front)
//        //            default(for: AVMediaType.video)!
//        
//        do {
//            
//            let input = try AVCaptureDeviceInput(device: camera)
//            
//            if captureSession.canAddInput(input) {
//                captureSession.addInput(input)
//                activeInput = input
//            }
//        } catch {
//            print("Error setting device video input: \(error)")
//            return false
//        }
//        
//        // Setup Microphone
//        let microphone = AVCaptureDevice.default(for: AVMediaType.audio)!
//        
//        do {
//            let micInput = try AVCaptureDeviceInput(device: microphone)
//            if captureSession.canAddInput(micInput) {
//                captureSession.addInput(micInput)
//            }
//        } catch {
//            print("Error setting device audio input: \(error)")
//            return false
//        }
//        
//        
//        // Movie output
//        movieOutput.movieFragmentInterval = .invalid
//        if captureSession.canAddOutput(movieOutput) {
//            captureSession.addOutput(movieOutput)
//        }
//        
//        captureSession.commitConfiguration()
//        return true
//    }
//    
//    func setupCaptureMode(_ mode: Int) {
//        // Video Mode
//        
//    }
//    
//    //MARK:- Camera Session
//    func startSession() {
//        
//        if !captureSession.isRunning {
//            videoQueue().async {
//                self.captureSession.startRunning()
//            }
//        }
//    }
//    @objc func updateCounter() {
//        //example functionality
//        if counter > 0 {
//            seconds.text = "00:00:\(counter)"
//            counter -= 1
//        }else{
//            stopRecording()
//        }
//    }
//    
//    func stopSession() {
//        if captureSession.isRunning {
//            videoQueue().async {
//                self.captureSession.stopRunning()
//            }
//        }
//    }
//    
//    func videoQueue() -> DispatchQueue {
//        return DispatchQueue.main
//    }
//    
//    func currentVideoOrientation() -> AVCaptureVideoOrientation {
//        var orientation: AVCaptureVideoOrientation
//        
//        switch UIDevice.current.orientation {
//        case .portrait:
//            orientation = AVCaptureVideoOrientation.portrait
//        case .landscapeRight:
//            orientation = AVCaptureVideoOrientation.landscapeLeft
//        case .portraitUpsideDown:
//            orientation = AVCaptureVideoOrientation.portraitUpsideDown
//        default:
//            orientation = AVCaptureVideoOrientation.landscapeRight
//        }
//        
//        return orientation
//    }
//    
//    @objc func startCapture() {
//        
//        startRecording()
//        self.cameraButton.isHidden = true
//        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
//        self.view.bringSubviewToFront(self.seconds)
//        
//    }
//    
//    //EDIT 1: I FORGOT THIS AT FIRST
//    
//    func tempURL() -> URL? {
//        let directory = NSTemporaryDirectory() as NSString
//        
//        if directory != "" {
//            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
//            return URL(fileURLWithPath: path)
//        }
//        
//        return nil
//    }
//    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        
//        let vc = segue.destination as! VideoPlaybackViewController
//        
//        vc.videoURL = sender as? URL
//        
//    }
//    
//    func startRecording() {
//        
//        if movieOutput.isRecording == false {
//            
//            let connection = movieOutput.connection(with: AVMediaType.video)
//            
//            if (connection?.isVideoOrientationSupported)! {
//                connection?.videoOrientation = currentVideoOrientation()
//            }
//            
//            if (connection?.isVideoStabilizationSupported)! {
//                connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
//            }
//            
//            let device = activeInput.device
//            
//            if (device.isSmoothAutoFocusSupported) {
//                
//                do {
//                    try device.lockForConfiguration()
//                    device.isSmoothAutoFocusEnabled = false
//                    device.unlockForConfiguration()
//                } catch {
//                    print("Error setting configuration: \(error)")
//                }
//                
//            }
//            
//            //EDIT2: And I forgot this
//            outputURL = tempURL()
//            movieOutput.startRecording(to: outputURL, recordingDelegate: self)
//            
//        }
//        else {
//            stopRecording()
//        }
//        
//    }
//    
//    func stopRecording() {
//        
//        if movieOutput.isRecording == true {
//            movieOutput.stopRecording()
//        }
//    }
//    
//    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
//        
//    }
//    
//    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
//        
//        if (error != nil) {
//            
//            print("Error recording movie: \(error!.localizedDescription)")
//            
//        } else {
//            
//            let videoRecorded = outputURL! as URL
//            
//            //                PHPhotoLibrary.shared().performChanges({
//            //                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.outputURL)
//            //                }) { saved, error in
//            //                    if saved {
//            //                        print("saved")
//            //                    }
//            //                }
//            let formatter = DateFormatter()
//            formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
//            let date = Date()
//            let documentsPath = NSTemporaryDirectory()
//            let outputPath = "\(documentsPath)/\(formatter.string(from: date)).mp4"
//            let newOutputUrl = URL(fileURLWithPath: outputPath)
//            compressFile(urlToCompress: outputURL, outputURL: newOutputUrl) { (url) in
//                PHPhotoLibrary.shared().performChanges({
//                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
//                }) { saved, error in
//                    if saved {
//                        print("saved")
//                    }
//                }
//            }
//            performSegue(withIdentifier: "showVideo", sender: videoRecorded)
//            
//        }
//        
//    }
//}
//extension ViewController{
//    func compressFile(urlToCompress: URL, outputURL: URL, completion:@escaping (URL)->Void){
//        //video file to make the asset
//        
//        var audioFinished = false
//        var videoFinished = false
//        
//        
//        
//        let asset = AVAsset(url: urlToCompress);
//        
//        //create asset reader
//        do{
//            assetReader = try AVAssetReader(asset: asset)
//        } catch{
//            assetReader = nil
//        }
//        
//        guard let reader = assetReader else{
//            fatalError("Could not initalize asset reader probably failed its try catch")
//        }
//        
//        let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first!
//        let audioTrack = asset.tracks(withMediaType: AVMediaType.audio).first!
//        
//        let videoReaderSettings: [String:Any] =  [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32ARGB ]
//        
//        // ADJUST BIT RATE OF VIDEO HERE
//        
//        let videoSettings:[String:Any] = [
//            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey:self.bitrate],
//            AVVideoCodecKey: AVVideoCodecType.hevc,
//            AVVideoHeightKey: videoTrack.naturalSize.height,
//            AVVideoWidthKey: videoTrack.naturalSize.width
//        ]
//        
//        
//        let assetReaderVideoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderSettings)
//        let assetReaderAudioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)
//        
//        
//        if reader.canAdd(assetReaderVideoOutput){
//            reader.add(assetReaderVideoOutput)
//        }else{
//            fatalError("Couldn't add video output reader")
//        }
//        
//        if reader.canAdd(assetReaderAudioOutput){
//            reader.add(assetReaderAudioOutput)
//        }else{
//            fatalError("Couldn't add audio output reader")
//        }
//        
//        //        let audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: nil)
//        let videoAsset = AVURLAsset(url: urlToCompress as URL, options: nil)
//        let audioTrack2 = videoAsset.tracks(withMediaType: AVMediaType.audio)[0]
//        let audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: nil, sourceFormatHint: (audioTrack2.formatDescriptions[0] as! CMFormatDescription))
//        let videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
//        videoInput.transform = videoTrack.preferredTransform
//        //we need to add samples to the video input
//        
//        let videoInputQueue = DispatchQueue(label: "videoQueue")
//        let audioInputQueue = DispatchQueue(label: "audioQueue")
//        
//        do{
//            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mp4)
//        }catch{
//            assetWriter = nil
//        }
//        guard let writer = assetWriter else{
//            fatalError("assetWriter was nil")
//        }
//        
//        writer.shouldOptimizeForNetworkUse = true
//        writer.add(videoInput)
//        writer.add(audioInput)
//        
//        
//        writer.startWriting()
//        reader.startReading()
//        writer.startSession(atSourceTime: CMTime.zero)
//        
//        
//        let closeWriter:()->Void = {
//            if (audioFinished && videoFinished){
//                self.assetWriter?.finishWriting(completionHandler: {
//                    
//                    self.checkFileSize(sizeUrl: (self.assetWriter?.outputURL)!, message: "The file size of the compressed file is: ")
//                    
//                    completion((self.assetWriter?.outputURL)!)
//                    
//                })
//                
//                self.assetReader?.cancelReading()
//                
//            }
//        }
//        
//        
//        audioInput.requestMediaDataWhenReady(on: audioInputQueue) {
//            while(audioInput.isReadyForMoreMediaData){
//                let sample = assetReaderAudioOutput.copyNextSampleBuffer()
//                if (sample != nil){
//                    audioInput.append(sample!)
//                }else{
//                    audioInput.markAsFinished()
//                    DispatchQueue.main.async {
//                        audioFinished = true
//                        closeWriter()
//                    }
//                    break;
//                }
//            }
//        }
//        
//        videoInput.requestMediaDataWhenReady(on: videoInputQueue) {
//            //request data here
//            
//            while(videoInput.isReadyForMoreMediaData){
//                let sample = assetReaderVideoOutput.copyNextSampleBuffer()
//                if (sample != nil){
//                    videoInput.append(sample!)
//                }else{
//                    videoInput.markAsFinished()
//                    DispatchQueue.main.async {
//                        videoFinished = true
//                        closeWriter()
//                    }
//                    break;
//                }
//            }
//            
//        }
//        
//        
//    }
//    
//    func checkFileSize(sizeUrl: URL, message:String){
//        let data = NSData(contentsOf: sizeUrl)!
//        print(sizeUrl)
//        print(message, (Double(data.length) / 1048576.0), " mb")
//    }
//}
