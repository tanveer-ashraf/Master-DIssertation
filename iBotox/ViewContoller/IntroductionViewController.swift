//  iBotox
//
//  Created by Tanveer Ashraf on 14/04/2024.
//
import UIKit

class IntroductionViewController: UIViewController {
    var logoImageView: UIImageView!
    var startButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        updateLayoutBasedOnTraitCollection(traitCollection)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass ||
           traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            updateLayoutBasedOnTraitCollection(traitCollection)
        }
    }

    private func updateLayoutBasedOnTraitCollection(_ traitCollection: UITraitCollection) {
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        let isLandscape = traitCollection.verticalSizeClass == .compact

        if isIpad && !isLandscape {
            setupLayoutForIpadPortrait()
        } else if isLandscape && isIpad {
            setupLayoutForIpadHorizontal()
        } else if !isIpad && isLandscape {
            setupLayoutForIphoneHorizontal()
        } else if !isIpad && !isLandscape {
            setupLayoutForIphonePortrait()
        }
    }

        
    private func setuplogoImageView() {
        logoImageView = UIImageView()
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.image = UIImage(named: "intro_page_2")
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupStartButton() {
        startButton = UIButton(type: .system)
        startButton.setTitle("Start", for: .normal)
        startButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        startButton.backgroundColor = UIColor.systemBlue
        startButton.setTitleColor(UIColor.white, for: .normal)
        startButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        startButton.layer.cornerRadius = 10
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        
    }
        // Create UIImageView for the logo
        
        private func setupLayoutForIpadPortrait() {
            setuplogoImageView()
            setupStartButton()
            view.addSubview(logoImageView)
            view.addSubview(startButton)
            
            let buttonWidth: CGFloat = 250 // Set your desired fixed width here
            let buttonHeight: CGFloat = 50
            UIKit.NSLayoutConstraint.activate([
                logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 150),
                logoImageView.widthAnchor.constraint(equalToConstant: 600),
                logoImageView.heightAnchor.constraint(equalToConstant: 600),
                startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100), // Adjust the constant as needed
                startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                startButton.widthAnchor.constraint(equalToConstant: buttonWidth),
                startButton.heightAnchor.constraint(equalToConstant: buttonHeight)
            ])
        }
    
    
        private func setupLayoutForIpadHorizontal() {
            setuplogoImageView()
            setupStartButton()
            view.addSubview(logoImageView)
            view.addSubview(startButton)
        }
    
        private func setupLayoutForIphonePortrait() {

                // Ensure logoImageView and startButton are initialized
                if logoImageView == nil {
                    setuplogoImageView()
                }
                if startButton == nil {
                    setupStartButton()
                }

                // Add views if not already in the view hierarchy
                if logoImageView.superview == nil {
                    view.addSubview(logoImageView)
                }
                if startButton.superview == nil {
                    view.addSubview(startButton)
                }

                // Deactivate existing constraints before adding new ones
                NSLayoutConstraint.deactivate(logoImageView.constraints)
                NSLayoutConstraint.deactivate(startButton.constraints)
            let buttonWidth: CGFloat = 250 // Set your desired fixed width here
            let buttonHeight: CGFloat = 50
            
            UIKit.NSLayoutConstraint.activate([
                logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
                logoImageView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -100),
                logoImageView.heightAnchor.constraint(equalToConstant: 600),
                startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100), // Adjust the constant as needed
                startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                startButton.widthAnchor.constraint(equalToConstant: buttonWidth),
                startButton.heightAnchor.constraint(equalToConstant: buttonHeight)
            ])
        }
    
    private func setupLayoutForIphoneHorizontal() {

        // Ensure logoImageView and startButton are initialized
        if logoImageView == nil {
            setuplogoImageView()
        }
        if startButton == nil {
            setupStartButton()
        }

        // Add views if not already in the view hierarchy
        if logoImageView.superview == nil {
            view.addSubview(logoImageView)
        }
        if startButton.superview == nil {
            view.addSubview(startButton)
        }

        // Deactivate existing constraints before adding new ones
        NSLayoutConstraint.deactivate(logoImageView.constraints)
        NSLayoutConstraint.deactivate(startButton.constraints)

        let buttonWidth: CGFloat = 250
        let buttonHeight: CGFloat = 50
        let logoImageHeight: CGFloat = 350
        let gapBetweenLogoAndButton: CGFloat = 10  // Gap between the bottom of logoImageView and top of startButton

        NSLayoutConstraint.activate([
            // Constraints for logoImageView
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            logoImageView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -100),
            logoImageView.heightAnchor.constraint(equalToConstant: logoImageHeight),

            // Constraints for startButton
            startButton.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: gapBetweenLogoAndButton),
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -5), // 5 points from bottom
            startButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            startButton.heightAnchor.constraint(equalToConstant: buttonHeight)
        ])
    }



    
//        view.addSubview(logoImageView)
            // Create and configure the start button at the bottom center
       
        
        // Constraint-based layout for the button
        
       
        
        // Constraints for the button
        // Set your desired fixed height here
    
        
        
    

    @objc func startButtonTapped() {
        // Check if the device is an iPad or iPhone
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad

        // Instantiate the appropriate view controller based on the device type
        let nextViewController = isIpad ? OutlinePageViewController() : RootViewController()

        // Transition to the selected view controller
        let window = UIApplication.shared.windows.first
        window?.rootViewController = nextViewController
        window?.makeKeyAndVisible()
    }}
