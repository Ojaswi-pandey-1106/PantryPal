//
//  ShoppingListTableViewController.swift
//  FIT3178-Assignment
//
//  Created by Ojaswi Pandey on 23/9/2025.
//
//  This screen shows the shopping list
//  User can add items, delete items, or move items to pantry
//  Data is stored in Firebase and updates in real time
import UIKit

class ShoppingListTableViewController: UITableViewController, DatabaseListener {
    
    // listenerType = What data should we listen for?
    // Set to .all to listen for all data changes
    var listenerType: ListenerType = .all
    
    // CELL_SHOPPING = The ID of the table cell (set in storyboard)
    let CELL_SHOPPING = "shoppingCell"
    
    // databaseController = The manager that handles shopping list data
    weak var databaseController: DatabaseProtocol?
    
    // shoppingItems = The list of shopping items to display
    // Updates when Firebase sends new data
    var shoppingItems: [ShoppingItem] = []
    
    // When screen first opens, set up the buttons
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the database controller from AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Apply modern styling
        applyStandardBackground()
        tableView.backgroundColor = .lightBackground
        tableView.separatorColor = .systemGray5
        
        // Add the + button to add new items
        setupAddButton()
        
        // Add the camera button to scan barcodes
        setupCameraButton()
        
        // Add info button
        setupInfoButton()
    }
    
    // When screen appears, start listening for data changes
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Tell the database that we want updates
        // When data changes in Firebase, we will be notified
        databaseController?.addListener(listener: self)
    }
    
    // When screen disappears, stop listening for data changes
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop listening to avoid memory leaks
        databaseController?.removeListener(listener: self)
    }
    
    // MARK: - Setup Methods
    
    func setupInfoButton() {
        UIHelper.addInfoButton(
            to: self,
            message: """
            🛒 Shopping List Page
            
            Your digital shopping list keeps track of items you need to buy!
            
            Features:
            • ➕ Tap + button to manually add items
            • 📸 Scan barcodes to add items
            • 👆 Tap items to move them to pantry
            • ⬅️ Swipe LEFT to delete items
            
            Workflow:
            1. Add items you need to buy
            2. Go shopping and buy them
            3. Tap items to move to pantry
            4. Your pantry stays organized!
            
            Tip: Items from recipe suggestions can be added here automatically!
            """,
            title: "Shopping List Help"
        )
    }
    
    // Create the + button in the top right corner
    func setupAddButton() {
        // Create a + button
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )
        addButton.tintColor = .primaryGreen
        
        // If there's already an info button, add both
        if let infoButton = navigationItem.rightBarButtonItem {
            navigationItem.rightBarButtonItems = [infoButton, addButton]
        } else {
            navigationItem.rightBarButtonItem = addButton
        }
    }
    
    // When user taps the + button
    @objc func addButtonTapped() {
        // Show a popup to get item name and quantity
        let alert = UIAlertController(
            title: "➕ Add Shopping Item",
            message: "Enter item name and quantity",
            preferredStyle: .alert
        )
        
        // Add text field for item name
        alert.addTextField { textField in
            textField.placeholder = "Item name (e.g., Milk)"
        }
        
        // Add text field for quantity
        alert.addTextField { textField in
            textField.placeholder = "Quantity (e.g., 2)"
            // Use number keyboard only
            textField.keyboardType = .numberPad
        }
        
        // Next button - will show category picker
        let nextAction = UIAlertAction(title: "Next", style: .default) { [weak self] _ in
            // Check if item name is entered
            guard let self = self,
                  let name = alert.textFields?[0].text, !name.isEmpty else {
                self?.showError(message: "Please enter an item name")
                return
            }
            
            // Get quantity (default to 1 if empty)
            let quantityText = alert.textFields?[1].text ?? "1"
            let quantity = Int(quantityText) ?? 1
            
            // Show the category picker for this item
            self.showCategoryPicker(itemName: name, quantity: quantity)
        }
        
        // Cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        // Add buttons to alert
        alert.addAction(nextAction)
        alert.addAction(cancelAction)
        
        // Show the popup
        present(alert, animated: true)
    }
    
    // Create the camera button in the top left corner
    func setupCameraButton() {
        // Create a camera icon button
        let cameraButton = UIBarButtonItem(
            image: UIImage(systemName: "camera.fill"),
            style: .plain,
            target: self,
            action: #selector(openBarcodeScanner)
        )
        cameraButton.tintColor = .primaryBlue
        // Put it in the top left
        navigationItem.leftBarButtonItem = cameraButton
    }
    
    // When user taps the camera button
    @objc func openBarcodeScanner() {
        // Get the storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // Create the barcode scanner screen
        let scannerVC = storyboard.instantiateViewController(withIdentifier: "BarcodeScannerViewController") as! BarcodeScannerViewController
        
        // Wrap it in a navigation controller
        let navController = UINavigationController(rootViewController: scannerVC)
        
        // Make it fullscreen
        navController.modalPresentationStyle = .fullScreen
        
        // Show the scanner
        present(navController, animated: true)
    }
    
    // Show popup to let user choose category for the item
    func showCategoryPicker(itemName: String, quantity: Int) {
        // Create action sheet popup (bottom slide up menu)
        let alert = UIAlertController(
            title: "📂 Select Category",
            message: "Choose a category for \(itemName)",
            preferredStyle: .actionSheet
        )
        
        // Add one button for each food category
        for category in FoodCategory.allCases {
            let emoji = categoryEmoji(category)
            let action = UIAlertAction(title: "\(emoji) \(category.displayName)", style: .default) { [weak self] _ in
                guard let self = self else { return }
                
                // Create a new shopping item with this category
                let newItem = ShoppingItem(
                    name: itemName,
                    quantity: quantity,
                    category: category,
                    calories: nil
                )
                
                // Save to Firebase
                self.databaseController?.addShoppingItem(item: newItem)
                
                // Show success message
                let successAlert = UIAlertController(
                    title: "✅ Added!",
                    message: "\(itemName) added to shopping list",
                    preferredStyle: .alert
                )
                successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                // Show the success popup
                self.present(successAlert, animated: true)
            }
            // Add this category button
            alert.addAction(action)
        }
        
        // Add Cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancelAction)
        
        // For iPad, show popup from the + button
        if let popoverController = alert.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItems?.last
        }
        
        // Show the popup
        present(alert, animated: true)
    }
    
    // Helper to get emoji for each category
    func categoryEmoji(_ category: FoodCategory) -> String {
        switch category {
        case .beverages: return "🥤"
        case .dairy: return "🥛"
        case .fruits: return "🍎"
        case .vegetables: return "🥗"
        case .grains: return "🌾"
        case .proteins: return "🍗"
        case .snacks: return "🍿"
        case .condiments: return "🧂"
        }
    }
    
    // Show an error message popup
    func showError(message: String) {
        // Create error alert
        let alert = UIAlertController(
            title: "❌ Error",
            message: message,
            preferredStyle: .alert
        )
        // Add OK button
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        // Show the alert
        present(alert, animated: true)
    }
    
    // MARK: - Database Listener Methods
    
    // This runs when shopping list data changes in Firebase
    func onShoppingListChange(change: DatabaseChange, shoppingItems: [ShoppingItem]) {
        // Update our local list with new data from Firebase
        self.shoppingItems = shoppingItems
        // Refresh the table to show new data
        tableView.reloadData()
    }
    
    // This runs when pantry data changes (we don't use it here)
    func onPantryChange(change: DatabaseChange, pantryItems: [Pantry]) {
        // Not needed for shopping list screen
    }
    
    // This runs when user logs in or logs out
    func onAuthChange(user: User?) {
        // If user logged out
        if user == nil {
            // Clear all shopping items
            shoppingItems = []
            // Refresh the table
            tableView.reloadData()
        }
    }
    
    // MARK: - Table View Data Source
    
    // How many sections in the table?
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Just 1 section
        return 1
    }
    
    // How many rows in this section?
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Show empty state if no items
        if shoppingItems.isEmpty {
            let label = UILabel()
            label.text = "🛒 Your shopping list is empty!\n\nTap + to add items or scan barcodes"
            label.textColor = .secondaryLabel
            label.numberOfLines = 0
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 16)
            tableView.backgroundView = label
        } else {
            tableView.backgroundView = nil
        }
        
        // One row for each shopping item
        return shoppingItems.count
    }
    
    // Set up each cell to display an item
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get a cell from the table
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_SHOPPING, for: indexPath)
        
        // Get the shopping item for this row
        let item = shoppingItems[indexPath.row]
        
        // Configure the cell display
        var content = cell.defaultContentConfiguration()
        
        // Add emoji and show the item name as main text
        let emoji = categoryEmoji(item.category ?? .beverages)
        content.text = "\(emoji) \(item.name ?? "Unknown Item")"
        
        // Show quantity as secondary text
        if let quantity = item.quantity {
            content.secondaryText = "Qty: \(quantity)"
        }
        
        // Apply the configuration to the cell
        cell.contentConfiguration = content
        cell.backgroundColor = .cardBackground
        
        return cell
    }
    
    // When user taps on a shopping item
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Get the item that was tapped
            let item = shoppingItems[indexPath.row]
            
            // Show quantity picker first
            showQuantityPicker(for: item)
            
            // Deselect the row after tapping
            tableView.deselectRow(at: indexPath, animated: true)
        }

        func showQuantityPicker(for item: ShoppingItem) {
            let alert = UIAlertController(
                title: "📦 Set Quantity",
                message: "How many '\(item.name ?? "")' did you buy?",
                preferredStyle: .alert
            )
            
            // Add text field for quantity
            alert.addTextField { textField in
                textField.placeholder = "Quantity (e.g., 2)"
                textField.keyboardType = .numberPad
                // Pre-fill with existing quantity
                if let quantity = item.quantity {
                    textField.text = "\(quantity)"
                } else {
                    textField.text = "1"
                }
            }
            
            // Next button - will show category picker
            let nextAction = UIAlertAction(title: "Next", style: .default) { [weak self] _ in
                guard let self = self else { return }
                
                // Get the quantity entered
                let quantityText = alert.textFields?[0].text ?? "1"
                let quantity = Int(quantityText) ?? 1
                
                // Validate quantity
                if quantity <= 0 {
                    self.showError(message: "Please enter a valid quantity (1 or more)")
                    return
                }
                
                // Show category picker next
                self.showCategoryPickerForPantry(item: item, quantity: quantity)
            }
            
            // Cancel button
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            // Add buttons
            alert.addAction(nextAction)
            alert.addAction(cancelAction)
            
            // Show the popup
            present(alert, animated: true)
        }

        func showCategoryPickerForPantry(item: ShoppingItem, quantity: Int) {
            // Create action sheet popup
            let alert = UIAlertController(
                title: "📂 Select Category",
                message: "Choose a category for '\(item.name ?? "")' in your pantry",
                preferredStyle: .actionSheet
            )
            
            // Add one button for each food category
            for category in FoodCategory.allCases {
                let emoji = categoryEmoji(category)
                let action = UIAlertAction(title: "\(emoji) \(category.displayName)", style: .default) { [weak self] _ in
                    guard let self = self else { return }
                    
                    // Add to pantry with selected category and quantity
                    _ = self.databaseController?.addPantryItem(
                        name: item.name ?? "Unknown",
                        quantity: quantity,
                        calories: item.calories ?? 0,
                        date: Date(),
                        category: category,
                        barcode: nil
                    )
                    
                    // Remove from shopping list
                    self.databaseController?.deleteShoppingItem(item: item)
                    
                    // Show success message
                    self.showSuccessAndSwitchToPantry(itemName: item.name ?? "Item", quantity: quantity)
                }
                
                // Add this category button
                alert.addAction(action)
            }
            
            // Add Cancel button
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            alert.addAction(cancelAction)
            
            // For iPad, show popup from center
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            // Show the popup
            present(alert, animated: true)
        }
        func showSuccessAndSwitchToPantry(itemName: String, quantity: Int) {
            let alert = UIAlertController(
                title: "✅ Added to Pantry!",
                message: "\(quantity) x \(itemName) added to your pantry",
                preferredStyle: .alert
            )
            
            // View Pantry button
            let viewPantryAction = UIAlertAction(title: "View Pantry", style: .default) { [weak self] _ in
                // Switch to Pantry tab
                if let tabBarController = self?.tabBarController {
                    tabBarController.selectedIndex = 0
                }
            }
            
            // OK button (stays on shopping list)
            let okAction = UIAlertAction(title: "OK", style: .cancel)
            
            alert.addAction(viewPantryAction)
            alert.addAction(okAction)
            
            present(alert, animated: true)
        }
    
    // Can this cell be edited (swiped to delete)?
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Yes, all cells can be deleted
        return true
    }
    
    // When user swipes to delete
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // Check if this is a delete action
        if editingStyle == .delete {
            // Get the item to delete
            let item = shoppingItems[indexPath.row]
            // Delete from Firebase
            databaseController?.deleteShoppingItem(item: item)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "🛒 Shopping List (\(shoppingItems.count) items)"
    }
}
