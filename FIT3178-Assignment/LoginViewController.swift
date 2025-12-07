//
//  LoginViewController.swift
//  FIT3178-Assignment
//
//  Created by Ojaswi Pandey on 12/10/2025.
//
//  This screen lets users log in to their account
//  User enters email and password, we validate it, then send to Firebase
//  After successful login, user goes to the main app

import UIKit

class LoginViewController: UIViewController {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    // databaseController = The manager that handles login
    // We use this to call Firebase signin
    weak var databaseController: DatabaseProtocol?
    
    // When screen first opens, set up everything
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create a tap gesture recognizer
        // When user taps outside text fields, dismiss the keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        // Get the app's main controller
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        // Get the database manager from it
        databaseController = appDelegate?.databaseController
    }
    
    // When user taps the return key on the keyboard
    @objc func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // If user is in the email field
        if textField == emailTextField {
            // Move focus to password field
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            // If in password field, close the keyboard
            textField.resignFirstResponder()
        }
        return true
    }
    
    // When user taps outside any text field
    @objc func dismissKeyboard() {
        // Close the keyboard
        view.endEditing(true)
    }
    
    // When user taps the Log In button
    @IBAction func loginButtonTapped(_ sender: Any) {
        // Step 1: Check if email is entered
        guard let email = emailTextField.text, !email.isEmpty else {
            showError(message: "Please enter your email")
            return
        }
        
        // Step 2: Check if password is entered
        guard let password = passwordTextField.text, !password.isEmpty else {
            showError(message: "Please enter your password")
            return
        }
        
        // Step 3: Disable button to prevent multiple taps
        loginButton.isEnabled = false
        // Change button text to show it's loading
        loginButton.setTitle("Logging in...", for: .normal)
        
        // Step 4: Try to sign in using Firebase
        databaseController?.signIn(email: email, password: password) { [weak self] result in
            // Re-enable button on main thread
            DispatchQueue.main.async {
                // Turn button back on
                self?.loginButton.isEnabled = true
                // Change text back to Log In
                self?.loginButton.setTitle("Log In", for: .normal)
                
                // Check if login was successful or failed
                switch result {
                case .success(let userId):
                    // Login successful
                    print("Login successful! User ID: \(userId)")
                    print("Email: \(email)")
                    // Navigate to main app
                    self?.navigateToMainApp()
                    
                case .failure(let error):
                    // Login failed
                    print("❌ Login failed: \(error.localizedDescription)")
                    
                    // Check what type of error happened
                    let nsError = error as NSError
                    switch nsError.code {
                    case 17011:
                        // Wrong password
                        self?.showError(message: "Incorrect password. Please try again.")
                    case 17008:
                        // Invalid email format
                        self?.showError(message: "Invalid email format.")
                    case 17009:
                        // Wrong password (alternative code)
                        self?.showError(message: "Incorrect password. Please try again.")
                    default:
                        // Other error
                        self?.showError(message: "Login failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // Show an error message popup to the user
    func showError(message: String) {
        let alert = UIAlertController(
            title: "Login Error",
            message: message,
            preferredStyle: .alert
        )
        // Add OK button
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // Navigate to the main app after successful login
    func navigateToMainApp() {
        print("🚀 Navigating to main app...")
        
        // Get the storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarController") as? UITabBarController {
            
            tabBarController.modalPresentationStyle = .fullScreen
            
            present(tabBarController, animated: true) {
                print("✅ Successfully navigated to main app")
            }
        } else {
            // Could not find the tab bar controller in storyboard
            print("ERROR!!!!: Could not find TabBarController in storyboard")
            showError(message: "Navigation error!!. Please contact support!!!!.")
        }
    }
}
