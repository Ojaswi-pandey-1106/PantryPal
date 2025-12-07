//
//  SignUpViewController.swift
//  FIT3178-Assignment
//
//  Created by Ojaswi Pandey on 12/10/2025.
//
//  This screen lets users create a new account
//  User enters email and password, we validate it, then save to Firebase
//  After successful signup, user goes to main app

import UIKit

class SignUpViewController: UIViewController {
    
    
    // emailTextField = Where user types their email address
    @IBOutlet weak var emailTextField: UITextField!
    // passwordTextField = Where user types their password
    @IBOutlet weak var passwordTextField: UITextField!
    // confirmPasswordTextField = Where user re-types password to confirm
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    // signUpButton = The button user taps to create account
    @IBOutlet weak var signUpButton: UIButton!
    
    // databaseController = The manager that creates the account
    // We use this to call Firebase signup
    weak var databaseController: DatabaseProtocol?
    
    
    // When screen first opens, get the database controller
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the app's main controller
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        // Get the database manager from it
        databaseController = appDelegate?.databaseController
    }
    
    
    // When user taps the Sign Up button
    @IBAction func signUpButtonTapped(_ sender: Any) {
        // Step 1: Check if email is entered
        guard let email = emailTextField.text, !email.isEmpty else {
            showError(message: "Please enter your email")
            return
        }
        
        // Step 2: Check if password is entered
        guard let password = passwordTextField.text, !password.isEmpty else {
            showError(message: "Please enter a password")
            return
        }
        
        // Step 3: Check if confirm password is entered
        guard let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
            showError(message: "Please confirm your password")
            return
        }
        
        // Step 4: Check if passwords match
        guard password == confirmPassword else {
            showError(message: "Passwords do not match")
            return
        }
        
        // Step 5: Check if password is long enough
        guard password.count >= 6 else {
            showError(message: "Password must be at least 6 characters")
            return
        }
        
        // Step 6: Disable button to prevent multiple taps
        signUpButton.isEnabled = false
        // Change button text to show it's loading
        signUpButton.setTitle("Creating account...", for: .normal)
        
        // Step 7: Try to create account in Firebase
        databaseController?.signUp(email: email, password: password) { [weak self] result in
            // Re-enable button on main thread
            DispatchQueue.main.async {
                // Turn button back on
                self?.signUpButton.isEnabled = true
                // Change text back to Sign Up
                self?.signUpButton.setTitle("Sign Up", for: .normal)
                
                // Check if signup was successful or failed
                switch result {
                case .success(let userId):
                    // Account created successfully
                    print("Sign up successful!")
                    print("User ID: \(userId)")
                    print("Email: \(email)")
                    // Show success message and navigate to main app
                    self?.showSuccessAndNavigate()
                    
                case .failure(let error):
                    // Account creation failed
                    print("Sign up failed!!: \(error.localizedDescription)")
                    
                    // Check what type of error happened
                    let nsError = error as NSError
                    switch nsError.code {
                    case 17007:
                        // Email already in use
                        self?.showError(message: "This email is already registered. Please log in instead.")
                    case 17008:
                        // Invalid email format
                        self?.showError(message: "Please enter a valid email address.")
                    case 17026:
                        // Weak password
                        self?.showError(message: "Password is too weak. Please use a stronger password.")
                    default:
                        // Other error
                        self?.showError(message: "Sign up failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // Show an error message popup to the user
    func showError(message: String) {
        // Create an alert popup
        let alert = UIAlertController(
            title: "Sign Up Error",
            message: message,
            preferredStyle: .alert
        )
        // Add OK button
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        // Show the popup
        present(alert, animated: true)
    }
    
    // Show success message and prepare to navigate to main app
    func showSuccessAndNavigate() {
        // Create success alert
        let alert = UIAlertController(
            title: "Success!!!",
            message: "Your account has been created successfully",
            preferredStyle: .alert
        )
        
        // Create a button that navigates to main app when tapped
        let okAction = UIAlertAction(title: "Get Started", style: .default) { [weak self] _ in
            // When user taps "Get Started", go to main app
            self?.navigateToMainApp()
        }
        
        // Add button to alert
        alert.addAction(okAction)
        // Show the alert
        present(alert, animated: true)
    }
    
    // Navigate to the main app after successful signup
    func navigateToMainApp() {
        print("Navigating to main app......")
        
        // Get the storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // Get the tab bar controller from storyboard
        // Make sure "TabBarController" matches your storyboard ID
        if let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarController") as? UITabBarController {
            
            // Set it to full screen (no animation from bottom)
            tabBarController.modalPresentationStyle = .fullScreen
            
            // Show the tab bar controller
            present(tabBarController, animated: true) {
                print("Successfully navigated to the main app!!")
            }
        } else {
            // Could not find the tab bar controller in storyboard
            print("ERROR!!: Could not find TabBarController in storyboard")
            showError(message: "Navigation error. Please contact support.")
        }
    }
}
