//
//  CoreDataController.swift
//  FIT3178-Assignment
//
//  Created by Ojaswi Pandey on 8/11/2025.
//

//  This manages liked recipes stored on the phone
//  Uses CoreData (phone's local storage)
//  Only handles liked recipes - Firebase handles pantry and shopping list

import Foundation
import CoreData

class CoreDataController: NSObject, DatabaseProtocol, NSFetchedResultsControllerDelegate {
    
    // listeners = Tells other screens when liked recipes change
    var listeners = MulticastDelegate<DatabaseListener>()
    // persistentContainer is the CoreData storage system
    // This is like the phone's database for saving recipes locally
    var persistentContainer: NSPersistentContainer
    // Automatically watches for changes to recipes
    var likedRecipesFetchedResultsController: NSFetchedResultsController<LikedRecipe>?
    
    // Firebase handles pantry and shopping list instead
    var defaultPantry: [Pantry] = []
    var defaultShoppingList: [ShoppingItem] = []
    
    // When CoreDataController starts, load the CoreData storage
    override init() {
        // Create the CoreData container named "PantryPal"
        persistentContainer = NSPersistentContainer(name: "PantryPal")
        // Load the storage files from the phone
        persistentContainer.loadPersistentStores { (description, error) in
            if let error = error {
                fatalError("Failed to load Core Data Stack with error!!: \(error)")
            }
        }
        super.init()
    }
    
    // Save any changes to CoreData before app closes
    func cleanup() {
        // Check if there are unsaved changes
        if persistentContainer.viewContext.hasChanges {
            do {
                // Save the changes to phone storage
                try persistentContainer.viewContext.save()
                print("Core Data saved successfully!")
            } catch {
                fatalError("Failed to save changes to Core Data with error!!: \(error)")
            }
        }
    }
    
    // Save a recipe to the liked recipes list
    func addLikedRecipe(recipeId: Int, title: String?, image: String?) -> LikedRecipe {
        // Create a new recipe object in CoreData
        let recipe = LikedRecipe(context: persistentContainer.viewContext)
        // Set the recipe's ID number
        recipe.recipeId = Int32(recipeId)
        // Set the recipe's name
        recipe.title = title
        // Set the recipe's image link
        recipe.image = image
        // Set when the recipe was liked (right now)
        recipe.dateAdded = Date()
        
        print("Added liked recipe!!: \(title ?? "Unknown")")
        return recipe
    }
    
    // Delete a recipe from the liked recipes list
    func removeLikedRecipe(recipe: LikedRecipe) {
        persistentContainer.viewContext.delete(recipe)
        print("Removed liked recipe!!")
    }
    
    // Get all recipes the user has liked
    func fetchAllLikedRecipes() -> [LikedRecipe] {
        // If we haven't set up the fetcher yet, create it
        if likedRecipesFetchedResultsController == nil {
            // Create a request to get LikedRecipe data
            let request: NSFetchRequest<LikedRecipe> = LikedRecipe.fetchRequest()
            // Sort recipes by most recently liked (newest first)
            let dateSort = NSSortDescriptor(key: "dateAdded", ascending: false)
            request.sortDescriptors = [dateSort]
            
            // Initialize Fetched Results Controller
            // This watches the liked recipes and tells us when they change
            likedRecipesFetchedResultsController = NSFetchedResultsController<LikedRecipe>(
                fetchRequest: request,
                managedObjectContext: persistentContainer.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            // Tell the fetcher to notify us when recipes change/
            likedRecipesFetchedResultsController?.delegate = self
            
            // Run the request to get the recipes
            do {
                try likedRecipesFetchedResultsController?.performFetch()
            } catch {
                print("Fetch Request Failed!!: \(error)")
            }
        }
        
        // Return all the recipes that were found
        if let recipes = likedRecipesFetchedResultsController?.fetchedObjects {
            return recipes
        }
        return [LikedRecipe]()
    }
    
    // Tell a screen to listen for liked recipe changes
    func addListener(listener: DatabaseListener) {
        // Add this listener to our list of listeners
        listeners.addDelegate(listener)
        // If the listener wants liked recipes info, send it now
        if listener.listenerType == .likedRecipes || listener.listenerType == .all {
            listener.onLikedRecipesChange(change: .update, likedRecipes: fetchAllLikedRecipes())
        }
    }
    
    // Stop telling a screen about liked recipe changes
    func removeListener(listener: DatabaseListener) {
        listeners.removeDelegate(listener)
    }
    
    // These methods must exist because DatabaseProtocol requires them
    // But we don't use them here - use FirebaseController instead
    
    func addPantryItem(name: String, quantity: Int, calories: Int, date: Date, category: FoodCategory, barcode: String? = nil) -> Pantry {
        fatalError("Use FirebaseController for pantry items")
    }
    
    func deletePantryItem(item: Pantry) {
        fatalError("Use FirebaseController for pantry items")
    }
    
    func addShoppingItem(item: ShoppingItem) {
        fatalError("Use FirebaseController for shopping items")
    }
    
    func deleteShoppingItem(item: ShoppingItem) {
        fatalError("Use FirebaseController for shopping items")
    }
    
    func signUp(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        fatalError("Use FirebaseController for authentication")
    }
    
    func signIn(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        fatalError("Use FirebaseController for authentication")
    }
    
    func signOut() throws {
        fatalError("Use FirebaseController for authentication")
    }
    
    func getCurrentUserId() -> String? {
        fatalError("Use FirebaseController for authentication")
    }
    
    // This runs when liked recipes change (add, delete, modify)
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Check if this is for liked recipes
        if controller == likedRecipesFetchedResultsController {
            // Tell all listening screens that recipes changed
            listeners.invoke { listener in
                if listener.listenerType == .likedRecipes || listener.listenerType == .all {
                    // Send the updated recipes list
                    listener.onLikedRecipesChange(change: .update, likedRecipes: self.fetchAllLikedRecipes())
                }
            }
        }
    }
}
