//
//  UIHelper.swift
//  FIT3178-Assignment
//
//  Created by Ojaswi Pandey on 6/12/2025.
//
import Foundation
import UIKit

// MARK: - Color Palette (Dark Mode Compatible)
extension UIColor {
    // Primary brand colors
    static let primaryGreen = UIColor(red: 0.2, green: 0.7, blue: 0.4, alpha: 1.0)
    static let primaryBlue = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0)
    static let accentOrange = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
    
    // Background colors - FIXED: Now adapt to Dark Mode
    static let lightBackground = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // Dark mode background
            : UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0) // Light mode background
    }
    
    static let cardBackground = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0) // Dark mode card
            : UIColor.white // Light mode card
    }
    
    // Text colors - FIXED: Now adapt to Dark Mode
    static let primaryText = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor.white // Dark mode text
            : UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0) // Light mode text
    }
    
    static let secondaryText = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0) // Dark mode secondary text
            : UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0) // Light mode secondary text
    }
}

// MARK: - UI Helper Methods
class UIHelper {
    
    // Add info button to navigation bar
    static func addInfoButton(to viewController: UIViewController, message: String, title: String = "Page Information") {
        let infoButton = UIBarButtonItem(
            image: UIImage(systemName: "info.circle"),
            style: .plain,
            target: viewController,
            action: #selector(viewController.showInfoPopup)
        )
        infoButton.tintColor = .primaryBlue
        
        // Store the message in the view controller
        objc_setAssociatedObject(viewController, &AssociatedKeys.infoMessage, message, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(viewController, &AssociatedKeys.infoTitle, title, .OBJC_ASSOCIATION_RETAIN)
        
        viewController.navigationItem.rightBarButtonItem = infoButton
    }
    
    // Style a card view with shadow and rounded corners
    static func styleCardView(_ view: UIView, cornerRadius: CGFloat = 12, shadowOpacity: Float = 0.1) {
        view.backgroundColor = .cardBackground
        view.layer.cornerRadius = cornerRadius
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = shadowOpacity
        view.layer.shadowRadius = 4
        view.layer.masksToBounds = false
    }
    
    // Style a button with modern appearance
    static func styleButton(_ button: UIButton, color: UIColor = .primaryGreen) {
        button.backgroundColor = color
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        // Add subtle shadow
        button.layer.shadowColor = color.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 3
    }
    
    // Style a text field with border - FIXED: Dark mode compatible
    static func styleTextField(_ textField: UITextField) {
        textField.borderStyle = .roundedRect
        textField.layer.cornerRadius = 8
        textField.layer.borderColor = UIColor.systemGray4.cgColor
        textField.layer.borderWidth = 1
        textField.backgroundColor = .cardBackground
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.textColor = .primaryText // FIXED: Now adapts to Dark Mode
    }
}

// MARK: - Associated Keys for storing data
private struct AssociatedKeys {
    static var infoMessage = "infoMessage"
    static var infoTitle = "infoTitle"
}

// MARK: - UIViewController Extension
extension UIViewController {
    
    @objc func showInfoPopup() {
        // Retrieve stored message and title
        let message = objc_getAssociatedObject(self, &AssociatedKeys.infoMessage) as? String ?? "No information available"
        let title = objc_getAssociatedObject(self, &AssociatedKeys.infoTitle) as? String ?? "Information"
        
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Got it!", style: .default))
        present(alert, animated: true)
    }
    
    // Apply consistent background color to view controller
    func applyStandardBackground() {
        view.backgroundColor = .lightBackground
    }
}
