//
//  CameraViewController.swift
//  iBotox
//
//  Created by Tanveer Ashraf on 14/04/2024.
//
import UIKit

class InstructionsViewController: UIViewController {
    
    private let containerView = UIView()
    private let messageLabel = UILabel()
    private let closeButton = UIButton()
    
    var message: [String] = [] {
           didSet {
               let attributedString = NSMutableAttributedString()

               // Check if there are elements in the array
               if !message.isEmpty {
                   // Add the title (first element) with bold and center alignment
                   let titleAttributes: [NSAttributedString.Key: Any] = [
                       .font: UIFont.boldSystemFont(ofSize: 24),
                       .paragraphStyle: centerAlignedParagraphStyle()
                   ]
                   let titleString = NSAttributedString(string: message[0] + "\n\n", attributes: titleAttributes)
                   attributedString.append(titleString)

                   // Add the rest of the messages
                   if message.count > 1 {
                       let bodyAttributes: [NSAttributedString.Key: Any] = [
                           .font: UIFont.systemFont(ofSize: 22),
                           .paragraphStyle: bodyParagraphStyle()
                       ]
                       let bodyString = message[1...].joined(separator: "\n")
                       let bodyAttributedString = NSAttributedString(string: bodyString, attributes: bodyAttributes)
                       attributedString.append(bodyAttributedString)
                   }
               }

               messageLabel.attributedText = attributedString
           }
       }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func centerAlignedParagraphStyle() -> NSParagraphStyle {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            return paragraphStyle
    }
    private func bodyParagraphStyle() -> NSParagraphStyle {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 15 // Adjust the line spacing value as needed
            return paragraphStyle
        }
    
    private func setupUI() {
        // Configure the container view
        containerView.backgroundColor = UIColor.white
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.cornerRadius = 20
        containerView.clipsToBounds = true
        view.addSubview(containerView)

        // Configure the message label
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageLabel)

        // Configure the close button
        closeButton.setTitle("X", for: .normal) // Or set an image
        closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        closeButton.setTitleColor(.blue, for: .normal) // Set the color
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        view.bringSubviewToFront(closeButton)

        // Set constraints for the containerView
        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8),
            containerView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.8)
        ])

        // Set constraints for the messageLabel within containerView
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 25),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])

        // Set constraints for the closeButton
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 5),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true, completion: nil)
    }
}
