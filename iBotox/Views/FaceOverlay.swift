//  iBotox
//
//  Created by Tanveer Ashraf on 14/04/2024.
//

import UIKit
import MediaPipeTasksVision


struct TargetPoint {
    var view: UIView
    var isHit: Bool
    var idealDose: Int
}
/// A straight line.
struct Line {
  let from: CGPoint
  let to: CGPoint
}

/// Line connection
struct LineConnection {
  let color: UIColor
  let lines: [Line]
}

struct Translation {
    var deltaX: CGFloat
    var deltaY: CGFloat
}

struct DotInfo {
    let index: Int
    let translation: Translation
    let angleInject: CGFloat
}

//
struct DotInfoCollection {
    var dots: [DotInfo]
}

/**


 This structure holds the display parameters for the overlay to be drawon on a detected object.
 */
var dotHolders: DotInfoCollection = DotInfoCollection(dots: [])

struct FaceOverlay {
  let dots: [CGPoint]
  let lineConnections: [LineConnection]
}
//protocols

protocol OverlayViewInstructionsDelegate: AnyObject {
    func presentInstructions(with message: [String])
}

protocol OverlayViewDelegate: AnyObject {
    func presentResultsViewController(with screenshot: UIImage?, scoreMessage: String?, onTargetInjections: [Injection]?)
}


/// Custom view to visualize the face landmarker result on top of the input image.
class OverlayView: UIView, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var cameraFeedService: CameraFeedService?

    private var areMuscleLinesVisible: Bool = false
    
    private var areTargetsVisible: Bool = false
    
    private let panGestureThreshold: CGFloat = 5.0
    
    var presentAlert: ((String, String) -> Void)?

    weak var instructionsDelegate: OverlayViewInstructionsDelegate?
    
    weak var delegate: OverlayViewDelegate?

    var syringeTopConstraint: NSLayoutConstraint!
    var syringeLeadingConstraint: NSLayoutConstraint!
    
    var treatmentAnchorsHolder: [[Int]] = [[124, 35, 111, 353, 265, 340], [4, 4, 4, 4, 4, 4] ]
    var treatmentPatternHolder: String = "crow's feet"
    var treatmentPattern = [
        "crow's feet": [
            "anchors": [124, 35, 111, 353, 265, 340],
            "idealDoses": [4, 4, 4, 4, 4, 4] // Example ideal dose
        ],
        "frown lines": [
            "anchors": [55, 285, 417, 193],
            "idealDoses": [5, 5, 5, 5] // Example ideal dose
        ],
        "forehead lines": [
            "anchors": [297, 299, 69, 67],
            "idealDoses": [5, 5, 5, 5] // Example ideal dose
        ]
    ]
    var targetPoints: [TargetPoint] = []
    var targetHolder: [CGPoint] = []
    var hitTargetHolder: [Int] = []
    private var currentTreatmentPatternIndex = 0
    
    var faceOverlays: [FaceOverlay] = []
    
    private var yMarkLabels: [(label: UILabel, score: CGFloat, angle: CGFloat, hittingTarget: Int?, userDosage: Int?, idealDoseTarget: Int?)] = []
    
    private let drugs = ["Botox", "Dysport", "Xeomin", "Jeuveau"] // Drug options

    private var contentImageSize: CGSize = CGSizeZero
    var imageContentMode: UIView.ContentMode = .scaleAspectFit
    private var orientation = UIDeviceOrientation.portrait
    
    private var edgeOffset: CGFloat = 0.0
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = treatmentPatternHolder
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 40)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let hintsBoxView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .lightGray // Set the background color as needed
        view.layer.cornerRadius = 10
        return view
    }()
    
    private let muscleToggleButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle("Muscles", for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()
    
    private let targetToggleButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle("Targets", for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()
    
    private let treatmentPatternButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle("Press To Change Treatment Pattern", for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()
    
    private let injectButton: UIButton  = {
        let button = UIButton(type: .system)
        button.setTitle("Inject", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let clearButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle("Clear", for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
    }()
    
    private let syringeCalibrationView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .lightGray // Set the background color as needed
        view.layer.cornerRadius = 10
        return view
    }()
    
    private let syringeCalibrationTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Drug & Dose"
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 20) // Adjust the font size as needed
        return label
    }()

    private let drugPicker: UIPickerView = {
        let picker = UIPickerView()
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()

    private let unitsTextField: UITextField = {
        let textField = UITextField()
        textField.text = "1"
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Units"
        textField.keyboardType = .decimalPad // For entering floats
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    private let syringeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .white // Set background color
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        label.textColor = .black
        label.text = "Botox"
        label.layer.borderColor = UIColor.black.cgColor // Choose your outline color
        label.layer.borderWidth = 1.5 // Set the width of the outline
        // Rotate the label by 90 degrees clockwise
        label.transform = CGAffineTransform(rotationAngle: .pi / 2) // pi/2 radians = 90 degrees

        return label
    }()

    
    private func printRotationAngleOfDraggable()-> CGFloat {
        let transform = draggableSyringeView.transform
        var rotationAngleRadians = atan2(transform.b, transform.a) // Rotation in radians

        if rotationAngleRadians < 0 {
            rotationAngleRadians += 2 * .pi
        }

        let rotationAngleDegrees = rotationAngleRadians * 180 / .pi // Convert to degrees

        return rotationAngleDegrees
    }

    private func addNewYMarkLabel(_ position: Int, userDosage: Int, idealDoseTarget: Int?) {
        let label = UILabel()
        let positionString = String(position)
        label.text = "\(positionString)"
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textAlignment = .center
        label.textColor = .blue
        label.isHidden = true // Initially hidden
        label.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        addSubview(label)
        yMarkLabels.append((label: label, score: CGFloat(0),angle: CGFloat(0), hittingTarget: nil, userDosage: userDosage, idealDoseTarget: idealDoseTarget))
        bringSubviewToFront(label)
    }
    
    private func createTargetPoint(idealDose: Int) -> TargetPoint {
        let view = UIView(frame: CGRect(x: 250, y: 250, width: 50, height: 50))
        view.backgroundColor = .clear
        let label = UILabel(frame: view.bounds)
        label.text = "O"
        label.font = UIFont.italicSystemFont(ofSize: 30)
        label.textAlignment = .center
        label.textColor = .clear
        view.addSubview(label)
        return TargetPoint(view: view, isHit: false, idealDose: idealDose)
    }

    private let draggableSyringeView: UIView = {
        let view = UIView(frame: CGRect(x: 150, y: 150, width: 300, height: 700))
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        var syringeSize: CGSize
            if UIDevice.current.userInterfaceIdiom == .phone {
                // Adjust size for iPhone
                syringeSize = CGSize(width: 150, height: 210)
            } else {
                // Default size for iPad
                syringeSize = CGSize(width: 300, height: 400)
            }
        let imageView = UIImageView(image: UIImage(named: "syringe_3"))
        imageView.contentMode = .scaleToFill
        imageView.tintColor = .red
        imageView.backgroundColor = .clear
        let yOffset: CGFloat = 350
        
        imageView.frame = CGRect(x: (view.bounds.width - syringeSize.width) / 2,
                                     y: yOffset,
                                     width: syringeSize.width,
                                     height: syringeSize.height)

        view.addSubview(imageView)
        return view
    }()
    
    
     override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(hintsBoxView)
            initializeDraggableSyringeView()
            setupInjectButton()
            setupClearButton()
            setupButtons()
            setupTargetPoints()
            setupTreatmentPatternButton()
            setupTitleLabel()
            setupSyringeCalibrationView()
            setupHintsBoxView()
            commonInit()
     }
    
     required init?(coder aDecoder: NSCoder) {
           super.init(coder: aDecoder)
           addSubview(hintsBoxView)
           initializeDraggableSyringeView()
           setupInjectButton()
           setupClearButton()
           setupButtons()
           setupTargetPoints()
           setupTreatmentPatternButton()
           setupTitleLabel()
           setupSyringeCalibrationView()
           setupHintsBoxView()
           commonInit()
       }
        

    private func commonInit() {
           // ... existing setup code...
           setupUnitsTextField()
       }
    
    private func setupUnitsTextField() {
            // ... existing setup code for unitsTextField...
            unitsTextField.inputAccessoryView = createKeyboardToolbar()
        }
    
    private func createKeyboardToolbar() -> UIToolbar {
           let toolbar = UIToolbar()
           toolbar.sizeToFit()
           let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
           let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
           toolbar.setItems([flexSpace, doneButton], animated: false)
           return toolbar
       }
    
    @objc private func dismissKeyboard() {
           unitsTextField.resignFirstResponder()
       }
    
    private func setupTitleLabel() {
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 50),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8),
            titleLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupTargetPoints() {
        // Remove any existing target points from the subview
        for targetPoint in targetPoints {
            targetPoint.view.removeFromSuperview()
        }
        
        targetPoints = []
        
        let indices: [Int] = treatmentAnchorsHolder[0] 
        let idealDoseNums: [Int] = treatmentAnchorsHolder[1]


        for (i, index) in indices.enumerated() {
            let targetPoint = createTargetPoint(idealDose: idealDoseNums[i])
            addSubview(targetPoint.view)
            targetPoints.append(targetPoint)
        }
        // You can set additional properties or constraints for targetPoint here if needed
    }
    
    private func initializeDraggableSyringeView() {
        addSubview(draggableSyringeView)

        draggableSyringeView.addSubview(syringeLabel)
        syringeLabel.backgroundColor = .white
        syringeLabel.text = "Botox"

        // Set Auto Layout constraints for draggableSyringeView
        draggableSyringeView.translatesAutoresizingMaskIntoConstraints = false
        syringeTopConstraint = draggableSyringeView.topAnchor.constraint(equalTo: self.topAnchor, constant: -200)
        syringeLeadingConstraint = draggableSyringeView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10)
        let syringeWidth = NSLayoutConstraint(item: draggableSyringeView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 300)
        let syringeHeight = NSLayoutConstraint(item: draggableSyringeView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 700)
        NSLayoutConstraint.activate([syringeTopConstraint, syringeLeadingConstraint, syringeWidth, syringeHeight])

        syringeLabel.translatesAutoresizingMaskIntoConstraints = false

        // Define constraints for both iPhone and iPad
        var labelCenterX: NSLayoutConstraint
        var labelCenterY: NSLayoutConstraint
        var labelWidth: NSLayoutConstraint
        var labelHeight: NSLayoutConstraint

        if UIDevice.current.userInterfaceIdiom == .phone {
            // Constraints for iPhone
            labelCenterX = NSLayoutConstraint(item: syringeLabel, attribute: .centerX, relatedBy: .equal, toItem: draggableSyringeView, attribute: .centerX, multiplier: 1.003, constant: 0)
            labelCenterY = NSLayoutConstraint(item: syringeLabel, attribute: .centerY, relatedBy: .equal, toItem: draggableSyringeView, attribute: .centerY, multiplier: 1.35, constant: 0)
            labelWidth = NSLayoutConstraint(item: syringeLabel, attribute: .width, relatedBy: .equal, toItem: draggableSyringeView, attribute: .width, multiplier: 0.22, constant: 0) // Adjust these values as needed
            labelHeight = NSLayoutConstraint(item: syringeLabel, attribute: .height, relatedBy: .equal, toItem: draggableSyringeView, attribute: .height, multiplier: 0.025, constant: 0) // Adjust these values as needed
        } else {
            // Constraints for iPad
            labelCenterX = NSLayoutConstraint(item: syringeLabel, attribute: .centerX, relatedBy: .equal, toItem: draggableSyringeView, attribute: .centerX, multiplier: 1.005, constant: 0)
            labelCenterY = NSLayoutConstraint(item: syringeLabel, attribute: .centerY, relatedBy: .equal, toItem: draggableSyringeView, attribute: .centerY, multiplier: 1.6, constant: 0)
            labelWidth = NSLayoutConstraint(item: syringeLabel, attribute: .width, relatedBy: .equal, toItem: draggableSyringeView, attribute: .width, multiplier: 0.4, constant: 0)
            labelHeight = NSLayoutConstraint(item: syringeLabel, attribute: .height, relatedBy: .equal, toItem: draggableSyringeView, attribute: .height, multiplier: 0.05, constant: 0)
        }

        // Activate the constraints
        NSLayoutConstraint.activate([labelCenterX, labelCenterY, labelWidth, labelHeight])


        // Add gestures to the syringe view
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        draggableSyringeView.addGestureRecognizer(panGesture)

        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotationGesture))
        draggableSyringeView.addGestureRecognizer(rotationGesture)
    }


    
    private func setupTreatmentPatternButton() {
        addSubview(treatmentPatternButton)
        treatmentPatternButton.addTarget(self, action: #selector(toggleTreatmentPattern), for: .touchUpInside)
        treatmentPatternButton.backgroundColor = UIColor.systemBlue
        treatmentPatternButton.setTitleColor(UIColor.white, for: .normal)

        treatmentPatternButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        treatmentPatternButton.layer.cornerRadius = 10
        treatmentPatternButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)

        NSLayoutConstraint.activate([
            treatmentPatternButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            treatmentPatternButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 100)
        ])
    }
    
   
    private func setupInjectButton() {
        addSubview(injectButton)
        injectButton.addTarget(self, action: #selector(injectButtonTapped), for: .touchUpInside)
        configureButtonAppearance(button: injectButton, isIphone: UIDevice.current.userInterfaceIdiom == .phone)            // Position the button at the right lower part of the frame
        NSLayoutConstraint.activate([
            injectButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -100),
            injectButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupClearButton() {
        addSubview(clearButton)
        clearButton.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)
        configureButtonAppearance(button: clearButton, isIphone: UIDevice.current.userInterfaceIdiom == .phone)
        // Position the clear button next to the inject button
        NSLayoutConstraint.activate([
            clearButton.trailingAnchor.constraint(equalTo: injectButton.leadingAnchor, constant: -10),
            clearButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupButtons() {
        // Create a horizontal stack view
        let buttonStackView = UIStackView(arrangedSubviews: [injectButton, clearButton])
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.alignment = .fill
        buttonStackView.spacing = 10
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false

        // Add the stack view to the view
        addSubview(buttonStackView)

        // Set up constraints for the stack view
        NSLayoutConstraint.activate([
                buttonStackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20), // Aligns stack view to the left
                buttonStackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20), // Positions stack view at the bottom
                buttonStackView.heightAnchor.constraint(equalToConstant: 40),
                buttonStackView.widthAnchor.constraint(equalToConstant: 200) // Adjust width as needed
            ])
        // Configure individual buttons
        configureButtonAppearance(button: injectButton, isIphone: UIDevice.current.userInterfaceIdiom == .phone)
        configureButtonAppearance(button: clearButton, isIphone: UIDevice.current.userInterfaceIdiom == .phone)
    }

    private func drawDots(_ dots: [CGPoint]) {
      for dot in dots {
        let dotRect = CGRect(
          x: CGFloat(dot.x) - DefaultConstants.pointRadius / 2,
          y: CGFloat(dot.y) - DefaultConstants.pointRadius / 2,
          width: DefaultConstants.pointRadius,
          height: DefaultConstants.pointRadius)
        let path = UIBezierPath(ovalIn: dotRect)
        DefaultConstants.pointFillColor.setFill()
        DefaultConstants.pointColor.setStroke()
        path.stroke()
        path.fill()
      }
    }
    
    private func resetSyringePosition() {
        // Set the constraints to the default position
        syringeTopConstraint.constant = -200
        syringeLeadingConstraint.constant = 10
        
        // Animate the change if needed
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }
    
    private func setupSyringeCalibrationView() {
        addSubview(syringeCalibrationView)
        syringeCalibrationView.addSubview(syringeCalibrationTitleLabel)
        syringeCalibrationView.addSubview(drugPicker)
        syringeCalibrationView.addSubview(unitsTextField)

        drugPicker.delegate = self
        drugPicker.dataSource = self

        syringeCalibrationView.translatesAutoresizingMaskIntoConstraints = false
        syringeCalibrationTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        drugPicker.translatesAutoresizingMaskIntoConstraints = false
        unitsTextField.translatesAutoresizingMaskIntoConstraints = false

        // Constraints adjustments for iPhone and iPad
        let isIphone = UIDevice.current.userInterfaceIdiom == .phone
        let syringeCalibrationViewWidth: CGFloat = isIphone ? 120 : 200 // Width of the view
        let syringeCalibrationViewHeight: CGFloat = 180 // Height of the view
        let syringeCalibrationViewTopConstant: CGFloat = isIphone ? 200 : 250 // Top space from safeAreaLayoutGuide
        let titleLabelHeight: CGFloat = isIphone ? 30 : 40 // Height of the title label
        
        
        // Layout Constraints for syringeCalibrationView
        NSLayoutConstraint.activate([
               syringeCalibrationView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
               syringeCalibrationView.bottomAnchor.constraint(equalTo: hintsBoxView.topAnchor, constant: -20),
               syringeCalibrationView.widthAnchor.constraint(equalToConstant: syringeCalibrationViewWidth),
               syringeCalibrationView.heightAnchor.constraint(equalToConstant: syringeCalibrationViewHeight)
           ])

        // Layout Constraints for syringeCalibrationTitleLabel
        NSLayoutConstraint.activate([
            syringeCalibrationTitleLabel.topAnchor.constraint(equalTo: syringeCalibrationView.topAnchor),
            syringeCalibrationTitleLabel.leadingAnchor.constraint(equalTo: syringeCalibrationView.leadingAnchor),
            syringeCalibrationTitleLabel.trailingAnchor.constraint(equalTo: syringeCalibrationView.trailingAnchor),
            syringeCalibrationTitleLabel.heightAnchor.constraint(equalToConstant: titleLabelHeight)
        ])

        // Layout Constraints for drugPicker
        NSLayoutConstraint.activate([
            drugPicker.topAnchor.constraint(equalTo: syringeCalibrationTitleLabel.bottomAnchor),
            drugPicker.leadingAnchor.constraint(equalTo: syringeCalibrationView.leadingAnchor),
            drugPicker.trailingAnchor.constraint(equalTo: syringeCalibrationView.trailingAnchor),
            drugPicker.heightAnchor.constraint(equalTo: syringeCalibrationView.heightAnchor, multiplier: isIphone ? 0.44 : 0.35)
        ])

        // Layout Constraints for unitsTextField
        NSLayoutConstraint.activate([
            unitsTextField.topAnchor.constraint(equalTo: drugPicker.bottomAnchor, constant: 10),
            unitsTextField.leadingAnchor.constraint(equalTo: syringeCalibrationView.leadingAnchor, constant: 10),
            unitsTextField.trailingAnchor.constraint(equalTo: syringeCalibrationView.trailingAnchor, constant: -10),
            unitsTextField.heightAnchor.constraint(equalTo: syringeCalibrationView.heightAnchor, multiplier: isIphone ? 0.19 : 0.15)
        ])
    }

    private func setupHintsBoxView() {
        addSubview(hintsBoxView)
        hintsBoxView.addSubview(muscleToggleButton)
        hintsBoxView.addSubview(targetToggleButton)
       
        targetToggleButton.addTarget(self, action: #selector(targetToggleButtonTapped), for: .touchUpInside)
        muscleToggleButton.addTarget(self, action: #selector(muscleToggleButtonTapped), for: .touchUpInside)

            
        configureButtonAppearance(button: targetToggleButton, isIphone: UIDevice.current.userInterfaceIdiom == .phone)            // Position the button at the right lower part of the frame
        configureButtonAppearance(button: muscleToggleButton, isIphone: UIDevice.current.userInterfaceIdiom == .phone)
        
        hintsBoxView.translatesAutoresizingMaskIntoConstraints = false
        targetToggleButton.translatesAutoresizingMaskIntoConstraints = false
        muscleToggleButton.translatesAutoresizingMaskIntoConstraints = false
        
        let isIphone = UIDevice.current.userInterfaceIdiom == .phone
        let hintsBoxViewWidth: CGFloat = isIphone ? 120 : 200 // Width of the view
        let hintsBoxViewHeight: CGFloat = isIphone ? 100 : 120 // Height of the view
        let hintsBoxViewTopConstant: CGFloat = isIphone ? 200 : 250 // Top space from safeAreaLayoutGuide
        let titleLabelHeight: CGFloat = isIphone ? 30 : 40 // Height of the title label
        let buttonHeightiPhone: CGFloat = 35 // Adjust as needed for iPhone
        let buttonHeightiPad: CGFloat = 44 // Adjust as needed for iPad
        let gapBetweenButtons: CGFloat = 10
        let gapBetweenButtonsAndCalibrationView: CGFloat = 20
        let verticalOffset: CGFloat = isIphone ? 280 : 0
        
        NSLayoutConstraint.activate([
                  hintsBoxView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
                  hintsBoxView.topAnchor.constraint(equalTo: syringeCalibrationView.bottomAnchor, constant: gapBetweenButtonsAndCalibrationView + verticalOffset),
                  hintsBoxView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -300 + verticalOffset), // Adjust this as necessary
                  hintsBoxView.widthAnchor.constraint(equalToConstant: hintsBoxViewWidth),
                  hintsBoxView.heightAnchor.constraint(equalToConstant: hintsBoxViewHeight)
            ])

        NSLayoutConstraint.activate([
            targetToggleButton.topAnchor.constraint(equalTo: hintsBoxView.topAnchor, constant: 10),
            targetToggleButton.leadingAnchor.constraint(equalTo: hintsBoxView.leadingAnchor, constant: 10),
            targetToggleButton.trailingAnchor.constraint(equalTo: hintsBoxView.trailingAnchor, constant: -10),
            targetToggleButton.heightAnchor.constraint(equalToConstant: isIphone ? buttonHeightiPhone : buttonHeightiPad)
        ])

        // Layout Constraints for unitsTextField
        NSLayoutConstraint.activate([
            muscleToggleButton.topAnchor.constraint(equalTo: targetToggleButton.bottomAnchor, constant: gapBetweenButtons),
            muscleToggleButton.leadingAnchor.constraint(equalTo: hintsBoxView.leadingAnchor, constant: 10),
            muscleToggleButton.trailingAnchor.constraint(equalTo: hintsBoxView.trailingAnchor, constant: -10),
            muscleToggleButton.heightAnchor.constraint(equalToConstant: isIphone ? buttonHeightiPhone : buttonHeightiPad),
            muscleToggleButton.bottomAnchor.constraint(equalTo: hintsBoxView.bottomAnchor, constant: -10)
        ])
        
    }

    
  // MARK: Public Functions
    
    
    @objc func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    @objc func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return drugs.count
    }

    @objc func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return drugs[row]
    }
    
    @objc func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedDrug = drugs[row]
        syringeLabel.text = selectedDrug
    }
    
   func presentInitialInstructions() {
      switch currentTreatmentPatternIndex {
          case 0:
              treatmentPatternHolder =  "crow's feet"
          case 1:
               treatmentPatternHolder = "frown lines"
          case 2:
               treatmentPatternHolder = "forehead lines"
          default:
               treatmentPatternHolder = "crow's feet"
      }
     let instructionsMessage = getInstructions(for: treatmentPatternHolder)
     instructionsDelegate?.presentInstructions(with: instructionsMessage)
   }

    
  func draw(
    faceOverlays: [FaceOverlay],
    inBoundsOfContentImageOfSize imageSize: CGSize,
    edgeOffset: CGFloat = 0.0,
    imageContentMode: UIView.ContentMode) {
      self.clear()
      contentImageSize = imageSize
      self.edgeOffset = edgeOffset
      self.faceOverlays = faceOverlays
      self.imageContentMode = imageContentMode
      orientation = UIDevice.current.orientation
      self.setNeedsDisplay()
  }

  func redrawFaceOverlays(forNewDeviceOrientation deviceOrientation:UIDeviceOrientation) {
    orientation = deviceOrientation
    switch orientation {
        case .portrait:
          fallthrough
        case .landscapeLeft:
          fallthrough
        case .landscapeRight:
          self.setNeedsDisplay()
        default:
          return
    }
  }

    func clear() {
        faceOverlays = []
        contentImageSize = CGSize.zero
        imageContentMode = .scaleAspectFit
        orientation = UIDevice.current.orientation
        edgeOffset = 0.0
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
      super.draw(rect)
      for faceOverlay in faceOverlays {
          drawDots(faceOverlay.dots)
          for lineConnection in faceOverlay.lineConnections {
            let color = areMuscleLinesVisible ? lineConnection.color : .clear
            drawLines(lineConnection.lines, lineColor: color)
          }
      }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        // Check if orientation changed
        if orientation != UIDevice.current.orientation {
            orientation = UIDevice.current.orientation

            // Reset syringe position
            resetSyringePosition()

            // Redraw face overlays for new orientation
            redrawFaceOverlays(forNewDeviceOrientation: orientation)
        }

        // Rest of the layout code...
    }
    
    func distanceBetweenPoints(point1: CGPoint, point2: CGPoint) -> CGFloat {
        return hypot(point2.x - point1.x, point2.y - point1.y)
    }
    
    func updateYMarkPositions() {
        
        for (i, dotInfo) in dotHolders.dots.enumerated() {
            
            guard dotInfo.index < faceOverlays.flatMap({ $0.dots }).count,
                  i < yMarkLabels.count else { continue }
            let dot = faceOverlays.flatMap({ $0.dots })[dotInfo.index]
            let correspondingLabel = yMarkLabels[i].label // Use loop index
            let transformedPoint = CGPoint(x: dot.x - dotInfo.translation.deltaX, y: dot.y - dotInfo.translation.deltaY)
            correspondingLabel.center = transformedPoint
            correspondingLabel.isHidden = false
            
            guard let point1 = targetHolder.first else { return }
            
            guard let overlay = faceOverlays.first, overlay.dots.count > 124 else {
                return
            }
            let leftFacedot = overlay.dots[454]
            let rightFacedot = overlay.dots[234]
            let faceWidth = distanceBetweenPoints(point1: leftFacedot, point2: rightFacedot)
                       
            var final: CGFloat?
            var indexKey: Int?
            for target in targetHolder {
                let distanceBetTargetAndInj = distanceBetweenPoints(point1: target, point2: transformedPoint)
                if final == nil || distanceBetTargetAndInj < final! {
                    final = distanceBetTargetAndInj
                    indexKey = targetHolder.firstIndex(where: { $0 == target })
                }
            }
    
            var proportionalDist = final!/faceWidth
    
            if yMarkLabels[i].score == 0 {
                yMarkLabels[i].score = proportionalDist
                yMarkLabels[i].angle = dotInfo.angleInject
                /// NEED TO ADD A CONDITION FOR ONLY THROW
                if proportionalDist < 0.05 && targetPoints[indexKey!].isHit && yMarkLabels.count != targetPoints.count {
                    presentAlert?("Warning", "You already hit this target- hit another")
                    return
                }
                if proportionalDist < 0.05 && !targetPoints[indexKey!].isHit {
                    targetPoints[indexKey!].isHit = true
                    yMarkLabels[i].hittingTarget = indexKey
                    yMarkLabels[i].idealDoseTarget = targetPoints[indexKey!].idealDose
                }
            }
            final = nil
         }
        targetHolder = []
    }
    
    func updateTargets() {
        guard let overlay = faceOverlays.first else { return }

        let indices = treatmentAnchorsHolder[0]

        for (i, targetPoint) in targetPoints.enumerated() {
            guard overlay.dots.count > indices[i] else { continue }
            let dot = overlay.dots[indices[i]]
            targetPoint.view.center = dot
            targetHolder.append(dot)
            
            if let label = targetPoint.view.subviews.first as? UILabel {
                label.textColor = areTargetsVisible ? .black : .clear
            }
        }
        
    }


  // MARK: Private Functions
// for future work in making more accurate target placements
    
    private func distanceBetween(_ point1: CGPoint, _ point2: CGPoint) -> CGFloat {
        return hypot(point2.x - point1.x, point2.y - point1.y)
    }

    private func angleBetweenPoints(_ point1: CGPoint, _ point2: CGPoint) -> CGFloat {
        return atan2(point2.y - point1.y, point2.x - point1.x)
    }

    private func rectAfterApplyingBoundsAdjustment(
       onOverlayBorderRect borderRect: CGRect) -> CGRect {

      var currentSize = self.bounds.size
      let minDimension = min(self.bounds.width, self.bounds.height)
      let maxDimension = max(self.bounds.width, self.bounds.height)

      switch orientation {
      case .portrait:
        currentSize = CGSizeMake(minDimension, maxDimension)
      case .landscapeLeft:
        fallthrough
      case .landscapeRight:
        currentSize = CGSizeMake(maxDimension, minDimension)
      default:
        break
      }

      let offsetsAndScaleFactor = OverlayView.offsetsAndScaleFactor(
        forImageOfSize: self.contentImageSize,
        tobeDrawnInViewOfSize: currentSize,
        withContentMode: imageContentMode)

      var newRect = borderRect
        .applying(
          CGAffineTransform(scaleX: offsetsAndScaleFactor.scaleFactor, y: offsetsAndScaleFactor.scaleFactor)
        )
        .applying(
          CGAffineTransform(translationX: offsetsAndScaleFactor.xOffset, y: offsetsAndScaleFactor.yOffset)
        )

      if newRect.origin.x < 0 &&
          newRect.origin.x + newRect.size.width > edgeOffset {
        newRect.size.width = newRect.maxX - edgeOffset
        newRect.origin.x = edgeOffset
      }

      if newRect.origin.y < 0 &&
          newRect.origin.y + newRect.size.height > edgeOffset {
        newRect.size.height += newRect.maxY - edgeOffset
        newRect.origin.y = edgeOffset
      }

      if newRect.maxY > currentSize.height {
        newRect.size.height = currentSize.height - newRect.origin.y  - edgeOffset
      }

      if newRect.maxX > currentSize.width {
        newRect.size.width = currentSize.width - newRect.origin.x - edgeOffset
      }
      return newRect
    }

 

  private func drawLines(_ lines: [Line], lineColor: UIColor) {
    let path = UIBezierPath()
    for line in lines {
      path.move(to: line.from)
      path.addLine(to: line.to)
    }
    path.lineWidth = DefaultConstants.lineWidth
    lineColor.setStroke()
    path.stroke()
  }
    
    private func configureButtonAppearance(button: UIButton, isIphone: Bool) {
        let fontSize: CGFloat = isIphone ? 14 : 18 // Adjust as needed
        button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.cornerRadius = 10

        // Set different padding for iPhone and iPad
        let horizontalPadding: CGFloat = isIphone ? 10 : 20 // Adjust as needed
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: horizontalPadding, bottom: 10, right: horizontalPadding)

        // Calculate the required width of the button
        let font = UIFont.systemFont(ofSize: 18, weight: .bold)
        let titleWidth = button.titleLabel!.text!.size(withAttributes: [.font: font]).width
        let requiredWidth = titleWidth + 2 * horizontalPadding
        button.widthAnchor.constraint(equalToConstant: requiredWidth).isActive = true
    }


  // MARK: Helper Functions
  static func offsetsAndScaleFactor(
    forImageOfSize imageSize: CGSize,
    tobeDrawnInViewOfSize viewSize: CGSize,
    withContentMode contentMode: UIView.ContentMode)
  -> (xOffset: CGFloat, yOffset: CGFloat, scaleFactor: Double) {

    let widthScale = viewSize.width / imageSize.width;
    let heightScale = viewSize.height / imageSize.height;

    var scaleFactor = 0.0

    switch contentMode {
    case .scaleAspectFill:
      scaleFactor = max(widthScale, heightScale)
    case .scaleAspectFit:
      scaleFactor = min(widthScale, heightScale)
    default:
      scaleFactor = 1.0
    }

    let scaledSize = CGSize(
      width: imageSize.width * scaleFactor,
      height: imageSize.height * scaleFactor)
    let xOffset = (viewSize.width - scaledSize.width) / 2
    let yOffset = (viewSize.height - scaledSize.height) / 2

    return (xOffset, yOffset, scaleFactor)
  }

  // Helper to get object overlays from detections.
  static func faceOverlays(
    fromMultipleFaceLandmarks landmarks: [[NormalizedLandmark]],
    inferredOnImageOfSize originalImageSize: CGSize,
    ovelayViewSize: CGSize,
    imageContentMode: UIView.ContentMode,
    andOrientation orientation: UIImage.Orientation,
    anchoredImage: UIImage? = nil,
    anchorStartIndex: Int = 0,
    anchorEndIndex: Int = 1) -> [FaceOverlay] {
       var faceOverlays: [FaceOverlay] = []
       guard !landmarks.isEmpty else {
         return []
       }

      let offsetsAndScaleFactor = OverlayView.offsetsAndScaleFactor(
        forImageOfSize: originalImageSize,
        tobeDrawnInViewOfSize: ovelayViewSize,
        withContentMode: imageContentMode)

        for faceLandmarks in landmarks {
            var transformedFaceLandmarks: [CGPoint]!
            
            switch orientation {
            case .left:
                transformedFaceLandmarks = faceLandmarks.map({CGPoint(x: CGFloat($0.y), y: 1 - CGFloat($0.x))})
            case .right:
                transformedFaceLandmarks = faceLandmarks.map({CGPoint(x: 1 - CGFloat($0.y), y: CGFloat($0.x))})
            default:
                transformedFaceLandmarks = faceLandmarks.map({CGPoint(x: CGFloat($0.x), y: CGFloat($0.y))})
            }
            
            let dots: [CGPoint] = transformedFaceLandmarks.map({CGPoint(x: CGFloat($0.x) * originalImageSize.width * offsetsAndScaleFactor.scaleFactor + offsetsAndScaleFactor.xOffset, y: CGFloat($0.y) * originalImageSize.height * offsetsAndScaleFactor.scaleFactor + offsetsAndScaleFactor.yOffset)})
            
            var lineConnections: [LineConnection] = []
            lineConnections.append(LineConnection(
                color: UIColor.orange,
                lines: FaceLandmarker.mentalisConnections().map({ connection in
                let start = dots[Int(connection.start)]
                let end = dots[Int(connection.end)]
                return Line(from: start, to: end)
                })
            ))
            lineConnections.append(LineConnection(
                color: UIColor.blue,
                lines: FaceLandmarker.frontalisConnections()
                .map({ connection in
                let start = dots[Int(connection.start)]
                let end = dots[Int(connection.end)]
                  return Line(from: start, to: end)
            })))
            lineConnections.append(LineConnection(
                color: UIColor.green,
                lines: FaceLandmarker.nasalisConnections()
                .map({ connection in
                let start = dots[Int(connection.start)]
                let end = dots[Int(connection.end)]
                  return Line(from: start, to: end)
            })))
            lineConnections.append(LineConnection(
                color: UIColor.purple,
                lines: FaceLandmarker.orbOccConnections()
                .map({ connection in
                let start = dots[Int(connection.start)]
                let end = dots[Int(connection.end)]
                  return Line(from: start, to: end)
            })))
            lineConnections.append(LineConnection(
                color: UIColor.yellow,
                lines: FaceLandmarker.orbOrisConnections()
                .map({ connection in
                let start = dots[Int(connection.start)]
                let end = dots[Int(connection.end)]
                  return Line(from: start, to: end)
            })))
            faceOverlays.append(FaceOverlay(dots: dots, lineConnections: lineConnections))
       }
      return faceOverlays
    }
}

extension FaceLandmarker {
    
    static func mentalisConnections() -> [Connection] {
        // Indices corresponding to the chin landmarks
        let chinIndices: [Int] = [83,18, 313, 421, 428, 199, 208, 201, 83]
        // Initialize an empty array to store the connections
        var connections: [Connection] = []
        // Create connections between the chin landmarks
        for i in 0..<chinIndices.count-1 {
            let connection = Connection(start: UInt(chinIndices[i]), end: UInt(chinIndices[i+1]))
            connections.append(connection)
        }
        return connections
    }
    
    static func frontalisConnections() -> [Connection] {
        // Indices corresponding to the chin landmarks
        let indices: [Int] = [54, 68, 104, 69, 108, 151, 337, 299, 333, 298, 284]
        // Initialize an empty array to store the connections
        var connections: [Connection] = []
        // Create connections between the landmarks
        for i in 0..<indices.count-1 {
            let connection = Connection(start: UInt(indices[i]), end: UInt(indices[i+1]))
            connections.append(connection)
        }
        return connections
    }
    
    static func nasalisConnections() -> [Connection] {
        // Indices corresponding to the chin landmarks
        let indices: [Int] = [6, 351, 412, 399, 456, 248, 195, 3, 236, 174, 188, 122, 6]
        // Initialize an empty array to store the connections
        var connections: [Connection] = []
        // Create connections between the landmarks
        for i in 0..<indices.count-1 {
            let connection = Connection(start: UInt(indices[i]), end: UInt(indices[i+1]))
            connections.append(connection)
        }
        return connections
    }
    
    static func orbOccConnections() -> [Connection] {
        // Indices corresponding to the chin landmarks
        let leftOuterIndices: [Int] = [465, 357, 350, 349, 348, 347, 346, 340, 265, 353, 276, 283, 282, 295, 285, 417, 465]
        let rightOuterIndices: [Int] = [245, 128, 128, 121, 120, 119, 118, 117, 111, 35, 124, 46, 53, 52, 65, 55, 193, 245]
        let rightInnerIndices: [Int] = [243, 112, 26, 22, 23, 24, 110, 25, 130, 247, 30, 29, 27, 28, 56, 190, 243]
        let leftInnerIndices: [Int] = [463, 341, 256, 252, 253, 254, 339, 255, 359, 467, 260, 259, 257, 258, 286, 414, 463]
        var connections: [Connection] = []

        // Create connections between the landmarks
        for i in 0..<leftOuterIndices.count-1 {
            let connection = Connection(start: UInt(leftOuterIndices[i]), end: UInt(leftOuterIndices[i+1]))
            connections.append(connection)
        }
        for i in 0..<rightOuterIndices.count-1 {
            let connection = Connection(start: UInt(rightOuterIndices[i]), end: UInt(rightOuterIndices[i+1]))
            connections.append(connection)
        }
        for i in 0..<rightInnerIndices.count-1 {
            let connection = Connection(start: UInt(rightInnerIndices[i]), end: UInt(rightInnerIndices[i+1]))
            connections.append(connection)
        }
        for i in 0..<leftInnerIndices.count-1 {
            let connection = Connection(start: UInt(leftInnerIndices[i]), end: UInt(leftInnerIndices[i+1]))
            connections.append(connection)
        }
        return connections
    }
    
    static func orbOrisConnections() -> [Connection] {
        // Indices corresponding to the chin landmarks
        let indicesInnerOrb: [Int] = [0,267, 269, 270, 409, 291, 375, 321, 405, 314, 17, 84, 181, 91, 146, 61, 185, 40, 39, 37, 0]
        let indicesOuterOrb: [Int] = [287, 273, 335, 406, 313, 18, 83, 182, 106,43, 57, 186, 92, 165, 167, 164, 393, 391, 322, 410, 287]
        // Initialize an empty array to store the connections
        var connections: [Connection] = []
        // Create connections between the landmarks
        for i in 0..<indicesInnerOrb.count-1 {
            let connection = Connection(start: UInt(indicesInnerOrb[i]), end: UInt(indicesInnerOrb[i+1]))
            connections.append(connection)
        }
        
        for i in 0..<indicesOuterOrb.count-1 {
            let connection = Connection(start: UInt(indicesOuterOrb[i]), end: UInt(indicesOuterOrb[i+1]))
            connections.append(connection)
        }
        return connections
    }
    
}


extension OverlayView {

    @objc private func handlePanGesture(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)

        if let viewToDrag = gesture.view {
            // Update constraints instead of setting center
            syringeTopConstraint.constant += translation.y
            syringeLeadingConstraint.constant += translation.x
            gesture.setTranslation(CGPoint.zero, in: self)
        }

        if gesture.state == .ended {
            // Call layoutIfNeeded if you want to animate the final position adjustment
            UIView.animate(withDuration: 0.3) {
                self.layoutIfNeeded()
            }
        }
    }


    @objc private func handleRotationGesture(gesture: UIRotationGestureRecognizer) {
        guard let viewToRotate = gesture.view else { return }
        // Rotate the view
        viewToRotate.transform = viewToRotate.transform.rotated(by: gesture.rotation)
        // Reset the rotation of the gesture for the next change
        gesture.rotation = 0
    }

    private func checkIntersectionWithFace() -> DotInfo? {
        let xCenter = draggableSyringeView.center
        // check if we have the draggable x position
        for faceOverlay in faceOverlays {
            for dot in faceOverlay.dots {
                if isPoint(xCenter, nearPoint: dot, threshold: 45.0) { // Adjust threshold as needed
                    let translation = Translation(deltaX: dot.x - xCenter.x, deltaY: dot.y - xCenter.y)
                    
                    if let indexNearestDot = faceOverlay.dots.firstIndex(of: dot) {
                        let angleOfInjection = printRotationAngleOfDraggable()
                        let positionY = DotInfo(index: indexNearestDot, translation: translation, angleInject: angleOfInjection)
                        return positionY
                    } else {
                        // Handle the case where index is not found
                        return nil
                    }
                }
            }
        }
        return nil
    }

    private func isPoint(_ point: CGPoint, nearPoint otherPoint: CGPoint, threshold: CGFloat) -> Bool {
        return abs(point.x - otherPoint.x) < threshold && abs(point.y - otherPoint.y) < threshold
    }
    
    func captureFullScreenshot(cameraFeedService: CameraFeedService) -> UIImage? {
        guard let baseImage = cameraFeedService.captureCurrentFrame() else { return nil }

        UIGraphicsBeginImageContextWithOptions(baseImage.size, false, 0)
        baseImage.draw(at: .zero) // Draw the base image

        // Determine if the device is an iPhone or iPad
        let isIphone = UIDevice.current.userInterfaceIdiom == .phone
        let iphoneScale = (baseImage.size.width / self.bounds.width) - 0.45
        let ipadScale = baseImage.size.width / self.bounds.width
        let scale: CGFloat = isIphone ? iphoneScale : ipadScale
        let verticalShift: CGFloat = isIphone ? 0 : 240 // Adjust these values for iPhone and iPad
        let horizontalShift: CGFloat = isIphone ? 100 : 10 // Adjust these values for iPhone and iPad

        let context = UIGraphicsGetCurrentContext()
        context?.scaleBy(x: scale, y: scale)
        context?.translateBy(x: horizontalShift / scale, y: verticalShift / scale)

        // Draw the overlay content
        self.layer.render(in: context!)

        let fullScreenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return fullScreenshot
    }




    @objc private func injectButtonTapped() {
        
        guard let units = unitsTextField.text, !units.isEmpty else {
                presentAlert?("Warning", "Please add a number of units")
                return
            }


        if yMarkLabels.count != targetPoints.count{
            
            if let position = checkIntersectionWithFace() {
                let units = unitsTextField.text ?? "0"
                let unitsInt = Int(units)!
                let selectedDrugIndex = drugPicker.selectedRow(inComponent: 0)
                let drug = drugs[selectedDrugIndex]
                let injection_number = yMarkLabels.count + 1
                
               
                //units is instantiated here
                dotHolders.dots.append(position)
                addNewYMarkLabel(injection_number, userDosage: unitsInt, idealDoseTarget: nil)
//                unitsTextField.text = ""

                
                if yMarkLabels.count == targetPoints.count {
                    updateTargets()
                    updateYMarkPositions()
                    finishingChangesAndResults()
                    return
                }
                
            }
        }
    }
    
    private func presentAlert(message: String) {
        
    }
    
    @objc private func muscleToggleButtonTapped() {
        areMuscleLinesVisible.toggle() // Toggle visibility state
        redrawFaceOverlays(forNewDeviceOrientation: orientation)
    }
    
    @objc private func targetToggleButtonTapped() {
            areTargetsVisible.toggle()
            updateTargets()
    }
    
    @objc private func finishingChangesAndResults() {
        var score = 0
        let scoreDenom = yMarkLabels.count
        hitTargetHolder = [-2]
        var hittingYmarkLabels: [(label: UILabel, score: CGFloat, angle: CGFloat, hittingTarget: Int?, userDosage: Int?, idealDoseTarget: Int?)] = []
        
        
           
        var onTargetInjections: [Injection] = []
        
        for yMarkLabel in yMarkLabels {

            if let hittingTarget = yMarkLabel.hittingTarget,
               yMarkLabel.score < 0.05,
               !hitTargetHolder.contains(hittingTarget),
               let injectionNumberText = yMarkLabel.label.text, // Correctly accessing label.text here
               let injectionNumber = Int(injectionNumberText),
               let doseApplied = yMarkLabel.userDosage {
                let idealDose = yMarkLabel.idealDoseTarget ?? 0 // Assuming you corrected the field name to idealDose

                let newInjection = Injection(injectionNumber: injectionNumber, doseApplied: doseApplied, idealDose: idealDose)
                onTargetInjections.append(newInjection)
                score += 1
                // Add newInjection to an array or use it as needed
            } else {
                yMarkLabel.label.textColor = .red
            }
        }
        
        let message = score == scoreDenom ? "" : ""
        let scoreMessage = "You hit \(score) targets out of \(scoreDenom). \n\(message)"
        draggableSyringeView.isHidden = true
        clearButton.isHidden = true
        treatmentPatternButton.isHidden = true
        injectButton.isHidden = true
       
        targetToggleButton.isHidden = true
        muscleToggleButton.isHidden = true
        syringeCalibrationView.isHidden = true
        hintsBoxView.isHidden = true
        areMuscleLinesVisible = true
        redrawFaceOverlays(forNewDeviceOrientation: orientation)
        if !areTargetsVisible {
            targetToggleButtonTapped()
        }
        let screenshot = captureFullScreenshot(cameraFeedService: cameraFeedService!)
        targetToggleButtonTapped()
        syringeCalibrationView.isHidden = false
        hintsBoxView.isHidden = false
        draggableSyringeView.isHidden = false
        clearButton.isHidden = false
        treatmentPatternButton.isHidden = false
        injectButton.isHidden = false
        targetToggleButton.isHidden = false
        muscleToggleButton.isHidden = false
        areTargetsVisible = false
        areMuscleLinesVisible = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Instantiate and present ResultsViewController
            self.delegate?.presentResultsViewController(with: screenshot, scoreMessage: scoreMessage, onTargetInjections: onTargetInjections)
            self.clearButtonTapped()
        }
    }
    
    
    @objc private func clearButtonTapped() {
        dotHolders.dots.removeAll()
        yMarkLabels.forEach { $0.label.removeFromSuperview() }
        yMarkLabels.removeAll()
        for index in targetPoints.indices {
                targetPoints[index].isHit = false
            }
        //        unitsTextField.text = ""
    }
    
    @objc private func toggleTreatmentPattern() {
        // Define your treatment patterns
        clearButtonTapped()
        resetSyringePosition()
        
        var treatmentPatterns: [[Int]] = []
        var treatmentIdealDoses: [[Int]] = []
            
        if let crowsFeetAnchors = treatmentPattern["crow's feet"]?["anchors"] as? [Int],
           let frownLinesAnchors = treatmentPattern["frown lines"]?["anchors"] as? [Int],
           let foreheadLinesAnchors = treatmentPattern["forehead lines"]?["anchors"] as? [Int] {
            
            
            treatmentPatterns = [
                crowsFeetAnchors,
                frownLinesAnchors,
                foreheadLinesAnchors
            ]
        }
        
        if let crowsFeetIdealDoses = treatmentPattern["crow's feet"]?["idealDoses"] as? [Int],
           let frownLinesIdealDoses = treatmentPattern["frown lines"]?["idealDoses"] as? [Int],
           let foreheadLinesIdealDoses = treatmentPattern["forehead lines"]?["idealDoses"] as? [Int] {
            
            treatmentIdealDoses = [
                crowsFeetIdealDoses,
                frownLinesIdealDoses,
                foreheadLinesIdealDoses
            ]
        }
    
        // Cycle through the patterns
        currentTreatmentPatternIndex = (currentTreatmentPatternIndex+1) % treatmentPatterns.count

        // Update the button title and treatment pattern
        let patternName: String
        switch currentTreatmentPatternIndex {
        case 0:
            patternName = "crow's feet"
        case 1:
            patternName = "frown lines"
        case 2:
            patternName = "forehead lines"
        default:
            patternName = "crow's feet"
        }

        titleLabel.text = patternName
        let instructionsMessage = getInstructions(for: patternName)
        instructionsDelegate?.presentInstructions(with: instructionsMessage)
        treatmentAnchorsHolder[0] = treatmentPatterns[currentTreatmentPatternIndex]
        treatmentAnchorsHolder[1] = treatmentIdealDoses[currentTreatmentPatternIndex]
        setupTargetPoints()
    }
    
    func getInstructions(for pattern: String) -> [String] {
        // Return the instructions based on the patter
        switch pattern {
        case "crow's feet":
            return ["Instructions for Crow's Feet",
                    "1) Select your Drug and Dose",
                    "2) Move your ipad to around 10 inches away from the patients face",
                    "3) Ask Patient to smile",
                    "4) Line up the needle and make sure your angle is correct",
                    "5) Press inject"]
        case "frown lines":
            return ["Instructions for Frown Lines",
                    "1) Select your Drug and Dose",
                    "2) Move your ipad to around 10 inches away from the patients face",
                    "3) Ask patient to make a frown",
                    "4) Line up the needle and make sure your angle is correct",
                    "5) Press inject"]
        case "forehead lines":
            return ["Instructions for Forehead Lines",
                    "1) Select your Drug and Dose",
                    "2) Move your ipad to around 10 inches away from the patients face",
                    "3) Ask patient to look surprised",
                    "4) Line up the needle and make sure your angle is correct",
                    "5) Press inject"]
        default:
            return [""]
        }
    }

    func realignDotsForNewOrientation() {
        
        clearButtonTapped()
        let patternName: String
        switch currentTreatmentPatternIndex {
        case 0:
            patternName = "crow's feet"
        case 1:
            patternName = "frown lines"
        case 2:
            patternName = "forehead lines"
        default:
            patternName = "crow's feet"
        }

        titleLabel.text = patternName
        let instructionsMessage = getInstructions(for: patternName)
        instructionsDelegate?.presentInstructions(with: instructionsMessage)
    }
}

