//
//  RecordReactionViewController.swift
//  testCamera
//
//  Created by Adel Mohy on 11/11/20.
//

import UIKit
import AVKit
import Photos

class RecordReactionViewController: UIViewController {
    @IBOutlet var cameraView: UIView!
    @IBOutlet var videoPlayer: UIView!
    private var mergeTwoAudios:MergeTwoAudios!
    private var cameraRecorder:CameraRecorder = CameraRecorder()
    private let avPlayer = AVPlayer()
    private var avPlayerLayer: AVPlayerLayer!
    private let cameraButton = UIView()
    private var TalentAsset: AVURLAsset!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraButton.isUserInteractionEnabled = true
        
        let cameraButtonRecognizer = UITapGestureRecognizer(target: self, action: #selector(startCapture))
        
        cameraButton.addGestureRecognizer(cameraButtonRecognizer)
        
        cameraButton.frame = CGRect(x: self.view.center.x, y: self.view.center.y, width: 30, height: 30)
        
        cameraButton.backgroundColor = UIColor.red
        
        view.addSubview(cameraButton)
        
        let resourcepath = Bundle.main.path(forResource: "test", ofType: "mp4")
        let url = URL(fileURLWithPath: resourcepath!)
        TalentAsset = AVURLAsset(url: url)
        
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.frame = view.bounds
        avPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPlayer.layer.insertSublayer(avPlayerLayer, at: 0)
    
        view.layoutIfNeeded()
        
        let playerItem = AVPlayerItem(url: url as URL)
        avPlayer.replaceCurrentItem(with: playerItem)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraRecorder.camPreview = cameraView
        cameraRecorder.delegate = self
        if cameraRecorder.setupSession() {
            cameraRecorder.setupPreview()
            cameraRecorder.startSession()
        }
    }
    @objc func startCapture() {
        cameraRecorder.counter = TalentAsset.duration.seconds
        avPlayer.play()
        cameraRecorder.startCapture()
        self.cameraButton.isHidden = true
    }
}

extension RecordReactionViewController:CameraRecorderDelegate{
    func finishedSavingWithURl(outputURL: URL) {
        mergeTwoAudios = MergeTwoAudios()
        mergeTwoAudios.mergeTwoAudiosFromVideo(VideoUrl1: outputURL.absoluteString, VideoUrl2: TalentAsset.url.absoluteString, compeletionHandeler: { url in
            print(url)
        })
    }
}


