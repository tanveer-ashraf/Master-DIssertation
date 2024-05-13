//  iBotox
//
//  Created by Tanveer Ashraf on 14/04/2024.
//

    import UIKit

    protocol InferenceResultDeliveryDelegate: AnyObject {
      func didPerformInference(result: ResultBundle?)
    }

    protocol InterfaceUpdatesDelegate: AnyObject {
      func shouldClicksBeEnabled(_ isEnabled: Bool)
    }

    /** The view controller is responsible for presenting and handling the tabbed controls for switching between the live camera feed and
      * media library view controllers. It also handles the presentation of the inferenceVC
      */
    class RootViewController: UIViewController {
        
      // MARK: Storyboards Connections
    //  @IBOutlet weak var bottomSheetViewBottomSpace: NSLayoutConstraint!
      @IBOutlet weak var bottomViewHeightConstraint: NSLayoutConstraint!
      
      // MARK: Constants
      private struct Constants {
        static let inferenceBottomHeight = 260.0
        static let expandButtonHeight = 41.0
        static let expandButtonTopSpace = 10.0
        static let mediaLibraryViewControllerStoryBoardId = "MEDIA_LIBRARY_VIEW_CONTROLLER"
        static let cameraViewControllerStoryBoardId = "CAMERA_VIEW_CONTROLLER"
        static let storyBoardName = "Main"
        static let inferenceVCEmbedSegueName = "EMBED"
      }
      
      // MARK: Controllers that manage functionality
      private var cameraViewController: CameraViewController?

      
      // MARK: Private Instance Variables

      // MARK: View Handling Methods
      override func viewDidLoad() {
        super.viewDidLoad()
          // Create face landmarker helper
    //      inferenceViewController?.isUIEnabled = true
          instantiateCameraViewController()
          
          // Add CameraViewController as child
          if let cameraVC = cameraViewController {
              addChild(cameraVC)
              cameraVC.view.frame = view.bounds
              view.addSubview(cameraVC.view)
              cameraVC.didMove(toParent: self)
          }
      }
      
      override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        
    //    bottomSheetViewBottomSpace.constant = 0.0
      }
      
      override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
      }
      
      // MARK: Storyboard Segue Handlers
      override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == Constants.inferenceVCEmbedSegueName {
          bottomViewHeightConstraint.constant = Constants.inferenceBottomHeight
          view.layoutSubviews()
        }
      }
      
      // MARK: Private Methods
      private func instantiateCameraViewController() {
        guard cameraViewController == nil else {
          return
        }
        
        guard let viewController = UIStoryboard(
          name: Constants.storyBoardName, bundle: .main)
          .instantiateViewController(
            withIdentifier: Constants.cameraViewControllerStoryBoardId) as? CameraViewController else {
          return
        }
        
        viewController.inferenceResultDeliveryDelegate = self
        viewController.interfaceUpdatesDelegate = self
        
        cameraViewController = viewController
      }
      
    }

    // MARK: InferenceResultDeliveryDelegate Methods
    extension RootViewController: InferenceResultDeliveryDelegate {
      func didPerformInference(result: ResultBundle?) {
        var inferenceTimeString = ""
        
        if let inferenceTime = result?.inferenceTime {
          inferenceTimeString = String(format: "%.2fms", inferenceTime)
        }

      }
    }

    // MARK: InterfaceUpdatesDelegate Methods
    extension RootViewController: InterfaceUpdatesDelegate {
      func shouldClicksBeEnabled(_ isEnabled: Bool) {

      }
    }

