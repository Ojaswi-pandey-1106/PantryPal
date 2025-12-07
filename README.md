🥘 PantryPal
A comprehensive iOS app for smart pantry management, recipe discovery, and personalized nutrition tracking

PantryPal is a full-featured iOS application built for FIT3178 Mobile App Development at Monash University. It helps users manage their pantry inventory, discover recipes based on available ingredients, track shopping lists, and monitor their health metrics—all in one seamless experience.

📱 Features
🍽️ Pantry Management

- Real-time Cloud Sync: All pantry items stored in Firebase Firestore with instant synchronization
- Barcode Scanning: Scan product barcodes using device camera to instantly add items
- Automatic Nutritional Data: Fetches calories, fat, carbs, protein, and nutrition grades from OpenFoodFacts API
- Smart Categorization: Automatically categorizes items (Beverages, Dairy, Fruits, Vegetables, Grains, Proteins, Snacks, Condiments)
- Expiry Date Tracking: Monitor when items expire to reduce food waste
- Category Filtering: Filter pantry items by food category for easy organization
- Search Functionality: Quickly find specific items in your pantry
- Duplicate Detection: Automatically increments quantity when scanning existing barcoded items

🛒 Shopping List

- Add Items Manually: Create shopping lists with item name, quantity, and category
- Barcode Integration: Scan barcodes to add items directly to shopping list
- One-Tap Pantry Transfer: Tap items to move them from shopping list to pantry with quantity selection
- Category Organization: Organize shopping items by food category
- Cloud Persistence: Shopping lists sync across devices via Firebase

🍳 Recipe Suggestions

- Ingredient-Based Search: Discover recipes using ingredients already in your pantry
- Spoonacular API Integration: Access thousands of recipes with detailed instructions
- Smart Ranking: Recipes ranked by ingredient match percentage
- Missing Ingredient Detection: See which ingredients you need to buy
- Recipe Details: View cooking time, servings, step-by-step instructions, and nutritional info
- Interactive Cooking Timers: Automatic timer buttons for time-based instructions
- Recipe Liking System: Save favorite recipes using CoreData for offline access
- Shopping List Integration: Add missing ingredients directly to shopping list

❤️ Liked Recipes (CoreData)

- Local Storage: Favorite recipes stored on-device using CoreData
- Offline Access: View liked recipes without internet connection
- Search & Filter: Quickly find saved recipes
- Date Tracking: See when you saved each recipe
- Swipe to Unlike: Easy removal of recipes you no longer want

💪 Health Dashboard

- BMI Calculator: Calculate Body Mass Index based on weight and height
- Personalized Calorie Goals: Get daily calorie recommendations based on: Current weight and height
- Fitness goals (maintain, mild weight loss, weight loss)
- Activity level (moderate activity assumed)
- Interactive Steppers: Easily adjust weight and height values
- Visual Goal Display: Clean card-based layout showing calorie targets

🔐 User Authentication

- Firebase Authentication: Secure sign-up and login system
- Email/Password Auth: Standard authentication with validation
- User-Specific Data: Each user's pantry, shopping list, and liked recipes are private
- Session Persistence: Stay logged in across app launches


🛠️ Technologies Used
Languages & Frameworks
Swift 5: Primary programming language
UIKit: User interface framework
SwiftUI Elements: Modern UI components where applicable
Storyboard: Interface Builder for UI design

Backend & Database
Firebase Authentication: User authentication and session management
Firebase Firestore: NoSQL cloud database for real-time data sync
CoreData: Local persistence for liked recipes

APIs & External Services
Spoonacular API: Recipe data, ingredients, and cooking instructions
OpenFoodFacts API: Product information and nutritional data from barcodes
AVFoundation: Camera control for barcode scanning
Vision Framework: Barcode detection and recognition

Architecture & Design Patterns
MVVM Architecture: Separation of concerns with Model-View-ViewModel
Protocol-Oriented Programming: DatabaseProtocol, DatabaseListener
Delegation Pattern: Database change notifications to view controllers
Multicast Delegates: Multiple listeners for database changes
Observer Pattern: Real-time Firebase snapshot listeners

Key iOS Frameworks
AVFoundation - Camera and barcode scanning
Vision - Barcode detection using VNBarcodeObservation
CoreData - Local data persistence
UIKit - User interface components
Foundation - Core data structures and utilities


📂 Project Structure
FIT3178-Assignment/
├── AppDelegate.swift                    # App lifecycle and initialization
├── SceneDelegate.swift                  # Scene lifecycle management
│
├── Authentication/
│   ├── LoginViewController.swift        # User login screen
│   └── SignUpViewController.swift       # Account creation screen
│
├── Pantry/
│   ├── PantryTableViewController.swift  # Main pantry display
│   ├── Pantry.swift                     # Pantry model with nutrition data
│   └── BarcodeScannerViewController.swift # Camera-based barcode scanner
│
├── Shopping List/
│   ├── ShoppingListTableViewController.swift  # Shopping list management
│   └── ShoppingItem.swift               # Shopping item model
│
├── Recipes/
│   ├── RecipeTableViewController.swift  # Recipe search results
│   ├── RecipeDetailViewController.swift # Detailed recipe view with timers
│   ├── RecipeTableViewCell.swift        # Custom recipe cell design
│   ├── Recipe.swift                     # Recipe data model
│   └── RecipeAPIService.swift           # Spoonacular API communication
│
├── Liked Recipes/
│   ├── LikedRecipesViewController.swift # Saved recipes (CoreData)
│   ├── LikedRecipe+CoreDataClass.swift  # CoreData entity
│   └── LikedRecipe+CoreDataProperties.swift
│
├── Health Dashboard/
│   └── UserDashboardViewController.swift # BMI & calorie calculator
│
├── Database/
│   ├── DatabaseProtocol.swift           # Database interface
│   ├── FirebaseController.swift         # Firebase implementation
│   ├── CoreDataController.swift         # CoreData implementation
│   └── MulticastDelegate.swift          # Multi-listener support
│
├── Models/
│   ├── User.swift                       # User data model
│   └── FoodCategory.swift               # Food category enum
│
└── Utilities/
    └── UIHelper.swift                   # UI styling and helper methods

🔥 Firebase Architecture
Firestore Collections
pantryItems Collection
javascript{
  name: String,
  quantity: Int,
  calories: Int,
  date: Timestamp,
  category: Int,
  userId: String,
  barcode: String,
  fat: Double,
  carbs: Double,
  protein: Double,
  nutritionGrade: String
}
shoppingItems Collection
javascript{
  name: String,
  quantity: Int,
  isPurchased: Bool,
  category: Int,
  calories: Int,
  userId: String
}

Real-Time Sync
Uses Firebase snapshot listeners for instant updates
Automatic conflict resolution with last-write-wins
User-specific queries using whereField("userId", isEqualTo: userId)


📸 Key Features Breakdown
Barcode Scanner Implementation
- Camera Setup: AVCaptureSession with automatic focus and exposure
- Photo Capture: AVCapturePhotoOutput for high-quality image capture
- Barcode Detection: Vision framework's VNDetectBarcodesRequest
- API Integration: Fetches product data from OpenFoodFacts
- Smart Data Parsing: Extracts nutritional info (calories, macros, nutrition grade)
- Duplicate Handling: Automatically increments quantity for existing items

Recipe Discovery System
- Ingredient Extraction: Maps pantry items to searchable ingredient names
- API Query: Searches Spoonacular with up to 100 results
- Ranking Algorithm: Recipes ranked by usedIngredientCount (API ranking=2)
- Missing Ingredient Detection: Shows what's needed to complete each recipe
- Interactive Details: Step-by-step instructions with automatic timer detection
- Shopping Integration: One-swipe addition of missing ingredients

CoreData for Liked Recipes
- NSFetchedResultsController: Automatic UI updates when data changes
- Persistent Storage: Recipes saved locally on device
- Efficient Querying: Sorted by date added (newest first)
- Memory Safe: Uses weak references and proper cleanup

Health Dashboard Calculations
BMI Formula
BMI = weight(kg) / (height(m))²
// Basal Metabolic Rate (Women's Formula)
BMR = (10 × weight) + (6.25 × height) - 161
// Maintenance Calories (Moderate Activity)
Maintenance = BMR × 1.55
// Weight Loss Goals
Mild Loss (0.25kg/week) = Maintenance × 0.84
Weight Loss (0.5kg/week) = Maintenance × 0.69

Swipe Gestures
ScreenRight SwipeLeft SwipePantryAdd to Shopping ListDelete ItemRecipesLike/Unlike RecipeAdd Missing IngredientsShopping ListN/ADelete ItemLiked RecipesN/AUnlike Recipe
Pull-to-Refresh
Pantry: Reload from Firebase
Recipes: Fetch fresh recipes
Shopping List: Sync with Firebase


💡 What I Learned
Technical Skills

Multi-API Integration: Combining Spoonacular and OpenFoodFacts APIs
Real-Time Database: Firebase Firestore snapshot listeners and data sync
CoreData Management: NSFetchedResultsController and local persistence
Camera Programming: AVFoundation session management and photo capture
Computer Vision: Vision framework for barcode recognition
Protocol-Oriented Design: Creating flexible, testable database interfaces
Memory Management: Weak references, delegate patterns, and proper cleanup

Architecture

MVVM Pattern: Separation of business logic from UI
Observer Pattern: Database change notifications via MulticastDelegate
Singleton Pattern: Shared database controllers via AppDelegate
Repository Pattern: DatabaseProtocol abstraction layer

Problem-Solving

Duplicate Item Handling: Implemented barcode-based quantity incrementation
Nutritional Data Parsing: Extracted nested JSON from OpenFoodFacts API
Category Mapping: Created smart categorization from API category strings
Timer Detection: Used regex to extract cooking times from instructions
Dark Mode Support: Implemented dynamic color system for theme switching


🚀 Setup & Installation
Prerequisites
macOS with Xcode 14.0+
iOS 15.0+ device or simulator
Firebase account
Spoonacular API key

Installation Steps
1. Clone the repository
bashgit clone https://github.com/Ojaswi-pandey-1106/PantryPal.git
cd PantryPal

2. Install dependencies (if using CocoaPods)
bashpod install
open FIT3178-Assignment.xcworkspace

3. Configure Firebase
Create a Firebase project at https://console.firebase.google.com
Add an iOS app to your Firebase project
Download GoogleService-Info.plist
Add the file to your Xcode project


4. Set up Spoonacular API
Get API key from https://spoonacular.com/food-api
Open RecipeAPIService.swift
Replace API_KEY with your key:

swiftlet API_KEY = "YOUR_API_KEY_HERE"

5. Enable Firebase Authentication
In Firebase Console, enable Email/Password authentication
Enable Firestore Database

6. Build and Run
Select your target device/simulator
Press Cmd + R to build and run


Known Limitations

- Requires active internet connection for Firebase and APIs
- Spoonacular API has rate limits (150 requests/day on free tier)
- Barcode scanner requires well-lit environment for accuracy
- Health calculations assume moderate activity level


🔮 Future Enhancements

 Notifications: Expiry date alerts
 Meal Planning: Weekly meal planner
 Recipe Sharing: Share recipes with other users
 Nutrition Analytics: Track daily calorie intake
 Inventory History: Track consumption patterns
 OCR for Receipts: Scan shopping receipts to add items
 Voice Commands: Add items via Siri
 Apple Watch App: Quick pantry checks

📄 License
This project is licensed under the MIT License - see below for details:
MIT License

Copyright (c) 2025 Ojaswi Pandey

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

👤 Author
Ojaswi Pandey

🎓 Computer Science Student @ Monash University
📧 Email: ojaswioja98@gmail.com
💼 LinkedIn: linkedin.com/in/ojaswi-pandey-a89469318
🐙 GitHub: @Ojaswi-pandey-1106


🙏 Acknowledgments

FIT3178 Teaching Team - Project guidance and support
Spoonacular API - Recipe data and nutritional information
OpenFoodFacts - Open-source product database
Firebase - Backend infrastructure
Monash University - Educational resources
