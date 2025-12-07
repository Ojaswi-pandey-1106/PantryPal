//
//  LikedRecipesViewController.swift
//  FIT3178-Assignment
//
//  Created by Ojaswi Pandey on 8/11/2025.
//
//  This screen shows all recipes the user has liked
//  Recipes are stored in CoreData (local phone storage)
//  User can search liked recipes or delete them by swiping

import UIKit

class LikedRecipesViewController: UITableViewController, DatabaseListener, UISearchResultsUpdating {
    
    // listenerType = What data should we listen for?
    // Set to .likedRecipes to listen for liked recipe changes
    var listenerType: ListenerType = .likedRecipes
    
    // databaseController = The manager that handles data
    // Not used in this screen but kept for protocol compliance
    weak var databaseController: DatabaseProtocol?
    
    // coreDataController = The manager that handles CoreData (local storage)
    // We use this to get and delete liked recipes
    weak var coreDataController: CoreDataController?
    
    // likedRecipes = All liked recipes from CoreData
    // This contains the complete unfiltered list
    var likedRecipes: [LikedRecipe] = []
    
    // filteredRecipes = Liked recipes after searching
    // This is what gets displayed in the table
    var filteredRecipes: [LikedRecipe] = []
    
    // CELL_RECIPE = The ID of the table cell (set in storyboard)
    let CELL_RECIPE = "likedRecipeCell"
    
    // When screen first opens, set up everything
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the screen title
        title = " Liked Recipes"
        
        // Get controllers from AppDelegate (the app's main controller)
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        // Get the CoreData controller
        coreDataController = appDelegate?.coreDataController
        
        setupTableView()
        
        setupSearchController()
        
        setupInfoButtonForLiked()
    }
    
    // When screen appears, start listening for data changes
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Tell CoreData that we want updates
        // When liked recipes change, we will be notified
        coreDataController?.addListener(listener: self)
    }
    
    // When screen disappears, stop listening
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop listening to avoid memory leaks
        coreDataController?.removeListener(listener: self)
    }
    // Set up the table view cells
    func setupTableView() {
        // Register a basic cell for displaying recipes
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CELL_RECIPE)
    }
    
    func setupInfoButtonForLiked() {
        UIHelper.addInfoButton(
            to: self,
            message: """
            ❤️ Liked Recipes Page
            
            Your personal collection of favorite recipes!
            
            Features:
            • 🔍 Search your saved recipes
            • 📅 See when you saved each recipe
            • 👆 Tap to view recipe details
            • ⬅️ Swipe LEFT to unlike/remove recipes
            
            How to save recipes:
            1. Go to Recipe Suggestions page
            2. Find recipes you like
            3. Swipe RIGHT on any recipe
            4. It appears here instantly!
            
            Storage:
            Your liked recipes are saved locally on your device and persist even after closing the app.
            
            Tip: Build your recipe collection and never lose track of your favorites!
            """,
            title: "Liked Recipes Help"
        )
    }
    
    // Set up the search controller at the top
    func setupSearchController() {
        // Create the search controller
        let searchController = UISearchController(searchResultsController: nil)
        
        // Tell it to update results as user types
        searchController.searchResultsUpdater = self
    
        searchController.obscuresBackgroundDuringPresentation = false
        
        // Set placeholder text
        searchController.searchBar.placeholder = "Search liked recipes..."
        
        // Add search bar to navigation
        navigationItem.searchController = searchController
        
        // Keep search active when navigating
        definesPresentationContext = true
    }
    // This runs when liked recipes change in CoreData
    func onLikedRecipesChange(change: DatabaseChange, likedRecipes: [LikedRecipe]) {
        // Save the new list of liked recipes
        self.likedRecipes = likedRecipes
        
        // Update search results with new data
        updateSearchResults(for: navigationItem.searchController!)
    }
    
    // This runs as user types in the search bar
    func updateSearchResults(for searchController: UISearchController) {
        // Get the search text
        guard let searchText = searchController.searchBar.text?.lowercased() else {
            // If no search text, show all recipes
            filteredRecipes = likedRecipes
            tableView.reloadData()
            return
        }
        
        // If search is empty, show all recipes
        if searchText.isEmpty {
            filteredRecipes = likedRecipes
        } else {
            // Filter recipes by title containing search text
            filteredRecipes = likedRecipes.filter { recipe in
                return recipe.title?.lowercased().contains(searchText) ?? false
            }
        }
        
        // Update the table with filtered results
        tableView.reloadData()
    }
    // How many sections in the table..
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // How many rows in this section...
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Check if there are no recipes
        if filteredRecipes.isEmpty {
            // Create an empty state label
            let label = UILabel()
            // Message telling user no recipes are liked
            label.text = "No liked recipes yet!!! \nSwipe RIGHT on recipes to add them."
            // Gray color for secondary text
            label.textColor = .secondaryLabel
            label.numberOfLines = 0
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 16)
            tableView.backgroundView = label
        } else {
            // If recipes exist, remove the empty state label
            tableView.backgroundView = nil
        }
        
        // Return number of recipes to display
        return filteredRecipes.count
    }
    
    // Set up each cell to display a recipe
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get a cell from the table
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_RECIPE, for: indexPath)
        
        // Get the recipe for this row
        let recipe = filteredRecipes[indexPath.row]
        
        // Get the cell's default layout
        var content = cell.defaultContentConfiguration()
        
        // Show the recipe title as main text
        content.text = recipe.title ?? "Unknown Recipe"
        
        // Create a date formatter to show when recipe was saved
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        // Format the save date
        let dateString = dateFormatter.string(from: recipe.dateAdded ?? Date())
        
        // Show the save date as secondary text
        content.secondaryText = "Saved: \(dateString)"
        
        // Apply the configuration to the cell
        cell.contentConfiguration = content
        return cell
    }
    
    // When user taps on a recipe
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Get the recipe that was tapped
        let recipe = filteredRecipes[indexPath.row]
        
        // Show a popup with recipe details
        let alert = UIAlertController(
            title: recipe.title ?? "Recipe",
            message: "Saved on: \(recipe.dateAdded?.formatted() ?? "Unknown")",
            preferredStyle: .alert
        )
        
        // Add OK button to close
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        // Show the popup
        present(alert, animated: true)
        
        // Deselect the row
        tableView.deselectRow(at: indexPath, animated: true)
    }
    // Trailing swipe (LEFT swipe) - Delete recipe
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Get the recipe being swiped
        let recipe = filteredRecipes[indexPath.row]
        
        // Create the delete action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            // Delete the recipe from CoreData
            self?.coreDataController?.removeLikedRecipe(recipe: recipe)
            
            // Save the changes to CoreData
            self?.coreDataController?.cleanup()
            
            // Complete the action
            completionHandler(true)
        }
        
        // Create the swipe configuration
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
    
    // Header text for the table section
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Show how many recipes are displayed
        return "Liked Recipes (\(filteredRecipes.count))"
    }
}
