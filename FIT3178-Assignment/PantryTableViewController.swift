//
//  PantryTableViewController.swift
//  FIT3178-Assignment
//
//  Created by Ojaswi Pandey on 22/9/2025.
//
//  This screen shows all pantry items the user has added
//  User can search items, filter by category, delete items, or move to shopping list
//  Data is stored in Firebase and updates in real time
import UIKit

class PantryTableViewController: UITableViewController, UISearchResultsUpdating, DatabaseListener {
    
    // listenerType is what data we should listen for
    // Set to .pantry to listen for pantry changes
    var listenerType: ListenerType = .pantry
    
    let SECTION_PANTRY = 0
    let SECTION_INFO = 1
    
    let CELL_PANTRY = "pantryCell"
    let CELL_INFO = "pantryInfoCell"
    
    // databaseController = The manager that handles pantry data
    weak var databaseController: DatabaseProtocol?
    
    // allPantryItems = All pantry items from Firebase
    // This contains the complete unfiltered list
    var allPantryItems: [Pantry] = []
    
    // filteredPantryItems = Pantry items after filtering/searching
    // This is what gets displayed in the table
    var filteredPantryItems: [Pantry] = []
    
    // selectedCategory = The food category user is currently viewing
    // NEW: Changed to optional - nil means "Show All"
    var selectedCategory: FoodCategory? = nil
    
    // When screen first opens, set up everything
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the database controller from AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        applyStandardBackground()
        tableView.backgroundColor = .lightBackground
        tableView.separatorColor = .systemGray5
        
        setupSearchController()
        setupNavigationButtons()
    }
    
    // When screen appears, start listening for data changes
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Tell the database that we want updates
        // When pantry data changes in Firebase, we will be notified
        databaseController?.addListener(listener: self)
    }
    
    // When screen disappears, stop listening
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop listening to avoid memory leaks
        databaseController?.removeListener(listener: self)
    }
    
    // MARK: - Setup Methods
    
    // Set up all navigation bar buttons
    func setupNavigationButtons() {
        // Camera button on the left
        let cameraButton = UIBarButtonItem(
            image: UIImage(systemName: "camera.fill"),
            style: .plain,
            target: self,
            action: #selector(openBarcodeScanner)
        )
        cameraButton.tintColor = .primaryBlue
        navigationItem.leftBarButtonItem = cameraButton
        
        // Filter button
        let filterButton = UIBarButtonItem(
            image: UIImage(systemName: "line.horizontal.3.decrease.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(showFilterOptions)
        )
        filterButton.tintColor = .primaryGreen
        
        // Info button
        let infoButton = UIBarButtonItem(
            image: UIImage(systemName: "info.circle"),
            style: .plain,
            target: self,
            action: #selector(showInfoPopup)
        )
        infoButton.tintColor = .primaryBlue
        
        // Add both buttons to the right side
        navigationItem.rightBarButtonItems = [infoButton, filterButton]
        
        // Store info message for the info button
        objc_setAssociatedObject(self, &AssociatedKeys.infoMessage, """
            📦 Pantry Page
            
            Your digital pantry keeps track of all your food items!
            
            Features:
            • 📸 Scan barcodes to add items instantly
            • 🔍 Search for specific items
            • 🏷️ Filter by food category
            • 📅 Track expiry dates
            • ➡️ Swipe RIGHT to add to shopping list
            • ⬅️ Swipe LEFT to delete items
            • 👆 Tap items to view full nutritional details
            
            Tip: Keep your pantry updated to get better recipe suggestions!
            """, .OBJC_ASSOCIATION_RETAIN)
        
        objc_setAssociatedObject(self, &AssociatedKeys.infoTitle, "Pantry Help", .OBJC_ASSOCIATION_RETAIN)
    }
    
    // This runs when pantry data changes in Firebase
    func onPantryChange(change: DatabaseChange, pantryItems: [Pantry]) {
        // Save all pantry items from Firebase
        allPantryItems = pantryItems
        
        // NEW: If no category selected, show all items
        if selectedCategory == nil {
            filteredPantryItems = allPantryItems
            tableView.reloadData()
        } else {
            // Apply the current category filter
            applyFilter(for: selectedCategory!)
        }
    }
    
    // This runs when shopping list changes (we don't use it here)
    func onShoppingListChange(change: DatabaseChange, shoppingItems: [ShoppingItem]) {
        // Not needed for pantry screen
    }
    
    // This runs when user logs in or logs out
    func onAuthChange(user: User?) {
        // If user logged out
        if user == nil {
            // Clear all pantry items
            allPantryItems = []
            filteredPantryItems = []
            // Refresh the table
            tableView.reloadData()
        }
    }
    
    // Set up the search controller at the top
    func setupSearchController() {
        // Create the search controller
        let searchController = UISearchController(searchResultsController: nil)
        // Tell it to update results as user types
        searchController.searchResultsUpdater = self
        // Don't dim the background when searching
        searchController.obscuresBackgroundDuringPresentation = false
        // Set placeholder text
        searchController.searchBar.placeholder = "Search pantry items..."
        searchController.searchBar.tintColor = .primaryBlue
        // Add search bar to navigation
        navigationItem.searchController = searchController
        // Keep search active when navigating
        definesPresentationContext = true
    }
    
    // When user taps the camera button
    @objc func openBarcodeScanner() {
        // Get the storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // Create the barcode scanner screen
        let scannerVC = storyboard.instantiateViewController(withIdentifier: "BarcodeScannerViewController") as! BarcodeScannerViewController
        
        // Set presentation style
        navigationController?.modalPresentationStyle = .popover
        
        // Show the scanner
        navigationController?.present(scannerVC, animated: true)
    }
    
    // When user taps the filter button
    @objc func showFilterOptions() {
        // Create an action sheet (bottom slide-up menu)
        let alertController = UIAlertController(
            title: "Filter by Category",
            message: "Select a food category to filter your pantry items",
            preferredStyle: .actionSheet
        )
        
        // Add "Show All" button first (highlighted as default)
        let showAllAction = UIAlertAction(title: "✨ Show All", style: .default) { _ in
            // Clear category filter
            self.selectedCategory = nil
            // Show all pantry items without filtering
            self.filteredPantryItems = self.allPantryItems
            // Refresh the table
            self.tableView.reloadData()
        }
        // Mark it if it's currently selected
        if selectedCategory == nil {
            showAllAction.setValue(true, forKey: "checked")
        }
        alertController.addAction(showAllAction)
        
        // Add one button for each food category
        for category in FoodCategory.allCases {
            let emoji = categoryEmoji(category)
            let action = UIAlertAction(title: "\(emoji) \(category.displayName)", style: .default) { _ in
                // When user selects a category
                self.selectedCategory = category
                // Apply this category filter
                self.applyFilter(for: category)
            }
            
            // If this category is already selected, mark it
            if category == selectedCategory {
                action.setValue(true, forKey: "checked")
            }
            
            // Add the category button
            alertController.addAction(action)
        }
        
        // Add Cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        // For iPad, show popup from the filter button
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItems?[1]
        }
        
        // Show the popup
        present(alertController, animated: true, completion: nil)
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
    
    // Filter pantry items by a specific category
    func applyFilter(for category: FoodCategory) {
        // Keep only items that match this category
        filteredPantryItems = allPantryItems.filter { item in
            return item.category == category
        }
        // Refresh the table with filtered items
        tableView.reloadData()
    }
    
    // This runs as user types in the search bar
    func updateSearchResults(for searchController: UISearchController) {
        // Get the search text
        guard let searchText = searchController.searchBar.text?.lowercased() else {
            return
        }
        
        // If user typed something
        if searchText.count > 0 {
            // Filter items by name containing search text
            filteredPantryItems = allPantryItems.filter { (item: Pantry) -> Bool in
                return (item.name?.lowercased().contains(searchText) ?? false)
            }
        } else {
            // If search is empty, apply current filter
            if let category = selectedCategory {
                applyFilter(for: category)
            } else {
                // Show all items
                filteredPantryItems = allPantryItems
            }
        }
        // Update the table with filtered results
        tableView.reloadData()
    }
    
    // MARK: - Table View Data Source
    
    // How many sections in the table?
    override func numberOfSections(in tableView: UITableView) -> Int {
        // 2 sections: one for items, one for info
        return 2
    }
    
    // How many rows in each section?
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case SECTION_PANTRY:
            // One row for each filtered pantry item
            return filteredPantryItems.count
        case SECTION_INFO:
            // Info section always has 1 row
            return 1
        default:
            return 0
        }
    }
    
    // Set up each cell to display an item
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Check which section this cell is in
        if indexPath.section == SECTION_PANTRY {
            // This is a pantry item cell
            let pantryCell = tableView.dequeueReusableCell(withIdentifier: CELL_PANTRY, for: indexPath)
            
            // Get a default cell layout
            var content = pantryCell.defaultContentConfiguration()
            // Get the pantry item for this row
            let item = filteredPantryItems[indexPath.row]
            
            // Add emoji and show the item name as main text
            let emoji = categoryEmoji(item.category ?? .beverages)
            content.text = "\(emoji) \(item.name ?? "Unknown Item")"
            
            // Create secondary text with quantity, calories, and expiry date
            var secondaryText = ""
            // Add quantity if available
            if let quantity = item.quantity {
                secondaryText += "Qty: \(quantity)"
            }
            // Add calories if available
            if let calories = item.calories {
                if !secondaryText.isEmpty { secondaryText += " • " }
                secondaryText += "\(calories) cal"
            }
            // Add expiry date if available
            if let date = item.date {
                // Format the date nicely
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                if !secondaryText.isEmpty { secondaryText += " • " }
                secondaryText += "Exp: \(formatter.string(from: date))"
            }
            
            // Show the secondary text
            content.secondaryText = secondaryText
            pantryCell.contentConfiguration = content
            pantryCell.backgroundColor = .cardBackground
            return pantryCell
        } else {
            // This is an info cell
            let infoCell = tableView.dequeueReusableCell(withIdentifier: CELL_INFO, for: indexPath)
            
            // Get a default cell layout
            var content = infoCell.defaultContentConfiguration()
            
            // Show different messages based on whether items exist
            if filteredPantryItems.isEmpty {
                // If no items, show message
                if selectedCategory == nil {
                    content.text = "🍽️ Your pantry is empty. Add some items to get started!"
                } else {
                    content.text = "🍽️ No items in this category. Add some items to your pantry!"
                }
            } else {
                // If items exist, show count
                if let category = selectedCategory {
                    content.text = "📊 \(filteredPantryItems.count) items in \(category.displayName.lowercased())"
                } else {
                    content.text = "📊 \(filteredPantryItems.count) total items in your pantry"
                }
            }
            
            infoCell.contentConfiguration = content
            infoCell.backgroundColor = .lightBackground
            return infoCell
        }
    }
    
    // Can this cell be edited (swiped)...?
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Only pantry item cells can be edited, not info cells
        return indexPath.section == SECTION_PANTRY
    }
    
    // Leading swipe (RIGHT swipe) - Add to shopping list
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Only for pantry section
        guard indexPath.section == SECTION_PANTRY else { return nil }
        
        // Create the "Add to Shopping" action
        let addToShoppingAction = UIContextualAction(style: .normal, title: "Add to\nShopping") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            // Get the pantry item
            let item = self.filteredPantryItems[indexPath.row]
            
            // Create a shopping item from the pantry item
            let shoppingItem = ShoppingItem(
                name: item.name,
                quantity: item.quantity,
                category: item.category,
                calories: item.calories
            )
            
            // Add to database
            self.databaseController?.addShoppingItem(item: shoppingItem)
            
            // Switch to shopping list tab
            if let tabBarController = self.tabBarController {
                // Select second tab (index 1)
                tabBarController.selectedIndex = 1
            }
            
            // Complete the action
            completionHandler(true)
        }
        // Set button color to green
        addToShoppingAction.backgroundColor = .primaryGreen
        // Set button icon to shopping cart
        addToShoppingAction.image = UIImage(systemName: "cart.badge.plus")
        
        // Create the swipe configuration
        let configuration = UISwipeActionsConfiguration(actions: [addToShoppingAction])
        return configuration
    }
    
    // Trailing swipe (LEFT swipe) - Delete item
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Only for pantry section
        guard indexPath.section == SECTION_PANTRY else { return nil }
        
        // Create the delete action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            // Get the item to delete
            let itemToDelete = self.filteredPantryItems[indexPath.row]
            // Delete from database
            self.databaseController?.deletePantryItem(item: itemToDelete)
            // Complete the action
            completionHandler(true)
        }
        // Set button color to red (destructive)
        deleteAction.backgroundColor = .systemRed
        
        // Create the swipe configuration
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
    
    // When user taps on a cell
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Only for pantry items, not info cells
        if indexPath.section == SECTION_PANTRY {
            // Get the selected item
            let selectedItem = filteredPantryItems[indexPath.row]
            // Show detailed popup about this item
            showProductDetailsPopup(selectedItem)
        }
        
        // Deselect the cell after tapping
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func showProductDetailsPopup(_ item: Pantry) {
        // Get item data (use defaults if not available)
        let name = item.name ?? "Unknown Product"
        let barcode = item.barcode ?? "N/A"
        let category = item.category?.displayName ?? "N/A"
        let nutritionGrade = item.nutritionGrade ?? "N/A"
        let calories = item.calories ?? 0
        let fat = item.fat ?? 0.0
        let carbs = item.carbs ?? 0.0
        let protein = item.protein ?? 0.0
        
        // Create alert with all details
        let alert = UIAlertController(
            title: "📦 \(name)",
            message: """
            🏷️ Barcode: \(barcode)
            📂 Category: \(category)
            ⭐ Nutrition Grade: \(nutritionGrade)
            
            Per 100g:
            • 🔥 Calories: \(calories) kcal
            • 🧈 Fat: \(String(format: "%.1f", fat))g
            • 🍞 Carbs: \(String(format: "%.1f", carbs))g
            • 💪 Protein: \(String(format: "%.1f", protein))g
            """,
            preferredStyle: .alert
        )
        
        // Add OK button to close
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        // Show the popup
        present(alert, animated: true)
    }
    
    // Header text for each section
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case SECTION_PANTRY:
            return "Your Pantry Items"
        case SECTION_INFO:
            return "Summary"
        default:
            return nil
        }
    }
}

// MARK: - Associated Keys (needed for info button)
private struct AssociatedKeys {
    static var infoMessage = "infoMessage"
    static var infoTitle = "infoTitle"
}
