//
//  BarcodeScannerViewController.swift
//  FIT3178-Assignment
//
//  Created by Ojaswi Pandey on 13/10/2025.
//
//  This screen scans barcodes on food packages
//  User points camera at barcode → app reads it → app finds food info → saves to pantry
//  Like a barcode scanner at the grocery store

import UIKit
import AVFoundation
import Vision
class BarcodeScannerViewController: UIViewController {
    
    // MARK: - Outlets (these are connected on the storyboard)
    // cameraPreviewView is the area where camera shows live video
    @IBOutlet weak var cameraPreviewView: UIView!
    // captureButton is the button user taps to take a photo
    @IBOutlet weak var captureButton: UIButton!
    // loadingIndicator is the spinning circle that shows "wait, loading"
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    // captureSession is the manager that controls the camera
    var captureSession: AVCaptureSession?
    // videoPreviewLayer = Shows the camera feed on screen
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    // photoOutput = The camera's ability to take photos
    var photoOutput: AVCapturePhotoOutput?
    // databaseController = The manager that saves data
    weak var databaseController: DatabaseProtocol?
    
    // viewDidLoad - This runs once when screen first opens
    // We set up everything the screen needs here
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the database manager from AppDelegate (the app's main controller)
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        // Setup all things needed
        setupCamera()
        setupUI()
        setupCloseButton()
        
        // Make sure the buttons are visible on top of camera
        view.bringSubviewToFront(captureButton)
        view.bringSubviewToFront(loadingIndicator)
    }
    
    // viewWillAppear - This runs just before screen shows to user
    // We start the camera here so user sees video
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Start camera only if it's not already running
        if captureSession?.isRunning == false {
            captureSession?.startRunning()
        }
    }
    
    // viewWillDisappear - This runs just before screen closes
    // We stop the camera here to save battery
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }
    
    // setupCamera() - This sets up the camera so it's ready to use
    // This is like turning on and testing a camera before using it
    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            showError(message: "Unable to access camera")
            return
        }
        
        // Connect the camera to the capture session
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            showError(message: "Unable to initialize camera")
            return
        }
        // Add the camera input to the capture session
        if captureSession?.canAddInput(videoInput) == true {
            captureSession?.addInput(videoInput)
        }
        // Set camera focus and brightness to automatic
        do {
            try videoCaptureDevice.lockForConfiguration()
            // Turn on auto-focus (camera focuses automatically)
            if videoCaptureDevice.isFocusModeSupported(.autoFocus) {
                videoCaptureDevice.focusMode = .autoFocus
            }
            // Turn on auto-exposure (camera adjusts brightness automatically)
            if videoCaptureDevice.isExposureModeSupported(.autoExpose) {
                videoCaptureDevice.exposureMode = .autoExpose
            }
            videoCaptureDevice.unlockForConfiguration()
        } catch {
            print("Could not set camera focus: \(error)")
        }
        
        // Set up photo output (ability to take photos)
        photoOutput = AVCapturePhotoOutput()
        if captureSession?.canAddOutput(photoOutput!) == true {
            captureSession?.addOutput(photoOutput!)
        }
        
        // Show camera feed on screen
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        // Make video fill the entire preview area
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        // Set the size of the video display
        videoPreviewLayer?.frame = cameraPreviewView.layer.bounds
        
        // Add the video layer to the screen
        if let layer = videoPreviewLayer {
            cameraPreviewView.layer.addSublayer(layer)
        }
        // Start the camera running in background
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    // Set up the info button in the top right
    func setupInfoButton() {
        let infoButton = UIBarButtonItem(
            image: UIImage(systemName: "info.circle"),
            style: .plain,
            target: self,
            action: #selector(showInfoPopup)
        )
        navigationItem.rightBarButtonItem = infoButton
    }
        
    // When user taps the info button
    @objc override func showInfoPopup() {
        let alert = UIAlertController(
            title: "How to Use Barcode Scanner",
            message: """
                1. Point your camera at a product barcode
                2. Tap the capture button to take a photo
                3. Wait while we scan the barcode
                4. Review the product details
                5. Tap 'Add to Pantry' to save the item
                
                Tip: Make sure the barcode is clear and well-lit for best results!
                """,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Got it!", style: .default))
        present(alert, animated: true)
    }
    
    // When user taps X, this screen closes
    func setupCloseButton() {
        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeButtonTapped))
        navigationItem.leftBarButtonItem = closeButton
    }
    
    // Close the camera and go back to previous screen
    @objc func closeButtonTapped() {
        captureSession?.stopRunning()
        dismiss(animated: true)
    }
    
    // Set button shape, connect tap action, hide loading spinner
    func setupUI() {
        captureButton.layer.cornerRadius = captureButton.frame.size.width / 2
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        loadingIndicator.hidesWhenStopped = true

    }
    
    // Show loading spinner while taking photo
    @objc func capturePhoto() {
        guard let photoOutput = photoOutput else { return }
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .on
        photoOutput.capturePhoto(with: settings, delegate: self)
        loadingIndicator.startAnimating()
        captureButton.isEnabled = false
    }
    
    // Takes the photo → scans for barcode → extracts number
    func detectBarcode(in image: UIImage) {
        // Convert the image to a format Vision can use
        guard let cgImage = image.cgImage else {
            showError(message: "Could not process image")
            return
        }
        
        print(" Detecting barcode...............")
        
        // Create a request to detect barcodes in the image
        let request = VNDetectBarcodesRequest { [weak self] request, error in
            DispatchQueue.main.async {
                // Hide loading spinner
                self?.loadingIndicator.stopAnimating()
                // Re-enable button so user can tap again
                self?.captureButton.isEnabled = true
                
                // Check if there was an error
                if let error = error {
                    print("❌ Vision error: \(error.localizedDescription)")
                    self?.showError(message: "Detection error: \(error.localizedDescription)")
                    return
                }
                
                // Check if any barcodes were found
                guard let results = request.results as? [VNBarcodeObservation], !results.isEmpty else {
                    print("❌ No barcodes detected")
                    self?.showError(message: "No barcode detected. Please try again.")
                    return
                }
                
                print("✅ Found \(results.count) barcode(s)")
                // Get the first barcode found
                if let barcode = results.first?.payloadStringValue {
                    print("✅ Barcode: \(barcode)")
                    // Now download the product info using this barcode
                    self?.fetchProductInfo(barcode: barcode)
                }
            }
        }
        
        // Run the barcode detection
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            DispatchQueue.main.async {
                print("❌ Handler error: \(error.localizedDescription)")
                self.loadingIndicator.stopAnimating()
                self.captureButton.isEnabled = true
                self.showError(message: "Could not analyze image")
            }
        }
    }
    
    // Use the barcode to search OpenFoodFacts API
    func fetchProductInfo(barcode: String) {
        // Build the URL to download product info
        let urlString = "https://world.openfoodfacts.net/api/v2/product/\(barcode)?fields=product_name,image_url,nutriments,nutrition_grades,categories"
        
        print("🔗 Fetching from: \(urlString)")
        
        // Create a URL object
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            showError(message: "Invalid barcode")
            return
        }
        
        // Create a request
        var request = URLRequest(url: url)
        // Tell the server who we are (app name and version)
        request.setValue("PantryPal/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        
        // Download the data in background
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            DispatchQueue.main.async {
                // Check if there was a network error
                if let error = error {
                    print(" !!Network error!!: \(error.localizedDescription)")
                    self?.showError(message: "Network error: \(error.localizedDescription)")
                    return
                }
                
                // Check if we got data back
                guard let data = data else {
                    print("!!No data received!!")
                    self?.showError(message: "!!No data received!!")
                    return
                }
                
                // Convert the data to readable format
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("✅ JSON parsed successfully")
                        // Now read the product information
                        self?.parseProductData(json, barcode: barcode)
                    } else {
                        print("Could not parse JSON!!")
                        self?.showError(message: "Invalid API response!!")
                    }
                } catch {
                    print("JSON parsing error!!: \(error.localizedDescription)")
                    self?.showError(message: "Could not read product data!!")
                }
            }
        }
        
        task.resume()
    }
    
    // Get: name, calories, fat, carbs, protein, category, nutrition grade
    func parseProductData(_ json: [String: Any], barcode: String) {
        print("🔍 Parsing product data...")
        
        // Check if product was found (status = 1 means found)
        guard let status = json["status"] as? Int, status == 1 else {
            print("Product not found!!")
            showError(message: "Product not found in database!!")
            return
        }
        
        // Get the product information
        guard let product = json["product"] as? [String: Any] else {
            print("No product object!!")
            showError(message: "Invalid product data!!")
            return
        }
        // Extract basic info (use "Unknown" if not available)
        let productName = product["product_name"] as? String ?? "Unknown Product"
        let imageUrl = product["image_url"] as? String ?? ""
        let categories = product["categories"] as? String ?? "N/A"
        let nutritionGrade = product["nutrition_grades"] as? String ?? "N/A"
        
        // Extract nutrition info (default to 0 if not available)
        var calories = 0
        var fat = 0.0
        var carbs = 0.0
        var protein = 0.0
        
        // Look inside the nutriments data
        if let nutriments = product["nutriments"] as? [String: Any] {
            // Get calories (energy measured in kcal per 100g)
            if let energy = nutriments["energy-kcal_100g"] as? Double {
                calories = Int(energy)
            }
            // Get fat (grams per 100g)
            if let fatVal = nutriments["fat_100g"] as? Double {
                fat = fatVal
            }
            // Get carbs (grams per 100g)
            if let carbsVal = nutriments["carbohydrates_100g"] as? Double {
                carbs = carbsVal
            }
            // Get protein (grams per 100g)
            if let proteinVal = nutriments["proteins_100g"] as? Double {
                protein = proteinVal
            }
        }
        
        // Show the product info to user in a popup
        print("✅ Product found: \(productName)")
        showProductDetailsPopup(
            name: productName,
            barcode: barcode,
            calories: calories,
            fat: fat,
            carbs: carbs,
            protein: protein,
            imageUrl: imageUrl,
            category: categories,
            nutritionGrade: nutritionGrade
        )
    }
    
    // User can see details and decide to add to pantry or cancel
    func showProductDetailsPopup(name: String, barcode: String, calories: Int, fat: Double, carbs: Double, protein: Double, imageUrl: String, category: String, nutritionGrade: String) {
        let alert = UIAlertController(
            title: name,
            message: """
            Barcode: \(barcode)
            
            Category: \(category)
            Nutrition Grade: \(nutritionGrade)
            
            Per 100g:
            • Calories: \(calories) kcal
            • Fat: \(String(format: "%.1f", fat))g
            • Carbs: \(String(format: "%.1f", carbs))g
            • Protein: \(String(format: "%.1f", protein))g
            """,
            preferredStyle: .alert
        )
        
        // Create "Add to Pantry" button
        let addAction = UIAlertAction(title: "Add to Pantry", style: .default) { [weak self] _ in
            self?.addToPantry(name: name, calories: calories, barcode: barcode, apiCategory: category, fat: fat, carbs: carbs, protein: protein, nutritionGrade: nutritionGrade)
        }
        // Create "Cancel" button
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            // When user taps "Cancel", restart camera
            self?.captureSession?.startRunning()
        }
        // Add buttons to alert
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        // Show the popup
        present(alert, animated: true)
    }
    
    // mapAPICategory() = Convert API category text to app category
    // This matches the API category with our app's category list
    func mapAPICategory(toFoodCategory apiCategory: String) -> FoodCategory {
        // Convert category text to lowercase for easy checking
        let lowerCategory = apiCategory.lowercased()
        
        // Check if category contains beverage words
        if lowerCategory.contains("beverage") || lowerCategory.contains("drink") || lowerCategory.contains("coffee") || lowerCategory.contains("tea") || lowerCategory.contains("juice") {
            return .beverages
            // Check if category contains dairy words
        } else if lowerCategory.contains("dairy") || lowerCategory.contains("milk") || lowerCategory.contains("cheese") || lowerCategory.contains("yogurt") {
            return .dairy
            // Check if category contains fruit words
        } else if lowerCategory.contains("fruit") || lowerCategory.contains("apple") || lowerCategory.contains("banana") || lowerCategory.contains("orange") {
            return .fruits
            // Check if category contains vegetable words
        } else if lowerCategory.contains("vegetable") || lowerCategory.contains("carrot") || lowerCategory.contains("broccoli") || lowerCategory.contains("spinach") {
            return .vegetables
            // Check if category contains grain words
        } else if lowerCategory.contains("grain") || lowerCategory.contains("bread") || lowerCategory.contains("cereal") || lowerCategory.contains("rice") || lowerCategory.contains("pasta") {
            return .grains
            // Check if category contains protein words
        } else if lowerCategory.contains("protein") || lowerCategory.contains("meat") || lowerCategory.contains("chicken") || lowerCategory.contains("fish") || lowerCategory.contains("egg") {
            return .proteins
            // Check if category contains snack words
        } else if lowerCategory.contains("snack") || lowerCategory.contains("chips") || lowerCategory.contains("cookie") || lowerCategory.contains("candy") {
            return .snacks
            // Check if category contains condiment words
        } else if lowerCategory.contains("condiment") || lowerCategory.contains("sauce") || lowerCategory.contains("salt") || lowerCategory.contains("spice") {
            return .condiments
        }
        
        // If nothing matches, use beverages as default
        return .beverages
    }
    
    // Convert API category to app category
    // Set expiry date to 7 days from now
    func addToPantry(name: String, calories: Int, barcode: String, apiCategory: String, fat: Double, carbs: Double, protein: Double, nutritionGrade: String) {
        let quantity = 1
        let category = mapAPICategory(toFoodCategory: apiCategory)
        
        // Set expiry date to 7 days from today
        let expiryDate = Date().addingTimeInterval(86400 * 7)
        
        print("🔄 Mapping API category '\(apiCategory)' to: \(category.displayName)")
        print("💾 Saving nutritional data - Calories: \(calories), Fat: \(fat)g, Carbs: \(carbs)g, Protein: \(protein)g")
        
        // Create a Pantry object with ALL the information
        let pantryItem = Pantry(
            name: name,
            quantity: quantity,
            calories: calories,
            date: expiryDate,
            category: category,
            barcode: barcode,
            fat: fat,
            carbs: carbs,
            protein: protein,
            nutritionGrade: nutritionGrade
        )
        
        // Save to database - THIS IS THE KEY FIX
        // The problem was that addPantryItem in DatabaseProtocol doesn't accept nutritional parameters
        // So we need to save the pantryItem directly to Firebase
        
        // Get reference to Firebase
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        if let firebaseController = appDelegate?.databaseController as? FirebaseController {
            // Check for existing barcode item
            if let existingItem = firebaseController.defaultPantry.first(where: { $0.barcode == barcode }) {
                print("Item already exists! Incrementing quantity by \(quantity)")
                let newQuantity = (existingItem.quantity ?? 0) + quantity
                existingItem.quantity = newQuantity
                
                // Update in Firebase with ALL nutritional data
                if let itemId = existingItem.id, let pantryRef = firebaseController.pantryItemsRef {
                    pantryRef.document(itemId).updateData([
                        "quantity": newQuantity,
                        "calories": calories,
                        "fat": fat,
                        "carbs": carbs,
                        "protein": protein,
                        "nutritionGrade": nutritionGrade
                    ]) { error in
                        if let error = error {
                            print("Error updating item: \(error)")
                        } else {
                            print("✅ Item updated with full nutritional data")
                        }
                    }
                }
            } else {
                // New item - save with ALL nutritional data
                if let pantryRef = firebaseController.pantryItemsRef, let userId = firebaseController.getCurrentUserId() {
                    let itemData: [String: Any] = [
                        "name": name,
                        "quantity": quantity,
                        "calories": calories,
                        "date": expiryDate,
                        "category": category.rawValue,
                        "userId": userId,
                        "barcode": barcode,
                        "fat": fat,
                        "carbs": carbs,
                        "protein": protein,
                        "nutritionGrade": nutritionGrade
                    ]
                    
                    pantryRef.addDocument(data: itemData) { error in
                        if let error = error {
                            print("❌ Error saving item: \(error)")
                        } else {
                            print("✅ Item saved with full nutritional data!")
                        }
                    }
                }
            }
        }
        
        print("✅ Item added with barcode: \(barcode) in category: \(category.displayName)")
        
        // Show success message
        let successAlert = UIAlertController(
            title: "✅ Added to Pantry",
            message: "\(name) has been added to your pantry with full nutritional information",
            preferredStyle: .alert
        )
        
        // When user taps OK, close this screen
        successAlert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        
        present(successAlert, animated: true)
    }
    
    // Create a popup that shows what went wrong
    // Restart camera when user closes the error
    func showError(message: String) {
        // Create an alert with the error message
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        
        // When user taps OK, restart the camera
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.captureSession?.startRunning()
        })
        // Show the error message
        present(alert, animated: true)
    }
    
    // Make sure camera video fills the screen
    // Make sure buttons stay on top
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer?.frame = cameraPreviewView.layer.bounds
        
        view.bringSubviewToFront(captureButton)
        view.bringSubviewToFront(loadingIndicator)
    }
}

// This extension handles the camera taking a photo
// When user taps capture button, this code runs
extension BarcodeScannerViewController: AVCapturePhotoCaptureDelegate {
    // Get the photo data and start detecting the barcode
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // Check if there was an error taking the photo
        if let error = error {
            showError(message: "Camera error: \(error.localizedDescription)")
            return
        }
        
        // Convert photo to image format
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            showError(message: "Could not process photo")
            return
        }
        
        // Now scan the image to find the barcode
        detectBarcode(in: image)
    }
}
