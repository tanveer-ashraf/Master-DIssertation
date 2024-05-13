//  iBotox
//
//  Created by Tanveer Ashraf on 14/04/2024.
//

import Foundation
import UIKit

class OutlinePageViewController: UIViewController {

    let instructionsTextView = UITextView()
    let attributedText = NSMutableAttributedString()
    let clipboardImageView = UIImageView()

    var instructionsTextViewLeftConstraint: NSLayoutConstraint?
    var instructionsTextViewRightConstraint: NSLayoutConstraint?
    var instructionsTextViewTopConstraint: NSLayoutConstraint?
    var instructionsTextViewBottomConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    
        clipboardImageView.contentMode = .scaleAspectFit
        clipboardImageView.image = UIImage(named: "clipboard_2") // Replace with your image name
        view.addSubview(clipboardImageView)
        setupClipboardImageViewConstraints()
        
        
        let bulletPoints = [
            "InjectorMate tests your ability to virtually apply facial injections.",
            "You will need a patient to practice on.",
            "Sit opposite patient and point your camera at their face.",
            "Use'Press to change treatment' button at the top to select area",
            "Follow the instruction bubble for each treatment pattern.",
            "Position and angle your need then Inject.",
            "See how high you can score…."
        ]

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 21
        paragraphStyle.firstLineHeadIndent = 0

        for (index, bulletPoint) in bulletPoints.enumerated() {
            let bullet = "•"// You can choose between • (bullet) and – (dash)
            let bulletPointString = "\(bullet) \(bulletPoint)\n\n"
            let attributedBulletPoint = NSAttributedString(string: bulletPointString, attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
            attributedText.append(attributedBulletPoint)
        }
        
        
        // Create and configure the continue button
        let continueButton = UIButton(type: .system)
        continueButton.setTitle("Continue", for: .normal)
        

        // Set fixed width and other characteristics from configureButtonAppearance
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        continueButton.backgroundColor = UIColor.systemBlue
        continueButton.setTitleColor(UIColor.white, for: .normal)
        continueButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        continueButton.layer.cornerRadius = 10

        continueButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(continueButton)
        
        // Constraints for the button
        let buttonWidth: CGFloat = 250 // Set your desired fixed width here
        let buttonHeight: CGFloat = 50 // Set your desired fixed height here
        NSLayoutConstraint.activate([
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100), // Adjust the constant as needed
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            continueButton.heightAnchor.constraint(equalToConstant: buttonHeight)
        ])
        
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        
        view.addSubview(instructionsTextView)
        setupClipboardImageViewConstraints()
        setupInstructionsTextView()
        setupAutoLayoutForInstructionsTextView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLayoutBasedOnCurrentOrientation()
    }
    
    func setupClipboardImageViewConstraints() {
        clipboardImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            clipboardImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            clipboardImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            clipboardImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.95),
            clipboardImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.95)
        ])
    }
    
    func updateLayoutBasedOnCurrentOrientation() {
        let isLandscape = view.frame.width > view.frame.height
        let horizontalPadding: CGFloat = isLandscape ? 350 : 180 // Adjust these values as needed
        let verticalPadding: CGFloat = isLandscape ? 150 : 260   // Adjust these values as needed

        instructionsTextViewLeftConstraint?.constant = horizontalPadding
        instructionsTextViewRightConstraint?.constant = -horizontalPadding
        instructionsTextViewTopConstraint?.constant = verticalPadding
        instructionsTextViewBottomConstraint?.constant = -verticalPadding

        view.layoutIfNeeded()
    }
    
    func setupInstructionsTextView() {
        instructionsTextView.attributedText = attributedText
        instructionsTextView.isEditable = false
        instructionsTextView.isScrollEnabled = true
        instructionsTextView.textAlignment = .left
        instructionsTextView.backgroundColor = .clear
        instructionsTextView.font = UIFont.systemFont(ofSize: 25)
        instructionsTextView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
   }
    
    func setupAutoLayoutForInstructionsTextView() {
        instructionsTextView.translatesAutoresizingMaskIntoConstraints = false
        
        instructionsTextViewLeftConstraint = instructionsTextView.leftAnchor.constraint(equalTo: clipboardImageView.leftAnchor, constant: 180)
        instructionsTextViewRightConstraint = instructionsTextView.rightAnchor.constraint(equalTo: clipboardImageView.rightAnchor, constant: -180)
        instructionsTextViewTopConstraint = instructionsTextView.topAnchor.constraint(equalTo: clipboardImageView.topAnchor, constant: 260)
        instructionsTextViewBottomConstraint = instructionsTextView.bottomAnchor.constraint(equalTo: clipboardImageView.bottomAnchor, constant: -260)
        
        
        NSLayoutConstraint.activate([
               instructionsTextViewLeftConstraint!,
               instructionsTextViewRightConstraint!,
               instructionsTextViewTopConstraint!,
               instructionsTextViewBottomConstraint!
       ])
    }
    
    @objc func continueButtonTapped() {
        // Transition to RootViewController
        let rootViewController = RootViewController()
        let window = UIApplication.shared.windows.first
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()
    }
}
