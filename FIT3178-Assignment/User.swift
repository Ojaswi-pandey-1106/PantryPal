//
//  User.swift
//  FIT3178-Assignment
//
//  Created by Ojaswi Pandey on 6/10/2025.
//
//  Stores information about the logged in user
//  Holds user ID and email address
//  Used to pass user info between screens and database controllers

import Foundation

// User = A simple class to hold user information
// When a user logs in, we create a User object with their ID and email
class User: NSObject {
    
    // id = The unique user ID from Firebase
    // Every user gets a unique ID when they create an account
    var id: String?
    
    // email = The user's email address
    // Used for login and displaying user info
    var email: String?
    
    // MARK: - Initialization
    
    // When creating a new User object, pass in the ID and email
    init(id: String?, email: String?) {
        // Save the user ID
        self.id = id
        // Save the user email
        self.email = email
        // Call parent class initialization
        super.init()
    }
}
