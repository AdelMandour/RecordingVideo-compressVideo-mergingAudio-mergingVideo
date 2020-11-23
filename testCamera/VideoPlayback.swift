import UIKit
import AVFoundation

class VideoPlaybackViewController: UIViewController {

    let avPlayer = AVPlayer()
    var avPlayerLayer: AVPlayerLayer!

    var videoURL: URL!
    //connect this to your uiview in storyboard
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var thumbNailImage: UIImageView!
    var isPaused = false
    override func viewDidLoad() {
        super.viewDidLoad()

        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.frame = view.bounds
        avPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoView.layer.insertSublayer(avPlayerLayer, at: 0)
    
        view.layoutIfNeeded()
        
        let playerItem = AVPlayerItem(url: videoURL as URL)
        avPlayer.replaceCurrentItem(with: playerItem)
        avPlayer.play()
    }
    @IBAction func plus10(_ sender: Any) {
        forwardVideo(by: 10)
    }
    @IBAction func minus10(_ sender: Any) {
        rewindVideo(by: 10)
    }
    func rewindVideo(by seconds: Float64) {
         let currentTime = avPlayer.currentTime()
            var newTime = CMTimeGetSeconds(currentTime) - seconds
            if newTime <= 0 {
                newTime = 0
            }
            avPlayer.seek(to: CMTime(value: CMTimeValue(newTime * 1000), timescale: 1000))
    }
    func forwardVideo(by seconds: Float64) {
        let currentTime = avPlayer.currentTime()
        let duration = avPlayer.currentItem?.duration
            var newTime = CMTimeGetSeconds(currentTime) + seconds
        if newTime >= CMTimeGetSeconds(duration!) {
            newTime = CMTimeGetSeconds(duration!)
            }
        avPlayer.seek(to: CMTime(value: CMTimeValue(newTime * 1000), timescale: 1000))
    }
    
    @IBAction func takeThumbNail(_ sender: Any) {
        if isPaused{
            avPlayer.play()
            isPaused = false
        }else{
            isPaused = true
            avPlayer.pause()
            let endTime = CMTimeGetSeconds((avPlayer.currentTime()))
            generateThumbnail(path: videoURL, startSconds: Int64(endTime - 1), endSconds: Float(endTime))
        }
    }
    func generateThumbnail(path: URL, startSconds:Int64, endSconds:Float) {
        do {
            let asset = AVURLAsset(url: path, options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cg  = try imgGenerator.copyCGImage(at: avPlayer.currentTime(), actualTime: nil)
            print(avPlayer.currentTime())
            DispatchQueue.main.async {
                self.thumbNailImage.image = nil
                self.thumbNailImage.image = UIImage(cgImage: cg)
                self.thumbNailImage.setNeedsDisplay()
            }
        } catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
        }
    }
}
