//  FIT3178-Assignment
//
//  Created by Ojaswi Pandey on 8/11/2025.
//

import Foundation

// DatabaseChange = What type of change happened to the data
// add = A new item was added
// remove = An item was deleted
// update = An item was changed
enum DatabaseChange {
    case add
    case remove
    case update
}

// ListenerType = What data does this screen want to listen to?
// pantry = Listen for pantry changes only
// shopping = Listen for shopping list changes only
// auth = Listen for login/logout changes only
// likedRecipes = Listen for liked recipes changes only
// all = Listen for ALL changes
enum ListenerType {
    case pantry
    case shopping
    case auth
    case likedRecipes
    case all
}

// DatabaseListener = A blueprint for screens that want to hear about data changes
// Any screen that needs fresh data from the database must follow this blueprint
protocol DatabaseListener: AnyObject {
    // listenerType = What data does this screen want?
    var listenerType: ListenerType { get set }
    // This gets called when pantry items change
    func onPantryChange(change: DatabaseChange, pantryItems: [Pantry])
    // This gets called when shopping list items change
    func onShoppingListChange(change: DatabaseChange, shoppingItems: [ShoppingItem])
    // This gets called when user logs in or logs out
    func onAuthChange(user: User?)
    // This gets called when liked recipes change
    func onLikedRecipesChange(change: DatabaseChange, likedRecipes: [LikedRecipe])
}

// Provide default implementations so screens don't HAVE to use all methods
extension DatabaseListener {
    func onPantryChange(change: DatabaseChange, pantryItems: [Pantry]) {}
    func onShoppingListChange(change: DatabaseChange, shoppingItems: [ShoppingItem]) {}
    func onAuthChange(user: User?) {}
    func onLikedRecipesChange(change: DatabaseChange, likedRecipes: [LikedRecipe]) {}
}

// Any database manager must follow this blueprint
protocol DatabaseProtocol: AnyObject {
    // defaultPantry = All pantry items stored in memory (for fast access)
    var defaultPantry: [Pantry] { get }
    var defaultShoppingList: [ShoppingItem] { get }
    
    // Add a screen to listen for data changes
    func addListener(listener: DatabaseListener)
    // Stop a screen from listening for data changes
    func removeListener(listener: DatabaseListener)
    
    // Add a new food item to the pantry
    func addPantryItem(name: String, quantity: Int, calories: Int, date: Date, category: FoodCategory, barcode: String?) -> Pantry
    func deletePantryItem(item: Pantry)
    
    // Add a new item to the shopping list
    func addShoppingItem(item: ShoppingItem)
    func deleteShoppingItem(item: ShoppingItem)
    
    // Authentication
    func signUp(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void)
    func signIn(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void)
    func signOut() throws
    func getCurrentUserId() -> String?
    
    func cleanup()
    func addLikedRecipe(recipeId: Int, title: String?, image: String?) -> LikedRecipe
    func removeLikedRecipe(recipe: LikedRecipe)
    func fetchAllLikedRecipes() -> [LikedRecipe]
}
