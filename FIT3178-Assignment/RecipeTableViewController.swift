//
//  RecipeTableViewController.swift
//  FIT3178-Assignment
//
//  Created by Ojaswi Pandey on 14/10/2025.
//
//  This screen shows recipes based on items in the user's pantry
//  User can search recipes, like them, or add missing ingredients to shopping list
//  Recipes are fetched from an API based on pantry items

import UIKit

class RecipeTableViewController: UITableViewController, UISearchResultsUpdating, DatabaseListener {
    
    // listenerType = What data should we listen for?
    // Set to .pantry because we need to know when pantry changes
    var listenerType: ListenerType = .pantry
    
    // databaseController = The manager that handles data
    weak var databaseController: DatabaseProtocol?
    
    // allRecipes = All recipes fetched from the API
    var allRecipes: [Recipe] = []
    
    // filteredRecipes = Recipes after search filtering
    // This is what gets displayed in the table
    var filteredRecipes: [Recipe] = []
    
    // likedRecipeIds = Set of recipe IDs that user has liked
    // Used for quick lookup when checking if a recipe is liked
    var likedRecipeIds: Set<Int> = []
    
    // pantryItems = All items currently in user's pantry
    // Used to search for recipes with these ingredients
    var pantryItems: [Pantry] = []
    
    // apiService = The service that fetches recipes from the API
    let apiService = RecipeAPIService()
    
    // selectedCuisine = The cuisine type user selected for filtering
    // Can be nil if no cuisine filter applied
    var selectedCuisine: String? = nil
    
    // loadingIndicator = The spinning circle shown while loading recipes
    let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // emptyStateLabel = Message shown when there are no recipes or no pantry items
    let emptyStateLabel = UILabel()
    
    // When screen first opens, set up everything
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the database controller from AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Set up the table view
        setupTableView()
        // Set up the search bar
        setupSearchController()
        // Set up the loading spinner
        setupLoadingIndicator()
        // Set up the empty state message
        setupEmptyState()
        // Set up the pull to refresh
        setupRefreshControl()
        // Set up the camera button
        setupCameraButton()
        
        setupInfoButtonForRecipes()
    }
    
    // When screen appears, start listening for pantry changes
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Tell database to notify us of changes
        databaseController?.addListener(listener: self)
    }
    
    // When screen disappears, stop listening
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Stop listening to avoid memory leaks
        databaseController?.removeListener(listener: self)
    }
    
    func setupInfoButtonForRecipes() {
        UIHelper.addInfoButton(
            to: self,
            message: """
            🍳 Recipe Suggestions Page
            
            Discover recipes based on YOUR pantry items!
            
            Features:
            • 🔍 Search recipes by name
            • 🍽️ Recipes ranked by ingredient match
            • ❤️ Swipe RIGHT to like/save recipes
            • 🛒 Swipe LEFT to add missing ingredients
            • 👆 Tap for recipe details
            • ↓ Pull down to refresh recipes
            
            Color Coding:
            • 🟢 Green badge = All ingredients available
            • 🟠 Orange badge = Some ingredients missing
            • Light green background = Recipe is liked
            
            How it works:
            The app searches for recipes using ingredients from your pantry. Recipes with the most matches appear first!
            
            Tip: Keep your pantry updated for better recipe suggestions!
            """,
            title: "Recipe Help"
        )
    }
    
    // Set up the table view appearance and cells
    func setupTableView() {
        // Register the custom cell class
        tableView.register(RecipeTableViewCell.self, forCellReuseIdentifier: "RecipeCell")
        // Set height of each cell
        tableView.rowHeight = 124
        // Show divider lines between cells
        tableView.separatorStyle = .singleLine
    }
    
    // Set up the search controller at the top
    func setupSearchController() {
        // Create the search controller
        let searchController = UISearchController(searchResultsController: nil)
        // Tell it to update results as user types
        searchController.searchResultsUpdater = self
        // Don't dim the background when searching
        searchController.obscuresBackgroundDuringPresentation = false
        // Set placeholder text in search bar
        searchController.searchBar.placeholder = "Search recipes by name..."
        // Add search bar to navigation
        navigationItem.searchController = searchController
        // Keep search active when navigating
        definesPresentationContext = true
    }
    
    // Set up the camera button in the top left
    func setupCameraButton() {
        // Create a camera icon button
        let cameraButton = UIBarButtonItem(
            image: UIImage(systemName: "camera.fill"),
            style: .plain,
            target: self,
            action: #selector(openBarcodeScanner)
        )
        // Put it in the top left
        navigationItem.leftBarButtonItem = cameraButton
    }
    
    // When user taps the camera button
    @objc func openBarcodeScanner() {
        // Create the barcode scanner screen
        let scannerVC = BarcodeScannerViewController()
        // Make it fullscreen
        scannerVC.modalPresentationStyle = .fullScreen
        // Show the scanner
        present(scannerVC, animated: true)
    }
    
    // Set up the loading spinner that shows while fetching recipes
    func setupLoadingIndicator() {
        // Center it on the screen
        loadingIndicator.center = view.center
        // Hide when it's not spinning
        loadingIndicator.hidesWhenStopped = true
        // Add to the view
        view.addSubview(loadingIndicator)
    }
    
    // Set up the empty state message
    func setupEmptyState() {
        // Set the message
        emptyStateLabel.text = "Add items to your pantry to get recipe suggestions! "
        // Center the text
        emptyStateLabel.textAlignment = .center
        // Use gray color for the text
        emptyStateLabel.textColor = .secondaryLabel
        // Allow multiple lines
        emptyStateLabel.numberOfLines = 0
        // Set font size
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16)
        // Hide it initially
        emptyStateLabel.isHidden = true
        
        // Add to the view
        view.addSubview(emptyStateLabel)
        
        // Use Auto Layout to center it
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    // Set up the pull-to-refresh control
    func setupRefreshControl() {
        // Create the refresh control
        let refresh = UIRefreshControl()
        // Run this code when user pulls down
        refresh.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        // Add it to the table
        refreshControl = refresh
    }
    
    // When user pulls down to refresh
    @objc func handleRefresh() {
        // Fetch recipes again
        fetchRecipes()
    }
    
    // This runs as user types in the search bar
    func updateSearchResults(for searchController: UISearchController) {
        // Get the search text
        guard let searchText = searchController.searchBar.text?.lowercased() else {
            // If no search text, show all recipes
            filteredRecipes = allRecipes
            tableView.reloadData()
            return
        }
        
        // If search is empty, show all recipes
        if searchText.isEmpty {
            filteredRecipes = allRecipes
        } else {
            // Filter recipes by name containing search text
            filteredRecipes = allRecipes.filter { recipe in
                return recipe.title?.lowercased().contains(searchText) ?? false
            }
        }
        
        // Update the table with filtered results
        tableView.reloadData()
    }
    
    // This runs when pantry items change
    func onPantryChange(change: DatabaseChange, pantryItems: [Pantry]) {
        // Save the new pantry items
        self.pantryItems = pantryItems
        
        // If pantry has items, fetch recipes for them
        if !pantryItems.isEmpty {
            fetchRecipes()
        } else {
            // Pantry is empty, clear recipes
            allRecipes = []
            filteredRecipes = []
            // Show the empty state message
            emptyStateLabel.isHidden = false
            // Update the table
            tableView.reloadData()
        }
    }
    
    // This runs when shopping list changes (we don't use it)
    func onShoppingListChange(change: DatabaseChange, shoppingItems: [ShoppingItem]) {}
    
    // This runs when user logs in or logs out
    func onAuthChange(user: User?) {
        // If user logged out
        if user == nil {
            // Clear all data
            allRecipes = []
            filteredRecipes = []
            pantryItems = []
            likedRecipeIds.removeAll()
            // Update the table
            tableView.reloadData()
        }
    }
    
    // Fetch recipes from the API based on pantry items
    func fetchRecipes() {
        // Check if pantry is empty
        guard !pantryItems.isEmpty else {
            // Show the empty state message
            emptyStateLabel.isHidden = false
            return
        }
        
        // Hide empty state message
        emptyStateLabel.isHidden = true
        // Show loading spinner
        loadingIndicator.startAnimating()
        // Hide the table while loading
        tableView.isHidden = true
        
        // Get the names of all pantry items
        let ingredients = pantryItems.compactMap { $0.name }
        
        print("🔍 Searching recipes with ingredients: \(ingredients)")
        
        // Call the API service to get recipes
        apiService.fetchRecipesByIngredients(ingredients: ingredients) { [weak self] recipes, error in
            // Update UI on main thread
            DispatchQueue.main.async {
                // Stop the loading spinner
                self?.loadingIndicator.stopAnimating()
                // Stop the refresh animation
                self?.refreshControl?.endRefreshing()
                // Show the table again
                self?.tableView.isHidden = false
                
                // Check if there was an error
                if let error = error {
                    print("❌ Error fetching recipes: \(error.localizedDescription)")
                    // Show error message
                    self?.showError(message: "Could not load recipes. Please check your API key and try again.")
                    return
                }
                
                // If recipes were fetched
                if let recipes = recipes {
                    print("✅ Loaded \(recipes.count) recipes")
                    // Save all recipes
                    self?.allRecipes = recipes
                    // Show all recipes initially
                    self?.filteredRecipes = recipes
                    // Update the table
                    self?.tableView.reloadData()
                    
                    // If no recipes found
                    if recipes.isEmpty {
                        // Update the message
                        self?.emptyStateLabel.text = "No recipes found for your ingredients. Try adding more items to your pantry! "
                        // Show the message
                        self?.emptyStateLabel.isHidden = false
                    }
                }
            }
        }
    }
    
    // Show an error message popup
    func showError(message: String) {
        // Create error alert
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        // Add OK button
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        // Show the alert
        present(alert, animated: true)
    }
    
    // How many sections in the table?
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Just 1 section
        return 1
    }
    
    // How many rows in this section?
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // One row for each filtered recipe
        return filteredRecipes.count
    }
    
    // Set up each cell to display a recipe
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get a cell from the table
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeCell", for: indexPath) as! RecipeTableViewCell
        // Get the recipe for this row
        let recipe = filteredRecipes[indexPath.row]
        
        // Display the recipe in the cell
        cell.configure(with: recipe)
        
        // Get the CoreData controller to check liked recipes
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let coreDataController = appDelegate?.coreDataController
        // Get all liked recipes
        let allLiked = coreDataController?.fetchAllLikedRecipes() ?? []
        
        // Check if this recipe is liked
        if let recipeId = recipe.id, allLiked.contains(where: { Int($0.recipeId) == recipeId }) {
            // If liked, show green background
            cell.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        } else {
            // If not liked, clear background
            cell.backgroundColor = .clear
        }
        return cell
    }
    
    // Leading swipe (RIGHT swipe) - Like/Unlike
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Get the recipe for this row
        let recipe = filteredRecipes[indexPath.row]
        
        // Check if recipe has an ID
        guard let recipeId = recipe.id else { return nil }
        
        // Get the CoreData controller
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let coreDataController = appDelegate?.coreDataController
        
        // Get all liked recipes
        let allLiked = coreDataController?.fetchAllLikedRecipes() ?? []
        // Check if this recipe is liked
        let isLiked = allLiked.contains { Int($0.recipeId) == recipeId }
        
        // Create the like/unlike action
        let likeAction = UIContextualAction(style: .normal, title: isLiked ? "Unlike" : "Like") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            
            // If already liked, unlike it
            if isLiked {
                // Find the liked recipe
                if let recipeToRemove = allLiked.first(where: { Int($0.recipeId) == recipeId }) {
                    // Remove from CoreData
                    coreDataController?.removeLikedRecipe(recipe: recipeToRemove)
                }
                // Remove from the liked set
                self.likedRecipeIds.remove(recipeId)
                // Show message
                self.showTemporaryMessage("Recipe unliked")
            } else {
                // If not liked, like it
                // Add to CoreData
                let _ = coreDataController?.addLikedRecipe(
                    recipeId: recipeId,
                    title: recipe.title,
                    image: recipe.image
                )
                // Save to CoreData
                coreDataController?.cleanup()
                // Add to the liked set
                self.likedRecipeIds.insert(recipeId)
                // Show badge message
                self.showLikedBadge(for: recipe)
            }
            
            // Refresh this row to update the color
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
            // Complete the action
            completionHandler(true)
        }
        
        // Set button color based on liked status
        likeAction.backgroundColor = isLiked ? .systemGray : .systemGreen
        // Set button icon
        likeAction.image = UIImage(systemName: isLiked ? "heart.slash.fill" : "heart.fill")
        
        // Create the swipe configuration
        let configuration = UISwipeActionsConfiguration(actions: [likeAction])
        return configuration
    }
    
    // Trailing swipe (LEFT swipe) - Add missing ingredients to shopping list
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Get the recipe for this row
        let recipe = filteredRecipes[indexPath.row]
        
        // Create the add to shopping action
        let addToShoppingAction = UIContextualAction(style: .normal, title: "Add Missing\nIngredients") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            
            // Get the missing ingredients for this recipe
            if let missingIngredients = recipe.missedIngredients, !missingIngredients.isEmpty {
                // Add each missing ingredient to shopping list
                for ingredient in missingIngredients {
                    // Create a shopping item
                    let shoppingItem = ShoppingItem(
                        name: ingredient.name,
                        quantity: Int(ingredient.amount ?? 1),
                        category: nil,
                        calories: nil
                    )
                    // Add to database
                    self.databaseController?.addShoppingItem(item: shoppingItem)
                }
                
                // Show success message
                let message = "\(missingIngredients.count) ingredient\(missingIngredients.count == 1 ? "" : "s") added to shopping list"
                self.showTemporaryMessage(message)
                
                // Switch to shopping list tab
                if let tabBarController = self.tabBarController {
                    // Select second tab (index 1)
                    tabBarController.selectedIndex = 1
                }
            } else {
                // No missing ingredients
                self.showTemporaryMessage("No missing ingredients")
            }
            
            // Complete the action
            completionHandler(true)
        }
        
        // Set button color to blue
        addToShoppingAction.backgroundColor = .systemBlue
        // Set button icon to shopping cart
        addToShoppingAction.image = UIImage(systemName: "cart.badge.plus")
        
        // Create the swipe configuration
        let configuration = UISwipeActionsConfiguration(actions: [addToShoppingAction])
        return configuration
    }
    // Show message when recipe is liked
    func showLikedBadge(for recipe: Recipe) {
        // Create alert
        let alert = UIAlertController(
            title: " Liked Recipe!",
            message: "\(recipe.title ?? "Recipe") has been added to your favorites",
            preferredStyle: .alert
        )
        
        // Add OK button
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        // Show the alert
        present(alert, animated: true)
    }
    
    // Show a message that disappears automatically
    func showTemporaryMessage(_ message: String) {
        // Create alert
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        // Show the alert
        present(alert, animated: true)
        
        // Dismiss after 1.5 seconds automatically
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
    // When user taps on a recipe
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Get the recipe that was tapped
        let recipe = filteredRecipes[indexPath.row]
        // Create the detail view controller
        let detailVC = RecipeDetailViewController()
        detailVC.recipe = recipe
        detailVC.recipeId = recipe.id
        
        // Navigate to detail page
        navigationController?.pushViewController(detailVC, animated: true)
        
        // Deselect the row
        tableView.deselectRow(at: indexPath, animated: true)
    }
    // Header text for the table section
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // If no recipes, don't show header
        if filteredRecipes.isEmpty {
            return nil
        }
        
        // Get the number of liked recipes
        let likedCount = likedRecipeIds.count
        
        // Show different text based on number of liked recipes
        if likedCount > 0 {
            return "Recipes (\(filteredRecipes.count) found, \(likedCount) liked)"
        } else {
            return "Recipes (\(filteredRecipes.count) found)"
        }
    }
}
