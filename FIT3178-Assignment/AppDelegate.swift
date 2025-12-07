//
//  AppDelegate.swift
//  FIT3178-Assignment
//
//  Created by Ojaswi Pandey on 20/8/2025.
//
//  AppDelegate is the manager of the entire app
//  When the app starts, this code runs FIRST
//  It sets up everything the app needs to work

import UIKit
import FirebaseCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    // window is the screen where we show everything
    var window: UIWindow?
    // databaseController is the manager that talks to Firebase
    var databaseController: DatabaseProtocol?
    // coreDataController is the manager that saves data on the phone
    var coreDataController: CoreDataController?
    
    // This is like the "startup" or "turn on" step
    // Here we set up everything the app needs/
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        // Initialize our database controller
        databaseController = FirebaseController()
        coreDataController = CoreDataController()
        return true
    }

    // configurationForConnecting is when app creates a new window/screen
    // This method decides HOW to set up each new window

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    // didDiscardSceneSessions is when app closes a window/screen
    // If user closes a window, this code runs
    // We can clean up things we don't need anymore
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

