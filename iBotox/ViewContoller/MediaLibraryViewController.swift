//  iBotox
//
//  Created by Tanveer Ashraf on 14/04/2024.
//

import AVKit
import MediaPipeTasksVision
import UIKit

/**
 * The view controller is responsible for performing detection on videos or images selected by the user from the device media library and
 * presenting them with the landmarks of the face to the user.
 */
class MediaLibraryViewController: UIViewController {
  
  // MARK: Constants
  private struct Constants {
    static let edgeOffset: CGFloat = 2.0
    static let inferenceTimeIntervalInMilliseconds = 300.0
    static let milliSeconds = 1000.0
    static let savedPhotosNotAvailableText = "Saved photos album is not available."
    static let mediaEmptyText =
    "Click + to add an image or a video to begin running the face landmark."
    static let pickFromGalleryButtonInset: CGFloat = 10.0
  }
  // MARK: Face Landmarker Service
  weak var interfaceUpdatesDelegate: InterfaceUpdatesDelegate?
  weak var inferenceResultDeliveryDelegate: InferenceResultDeliveryDelegate?
  
  // MARK: Controllers that manage functionality
  private lazy var pickerController = UIImagePickerController()
  private var playerViewController: AVPlayerViewController?
  
  // MARK: Face Landmarker Service
  private var faceLandmarkerService: FaceLandmarkerService?
  
  // MARK: Private properties
  private var playerTimeObserverToken : Any?
  
  // MARK: Storyboards Connections
  @IBOutlet weak var overlayView: OverlayView!
  @IBOutlet weak var pickFromGalleryButton: UIButton!
  @IBOutlet weak var progressView: UIProgressView!
  @IBOutlet weak var imageEmptyLabel: UILabel!
  @IBOutlet weak var pickedImageView: UIImageView!
  @IBOutlet weak var pickFromGalleryButtonBottomSpace: NSLayoutConstraint!
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    redrawBoundingBoxesForCurrentDeviceOrientation()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    interfaceUpdatesDelegate?.shouldClicksBeEnabled(true)
    
    guard UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) else {
     pickFromGalleryButton.isEnabled = false
     self.imageEmptyLabel.text = Constants.savedPhotosNotAvailableText
     return
    }
    pickFromGalleryButton.isEnabled = true
    self.imageEmptyLabel.text = Constants.mediaEmptyText
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    clearPlayerView()
    if faceLandmarkerService?.runningMode == .video {
      overlayView.clear()
    }
    faceLandmarkerService = nil
  }
  
  @IBAction func onClickPickFromGallery(_ sender: Any) {
    interfaceUpdatesDelegate?.shouldClicksBeEnabled(true)
    configurePickerController()
    present(pickerController, animated: true)
  }
    
  private func configurePickerController() {
    pickerController.delegate = self
    pickerController.sourceType = .savedPhotosAlbum
    pickerController.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
    pickerController.allowsEditing = false
  }
  
  private func addPlayerViewControllerAsChild() {
    guard let playerViewController = playerViewController else {
      return
    }
    playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
    
    self.addChild(playerViewController)
    self.view.addSubview(playerViewController.view)
    self.view.bringSubviewToFront(self.overlayView)
    self.view.bringSubviewToFront(self.pickFromGalleryButton)
    NSLayoutConstraint.activate([
      playerViewController.view.leadingAnchor.constraint(
        equalTo: view.leadingAnchor, constant: 0.0),
      playerViewController.view.trailingAnchor.constraint(
        equalTo: view.trailingAnchor, constant: 0.0),
      playerViewController.view.topAnchor.constraint(
        equalTo: view.topAnchor, constant: 0.0),
      playerViewController.view.bottomAnchor.constraint(
        equalTo: view.bottomAnchor, constant: 0.0)
    ])
    playerViewController.didMove(toParent: self)
  }
  
  private func removePlayerViewController() {
    defer {
      playerViewController?.view.removeFromSuperview()
      playerViewController?.willMove(toParent: nil)
      playerViewController?.removeFromParent()
    }
    removeObservers(player: playerViewController?.player)
    playerViewController?.player?.pause()
    playerViewController?.player = nil
  }
  
  private func removeObservers(player: AVPlayer?) {
    guard let player = player else {
      return
    }
    
    if let timeObserverToken = playerTimeObserverToken {
      player.removeTimeObserver(timeObserverToken)
      playerTimeObserverToken = nil
    }
    
  }

  private func openMediaLibrary() {
    configurePickerController()
    present(pickerController, animated: true)
  }
  
  private func clearPlayerView() {
    imageEmptyLabel.isHidden = false
    removePlayerViewController()
  }
  
  private func showProgressView() {
    guard let progressSuperview = progressView.superview?.superview else {
      return
    }
    progressSuperview.isHidden = false
    progressView.progress = 0.0
    progressView.observedProgress = nil
    self.view.bringSubviewToFront(progressSuperview)
  }
  
  private func hideProgressView() {
    guard let progressSuperview = progressView.superview?.superview else {
      return
    }
    self.view.sendSubviewToBack(progressSuperview)
    self.progressView.superview?.superview?.isHidden = true
  }
  
  func layoutUIElements(withInferenceViewHeight height: CGFloat) {
    pickFromGalleryButtonBottomSpace.constant =
    height + Constants.pickFromGalleryButtonInset
    view.layoutSubviews()
  }
  
  func redrawBoundingBoxesForCurrentDeviceOrientation() {
    guard let faceLandmarkerService = faceLandmarkerService,
          faceLandmarkerService.runningMode == .image ||
          self.playerViewController?.player?.timeControlStatus == .paused else {
      return
    }
    overlayView
      .redrawFaceOverlays(
        forNewDeviceOrientation: UIDevice.current.orientation)
  }
  
  deinit {
    playerViewController?.player?.removeTimeObserver(self)
  }
}

extension MediaLibraryViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
  }
  
  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    clearPlayerView()
    pickedImageView.image = nil
    overlayView.clear()
    
    picker.dismiss(animated: true)
    
    guard let mediaType = info[.mediaType] as? String else {
      return
    }
    
    switch mediaType {
    case UTType.movie.identifier:
      guard let mediaURL = info[.mediaURL] as? URL else {
        imageEmptyLabel.isHidden = false
        return
      }
      clearAndInitializeFaceLandmarkerService(runningMode: .video)
      let asset = AVAsset(url: mediaURL)
      Task {
        interfaceUpdatesDelegate?.shouldClicksBeEnabled(false)
        showProgressView()
        
        guard let videoDuration = try? await asset.load(.duration).seconds else {
          hideProgressView()
          return
        }
        
        let resultBundle = await self.faceLandmarkerService?.detect(
          videoAsset: asset,
          durationInMilliseconds: videoDuration * Constants.milliSeconds,
          inferenceIntervalInMilliseconds: Constants.inferenceTimeIntervalInMilliseconds)
        
        hideProgressView()

        DispatchQueue.main.async {
          self.inferenceResultDeliveryDelegate?.didPerformInference(result: resultBundle)
        }
        
        playVideo(
          mediaURL: mediaURL,
          videoDuration: videoDuration,
          resultBundle: resultBundle)
      }
        
      imageEmptyLabel.isHidden = true
    case UTType.image.identifier:
      guard let image = info[.originalImage] as? UIImage else {
        imageEmptyLabel.isHidden = false
        break
      }
      pickedImageView.image = image
      imageEmptyLabel.isHidden = true
      
      showProgressView()
      
      clearAndInitializeFaceLandmarkerService(runningMode: .image)
      
      DispatchQueue.global(qos: .userInteractive).async { [weak self] in
        guard let weakSelf = self,
              let resultBundle = weakSelf.faceLandmarkerService?.detect(image: image),
              let faceLandmarkerResult = resultBundle.faceLandmarkerResults.first,
              let faceLandmarkerResult = faceLandmarkerResult else {
          DispatchQueue.main.async {
            self?.hideProgressView()
          }
          return
        }
          
        DispatchQueue.main.async {
          weakSelf.hideProgressView()
          weakSelf.inferenceResultDeliveryDelegate?.didPerformInference(result: resultBundle)
          let imageSize = image.size
          let faceOverlays = OverlayView.faceOverlays(
            fromMultipleFaceLandmarks: faceLandmarkerResult.faceLandmarks,
            inferredOnImageOfSize: imageSize,
            ovelayViewSize: weakSelf.overlayView.bounds.size,
            imageContentMode: weakSelf.overlayView.imageContentMode,
            andOrientation: image.imageOrientation)
          weakSelf.overlayView.draw(faceOverlays: faceOverlays,
                           inBoundsOfContentImageOfSize: imageSize,
                                    imageContentMode: .scaleAspectFit)
        }
      }
    default:
      break
    }
  }
  
  func clearAndInitializeFaceLandmarkerService(runningMode: RunningMode) {
    faceLandmarkerService = nil
    switch runningMode {
      case .image:
      faceLandmarkerService = FaceLandmarkerService.stillImageLandmarkerService(
        modelPath: InferenceConfigurationManager.sharedInstance.modelPath,
        numFaces: InferenceConfigurationManager.sharedInstance.numFaces,
        minFaceDetectionConfidence: InferenceConfigurationManager.sharedInstance.minFaceDetectionConfidence,
        minFacePresenceConfidence: InferenceConfigurationManager.sharedInstance.minFacePresenceConfidence,
        minTrackingConfidence: InferenceConfigurationManager.sharedInstance.minTrackingConfidence)
      case .video:
      faceLandmarkerService = FaceLandmarkerService.videoFaceLandmarkerService(
        modelPath: InferenceConfigurationManager.sharedInstance.modelPath,
        numFaces: InferenceConfigurationManager.sharedInstance.numFaces,
        minFaceDetectionConfidence: InferenceConfigurationManager.sharedInstance.minFaceDetectionConfidence,
        minFacePresenceConfidence: InferenceConfigurationManager.sharedInstance.minFacePresenceConfidence,
        minTrackingConfidence: InferenceConfigurationManager.sharedInstance.minTrackingConfidence,
        videoDelegate: self)
      default:
        break;
    }
  }
  
  private func playVideo(mediaURL: URL, videoDuration: Double, resultBundle: ResultBundle?) {
    playVideo(asset: AVAsset(url: mediaURL))
    playerTimeObserverToken = playerViewController?.player?.addPeriodicTimeObserver(
      forInterval: CMTime(value: Int64(Constants.inferenceTimeIntervalInMilliseconds),
                          timescale: Int32(Constants.milliSeconds)),
      queue: DispatchQueue(label: "com.google.mediapipe.MediaLibraryViewController.timeObserverQueue", qos: .userInteractive),
      using: { [weak self] (time: CMTime) in
        DispatchQueue.main.async {
          let index =
            Int(CMTimeGetSeconds(time) * Constants.milliSeconds / Constants.inferenceTimeIntervalInMilliseconds)
          guard
                let weakSelf = self,
                let resultBundle = resultBundle,
                index < resultBundle.faceLandmarkerResults.count,
                let faceLandmarkerResult = resultBundle.faceLandmarkerResults[index] else {
            return
          }
          let imageSize = resultBundle.size
          let faceOverlays = OverlayView.faceOverlays(
            fromMultipleFaceLandmarks: faceLandmarkerResult.faceLandmarks,
            inferredOnImageOfSize: imageSize,
            ovelayViewSize: weakSelf.overlayView.bounds.size,
            imageContentMode: weakSelf.overlayView.imageContentMode,
            andOrientation: .up)
          weakSelf.overlayView.draw(faceOverlays: faceOverlays,
                           inBoundsOfContentImageOfSize: imageSize,
                                    imageContentMode: .scaleAspectFit)
          
          // Enable clicks on inferenceVC if playback has ended.
          if (floor(CMTimeGetSeconds(time) +
                    Constants.inferenceTimeIntervalInMilliseconds / Constants.milliSeconds)
              >= floor(videoDuration)) {
            weakSelf.interfaceUpdatesDelegate?.shouldClicksBeEnabled(true)
          }
        }
    })
  }
  
  private func playVideo(asset: AVAsset) {
    if playerViewController == nil {
      let playerViewController = AVPlayerViewController()
      self.playerViewController = playerViewController
    }
    
    let playerItem = AVPlayerItem(asset: asset)
    if let player = playerViewController?.player {
      player.replaceCurrentItem(with: playerItem)
    }
    else {
      playerViewController?.player = AVPlayer(playerItem: playerItem)
    }
    
    playerViewController?.showsPlaybackControls = false
    addPlayerViewControllerAsChild()
    playerViewController?.player?.play()
  }
}

extension MediaLibraryViewController: FaceLandmarkerServiceVideoDelegate {
  
  func faceLandmarkerService(
    _ faceLandmarkerService: FaceLandmarkerService,
    didFinishDetectionOnVideoFrame index: Int) {
    progressView.observedProgress?.completedUnitCount = Int64(index + 1)
  }
  
  func faceLandmarkerService(
    _ faceLandmarkerService: FaceLandmarkerService,
    willBeginDetection totalframeCount: Int) {
    progressView.observedProgress = Progress(totalUnitCount: Int64(totalframeCount))
  }
}


