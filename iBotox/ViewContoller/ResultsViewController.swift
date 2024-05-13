//  iBotox
//
//  Created by Tanveer Ashraf on 14/04/2024.
//

import UIKit

class CollectionViewHeader: UICollectionReusableView {
    static let identifier = "CollectionViewHeader"
    

    let injectionLabel = UILabel()
    let doseAppliedLabel = UILabel()
    let idealDoseLabel = UILabel()


    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
            injectionLabel.text = "Injection"
            doseAppliedLabel.text = "Dose Applied"
            idealDoseLabel.text = "Recommended Dose"

            let isIphone = UIDevice.current.userInterfaceIdiom == .phone
            let fontSize: CGFloat = isIphone ? 14 : 18 // Use smaller font size for iPhone

            [injectionLabel, doseAppliedLabel, idealDoseLabel].forEach { label in
                label.textAlignment = .center
                label.font = UIFont.boldSystemFont(ofSize: fontSize)
                label.numberOfLines = 0
            }
        
            let stackView = UIStackView(arrangedSubviews: [injectionLabel, doseAppliedLabel, idealDoseLabel])
            stackView.axis = .horizontal
            stackView.distribution = .fillEqually
            stackView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(stackView)

            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: topAnchor),
                stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor)
            ])
        }
}


class CustomCollectionViewCell: UICollectionViewCell {
    static let identifier = "CustomCollectionViewCell"
    
    let injectionLabel = UILabel()
    let doseAppliedLabel = UILabel()
    let idealDoseLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCellViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCellViews() {
//        injectionLabel.translatesAutoresizingMaskIntoConstraints = false
//        doseAppliedLabel.translatesAutoresizingMaskIntoConstraints = false
//        idealDoseLabel.translatesAutoresizingMaskIntoConstraints = false
         [injectionLabel, doseAppliedLabel, idealDoseLabel].forEach { label in
                label.textAlignment = .center
                label.numberOfLines = 0
            }

           let stackView = UIStackView(arrangedSubviews: [injectionLabel, doseAppliedLabel, idealDoseLabel])
           stackView.distribution = .fillEqually
           stackView.alignment = .center // Ensure this is set to center
           stackView.translatesAutoresizingMaskIntoConstraints = false
           addSubview(stackView)

        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}

class ResultsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    
    @IBOutlet weak var resultsLabel: UILabel!
    var screenshot: UIImage?
    var scoreMessage: String?
    var onTargetInjections: [Injection]? // Add this line
    var collectionView: UICollectionView!
    var collectionViewHeightConstraint: NSLayoutConstraint?

    private var tableView: UITableView!

    @IBOutlet weak var screenshotImageView: UIImageView!
    
    private var titleLabel: UILabel!
    private var speechBubbleView: UIImageView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        setupTitleLabel()
        setupSpeechBubbleView()
        setupResultsLabel()
        setupCollectionView()
        updateCollectionViewHeight()
        
        // Determine the device type and orientation
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        let isLandscape = UIDevice.current.orientation.isLandscape

        if isIpad && !isLandscape {
            setupLayoutForIpadPortrait()
        } else if isLandscape && isIpad {
            setupLayoutForIpadHorizontal()
        } else if !isIpad && isLandscape {
            setupLayoutForIphoneHorizontal()
        } else if !isIpad && !isLandscape {
            setupLayoutForIphonePortrait()
        }

        // Common setup for screenshotImageView
        

        // Close button
        setupCloseButton()
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0.1

        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.register(CustomCollectionViewCell.self, forCellWithReuseIdentifier: CustomCollectionViewCell.identifier)
        collectionView.register(CollectionViewHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CollectionViewHeader.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear // Background color of collectionView itself
        view.addSubview(collectionView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // Border customization
        collectionView.layer.borderColor = UIColor.darkGray.cgColor // Set border color
        collectionView.layer.borderWidth = 2.0 // Set border width
        collectionView.layer.cornerRadius = 10 // Set corner radius for rounded corners
        
        // Shadow customization for a more "stylish" look
        collectionView.layer.shadowColor = UIColor.black.cgColor // Shadow color
        collectionView.layer.shadowOffset = CGSize(width: 0, height: 2) // Shadow direction and distance
        collectionView.layer.shadowOpacity = 0.5 // Shadow opacity
        collectionView.layer.shadowRadius = 5.0 // Shadow blurriness
        
        // It's important to set the collectionView's clipsToBounds to false to allow the shadow to be visible outside its bounds
        collectionView.clipsToBounds = false
        collectionViewHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: calculateCollectionViewHeight())
        collectionViewHeightConstraint?.isActive = true
    }
    
    private func updateCollectionViewHeight() {
            let newHeight = calculateCollectionViewHeight()
            collectionViewHeightConstraint?.constant = newHeight

            // Animate the height change if desired
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
    
    private func calculateCollectionViewHeight() -> CGFloat {
        let maxRows = 6
        let itemHeight: CGFloat = 35
        let headerHeight: CGFloat = 50
        let spacingBetweenRows: CGFloat = 1 // Assuming there's a spacing of 10 points between rows
        let bottomPadding: CGFloat = 20 // Additional space at the bottom

        let numberOfRows = min(onTargetInjections?.count ?? 0, maxRows)
        let totalHeight = (itemHeight * CGFloat(numberOfRows)) + headerHeight + (spacingBetweenRows * CGFloat(max(0, numberOfRows - 1))) + bottomPadding

        return totalHeight
    }


    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 50) // Adjust the height as needed
    }

    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }

        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CollectionViewHeader.identifier, for: indexPath) as! CollectionViewHeader
        // The labels are already set up in the header's setupViews method, so you don't need to customize them here unless you want to change them dynamically
        return header
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return onTargetInjections?.count ?? 0
        }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CustomCollectionViewCell.identifier, for: indexPath) as? CustomCollectionViewCell else {
                fatalError("Unable to dequeue CustomCollectionViewCell")
            }
            
            if let injection = onTargetInjections?[indexPath.row] {
                cell.injectionLabel.text = "Injection \(injection.injectionNumber)"
                cell.doseAppliedLabel.text = "\(injection.doseApplied) units"
                cell.idealDoseLabel.text = "\(injection.idealDose)"
            }
            
            return cell
        }
        
        // Optional: Implementing sizeForItemAt to adjust cell size
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 35) // Customize as needed
    }
    
    
    
    
    private func setupTitleLabel() {
        titleLabel = UILabel()
        titleLabel.text = "Results"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupSpeechBubbleView() {
        speechBubbleView = UIImageView()
        speechBubbleView.image = UIImage(named: "speech_bubble")
        speechBubbleView.contentMode = .scaleToFill
        speechBubbleView.translatesAutoresizingMaskIntoConstraints = false
        speechBubbleView.backgroundColor = .clear
    }
    
    private func setupResultsLabel() {
        resultsLabel.numberOfLines = 0
        resultsLabel.lineBreakMode = .byWordWrapping
        resultsLabel.backgroundColor = .clear
        resultsLabel.text = scoreMessage
        resultsLabel.font = UIFont(name: "Helvetica Neue", size: 28)
        resultsLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func resizeImageToScreenWidth(_ image: UIImage) -> UIImage? {
        let screenWidth = UIScreen.main.bounds.width
        let scale = screenWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: screenWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: screenWidth, height: newHeight))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }


    func cropImage(_ inputImage: UIImage, toRect cropRect: CGRect) -> UIImage? {
        let cgImage = inputImage.cgImage!
        let croppedCgImage = cgImage.cropping(to: cropRect)
        return croppedCgImage.map { UIImage(cgImage: $0) }
    }

    private func setupScreenshotImageView() {
        let resizedScreenshot = resizeImageToScreenWidth(screenshot!)
        
        let startY = 200 // The number of pixels from the top to start cropping
        let cropRect = CGRect(x: 0, y: startY, width: Int(resizedScreenshot!.size.width), height: Int(resizedScreenshot!.size.height) - startY)
        
        let croppedImage = resizedScreenshot.flatMap { cropImage($0, toRect: cropRect) }
        screenshotImageView.image = croppedImage
        screenshotImageView.contentMode = .scaleAspectFit
        screenshotImageView.translatesAutoresizingMaskIntoConstraints = false
        screenshotImageView.backgroundColor = .clear
        view.addSubview(screenshotImageView)

    }

    
    private func setupLayoutForIpadPortrait() {
        setupScreenshotImageView() // Make sure this is called to setup the screenshotImageView
    // Initialize and configure the tableView
        view.addSubview(titleLabel)
        view.addSubview(speechBubbleView)
        speechBubbleView.addSubview(resultsLabel)
        view.addSubview(screenshotImageView) // Make sure the screenshotImageView is added to the view

        ///
        collectionView.translatesAutoresizingMaskIntoConstraints = false

           // Ensure collectionViewHeightConstraint is updated based on the initial content
       let height = calculateCollectionViewHeight() // Calculate dynamic height
       collectionViewHeightConstraint?.constant = height
        ///
        // Layout constraints for iPad Portrait
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 30),
            
            speechBubbleView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            speechBubbleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            speechBubbleView.widthAnchor.constraint(equalToConstant: 800),
            speechBubbleView.heightAnchor.constraint(equalToConstant: 200),
            
            resultsLabel.centerXAnchor.constraint(equalTo: speechBubbleView.centerXAnchor),
            resultsLabel.centerYAnchor.constraint(equalTo: speechBubbleView.centerYAnchor),
            resultsLabel.widthAnchor.constraint(lessThanOrEqualTo: speechBubbleView.widthAnchor, constant: -20),
            resultsLabel.heightAnchor.constraint(lessThanOrEqualTo: speechBubbleView.heightAnchor, constant: -20),
            
            // Constraints for screenshotImageView
            screenshotImageView.topAnchor.constraint(equalTo: speechBubbleView.bottomAnchor, constant: 20),
            screenshotImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            screenshotImageView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40), // Adjust the width as necessary
            screenshotImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/2), // Set height to one-third of the view's height
            
//            // Constraints for collectionView
//            collectionView.topAnchor.constraint(equalTo: screenshotImageView.bottomAnchor, constant: 20),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            collectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            collectionView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40), // Adjust the width as necessary
           /* collectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/3),*/ // Set height to one-third of the view's height
            collectionViewHeightConstraint!,
        ])
    }

    
    private func setupLayoutForIphonePortrait() {
        setupScreenshotImageView()
        view.addSubview(titleLabel)
        view.addSubview(speechBubbleView)
        speechBubbleView.addSubview(resultsLabel)
        // Layout constraints for iPhone portrait
        let height = calculateCollectionViewHeight() // Calculate dynamic height
        collectionViewHeightConstraint?.constant = height
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 7),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 30),
            
            speechBubbleView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 7),
            speechBubbleView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5), // 5 points from the left edge
            speechBubbleView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5), // 5 points from the right edge
            speechBubbleView.heightAnchor.constraint(equalToConstant: 200),
            
            resultsLabel.centerXAnchor.constraint(equalTo: speechBubbleView.centerXAnchor),
            resultsLabel.centerYAnchor.constraint(equalTo: speechBubbleView.centerYAnchor),
            resultsLabel.widthAnchor.constraint(lessThanOrEqualTo: speechBubbleView.widthAnchor, constant: -150), // 50 points padding on each side
            resultsLabel.topAnchor.constraint(greaterThanOrEqualTo: speechBubbleView.topAnchor, constant: 20), // Padding from top
            resultsLabel.bottomAnchor.constraint(lessThanOrEqualTo: speechBubbleView.bottomAnchor, constant: -20),

            // Adjust screenshotImageView constraints as needed
            screenshotImageView.topAnchor.constraint(equalTo: speechBubbleView.bottomAnchor, constant: 20),
//            screenshotImageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 5),
            screenshotImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            screenshotImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5), // 5 points from the left edge
            screenshotImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5),
            screenshotImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/3),

            collectionView.topAnchor.constraint(greaterThanOrEqualTo: screenshotImageView.bottomAnchor, constant: 10),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -5),
            collectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            collectionView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40), // Adjust the width as necessary
           /* collectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/3),*/ // Set height to one-third of the view's height
            collectionViewHeightConstraint!,
        ])
    }
    
    private func setupLayoutForIpadHorizontal() {
        view.addSubview(titleLabel)
        view.addSubview(speechBubbleView)
        resultsLabel.text = "View Results in Portrait View. Press close."
        speechBubbleView.addSubview(resultsLabel)
    
        // Layout constraints for iPad
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 30),
            
            speechBubbleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            speechBubbleView.centerYAnchor.constraint(equalTo: view.centerYAnchor), // Center vertically
            speechBubbleView.widthAnchor.constraint(equalToConstant: 800),
            speechBubbleView.heightAnchor.constraint(equalToConstant: 200),
            
            resultsLabel.centerXAnchor.constraint(equalTo: speechBubbleView.centerXAnchor),
            resultsLabel.centerYAnchor.constraint(equalTo: speechBubbleView.centerYAnchor),
            resultsLabel.widthAnchor.constraint(lessThanOrEqualTo: speechBubbleView.widthAnchor, constant: -20),
            resultsLabel.heightAnchor.constraint(lessThanOrEqualTo: speechBubbleView.heightAnchor, constant: -20)
        ])
    }

    private func setupLayoutForIphoneHorizontal() {
        view.addSubview(titleLabel)
        view.addSubview(speechBubbleView)
        resultsLabel.text = "View Results in Portrait View. Press close."
        speechBubbleView.addSubview(resultsLabel)
    
        // Layout constraints for iPad
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 30),
            
            speechBubbleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            speechBubbleView.centerYAnchor.constraint(equalTo: view.centerYAnchor), // Center vertically
            speechBubbleView.widthAnchor.constraint(equalToConstant: 800),
            speechBubbleView.heightAnchor.constraint(equalToConstant: 200),
            
            resultsLabel.centerXAnchor.constraint(equalTo: speechBubbleView.centerXAnchor),
            resultsLabel.centerYAnchor.constraint(equalTo: speechBubbleView.centerYAnchor),
            resultsLabel.widthAnchor.constraint(lessThanOrEqualTo: speechBubbleView.widthAnchor, constant: -20),
            resultsLabel.heightAnchor.constraint(lessThanOrEqualTo: speechBubbleView.heightAnchor, constant: -20)
        ])
    }
    
    
    private func setupCloseButton() {
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
    }

    @objc func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    // Other methods...
}
