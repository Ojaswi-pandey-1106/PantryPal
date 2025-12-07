//  FIT3178-Assignment
//
//  Created by Ojaswi Pandey on 8/11/2025.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

// Firebase database manager that saves pantry and shopping list online
class FirebaseController: NSObject, DatabaseProtocol {
    
    
    // listeners = Tells other screens when data changes
    var listeners = MulticastDelegate<DatabaseListener>()
    // defaultPantry = All pantry items stored in memory
    var defaultPantry: [Pantry]
    // defaultShoppingList = All shopping items stored in memory
    var defaultShoppingList: [ShoppingItem]
    
    // authController = Handles login/signup with Firebase
    var authController: Auth
    // database = The online database where data gets saved
    var database: Firestore
    // pantryItemsRef = Reference to pantry collection in database
    var pantryItemsRef: CollectionReference?
    // shoppingItemsRef = Reference to shopping collection in database
    var shoppingItemsRef: CollectionReference?
    
    // currentUser = The user currently logged in
    var currentUser: FirebaseAuth.User?
    
    // Firestore listeners to remove when user logs out
    // pantryListener = Watches for pantry changes from database
    private var pantryListener: ListenerRegistration?
    // shoppingListener = Watches for shopping list changes from database
    private var shoppingListener: ListenerRegistration?
    
    
    // When the app starts, set up Firebase
    override init() {
        // Get the Firebase authentication service
        authController = Auth.auth()
        // Get the Firebase database service
        database = Firestore.firestore()
        
        // Initialize empty lists
        defaultPantry = [Pantry]()
        defaultShoppingList = [ShoppingItem]()
        
        super.init()
        
        // Check if user is already logged in (from previous session)
        if let user = authController.currentUser {
            print("!!User already logged in!!: \(user.email ?? "No email")")
            // Save the user
            currentUser = user
            // Start listening for pantry changes
            setupPantryListener()
            // Start listening for shopping list changes
            setupShoppingListener()
        } else {
            print("!!No user logged in - waiting for sign in/sign up!!")
            // Don't sign in anonymously - wait for user to log in or sign up
        }
    }
    
    
    // Save data before app closes
    func cleanup() {
        // Core Data cleanup is handled by CoreDataController
    }
    
    // These are stubs - CoreDataController handles liked recipes
    func addLikedRecipe(recipeId: Int, title: String?, image: String?) -> LikedRecipe {
        return LikedRecipe()
    }
    
    // Stub - handled by CoreDataController
    func removeLikedRecipe(recipe: LikedRecipe) {
        // Stub - handled by CoreDataController
    }
    
    // Stub - handled by CoreDataController
    func fetchAllLikedRecipes() -> [LikedRecipe] {
        return []
    }
    
    
    // Add a screen to listen for data changes
    func addListener(listener: DatabaseListener) {
        // Add this listener to the list
        listeners.addDelegate(listener)
        
        // If listener wants pantry data, send it now
        if listener.listenerType == .pantry || listener.listenerType == .all {
            listener.onPantryChange(change: .update, pantryItems: defaultPantry)
        }
        
        // If listener wants shopping list data, send it now
        if listener.listenerType == .shopping || listener.listenerType == .all {
            listener.onShoppingListChange(change: .update, shoppingItems: defaultShoppingList)
        }
        
        // If listener wants auth data, send it now
        if listener.listenerType == .auth || listener.listenerType == .all {
            listener.onAuthChange(user: currentUser != nil ? User(id: currentUser?.uid, email: currentUser?.email) : nil)
        }
    }
    
    // Stop a screen from listening for data changes
    func removeListener(listener: DatabaseListener) {
        // Remove this listener
        listeners.removeDelegate(listener)
    }
    
    
    // Add a food item to pantry
    // If same barcode exists, increment quantity instead
    func addPantryItem(name: String, quantity: Int, calories: Int, date: Date, category: FoodCategory, barcode: String? = nil) -> Pantry {
        // Check for duplicate barcode and increment quantity
        if let barcode = barcode, !barcode.isEmpty {
            // Look for existing item with this barcode
            if let existingItem = findItemByBarcode(barcode) {
                print("Item already exists! Incrementing quantity by \(quantity)")
                
                // Calculate new quantity
                let newQuantity = (existingItem.quantity ?? 0) + quantity
                // Update in memory
                existingItem.quantity = newQuantity
                
                // Update in Firebase
                if let itemId = existingItem.id {
                    pantryItemsRef?.document(itemId).updateData([
                        "quantity": newQuantity
                    ]) { error in
                        if let error = error {
                            print("Error updating quantity!!: \(error)")
                        } else {
                            print("Quantity updated to \(newQuantity)")
                        }
                    }
                }
                
                // Return the existing item
                return existingItem
            }
        }
        
        // Create a new pantry item
        let pantryItem = Pantry()
        // Set the item's data
        pantryItem.name = name
        pantryItem.quantity = quantity
        pantryItem.calories = calories
        pantryItem.date = date
        pantryItem.category = category
        pantryItem.userId = currentUser?.uid
        pantryItem.barcode = barcode
        
        // Create data dictionary to send to Firebase
        let itemData: [String: Any] = [
            "name": name,
            "quantity": quantity,
            "calories": calories,
            "date": date,
            "category": category.rawValue,
            "userId": currentUser?.uid ?? "",
            "barcode": barcode ?? ""
        ]
        
        // Save to Firebase and get the document ID
        if let itemRef = pantryItemsRef?.addDocument(data: itemData) {
            // Save the ID in the pantry item
            pantryItem.id = itemRef.documentID
            print("New item added to pantry with barcode: \(barcode ?? "N/A")")
        }
        
        // Return the new item
        return pantryItem
    }
    
    // Search for an item by its barcode
    func findItemByBarcode(_ barcode: String) -> Pantry? {
        // Loop through all pantry items
        for item in defaultPantry {
            // Check if this item's barcode matches
            if let itemBarcode = item.barcode, itemBarcode == barcode {
                print("Found existing item with barcode: \(barcode)")
                // Return this item
                return item
            }
        }
        // Item not found
        return nil
    }
    
    // Delete a pantry item
    func deletePantryItem(item: Pantry) {
        // Get the item's ID
        if let itemID = item.id {
            // Delete from Firebase
            pantryItemsRef?.document(itemID).delete()
        }
    }
    
    // Add an item to the shopping list
    func addShoppingItem(item: ShoppingItem) {
        // Create data dictionary
        let itemData: [String: Any] = [
            "name": item.name ?? "",
            "quantity": item.quantity ?? 1,
            "isPurchased": item.isPurchased,
            "category": item.category?.rawValue ?? 0,
            "calories": item.calories ?? 0,
            "userId": currentUser?.uid ?? ""
        ]
        
        // Save to Firebase
        shoppingItemsRef?.addDocument(data: itemData)
    }
    
    // Delete a shopping item
    func deleteShoppingItem(item: ShoppingItem) {
        // Get the item's ID
        if let itemID = item.id {
            // Delete from Firebase
            shoppingItemsRef?.document(itemID).delete()
        }
    }
    
    // Get the ID of the current logged in user
    func getCurrentUserId() -> String? {
        return currentUser?.uid
    }
    
    // Find a pantry item by its ID
    func getPantryItemById(_ id: String) -> Pantry? {
        // Loop through all pantry items
        for item in defaultPantry {
            // Check if this item's ID matches
            if item.id == id {
                return item
            }
        }
        return nil
    }
    
    // Start listening for pantry changes from database
    func setupPantryListener() {
        // Check if user is logged in
        guard let userId = currentUser?.uid else {
            print("No user logged in - can't set up pantry listener")
            return
        }
        
        // Connect to pantry collection in database
        pantryItemsRef = database.collection("pantryItems")
        
        // Only get items for THIS user
        // Watch for changes and run this code when they happen
        pantryListener = pantryItemsRef?
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener() { (querySnapshot, error) in
                // Check if we got data back
                guard let querySnapshot = querySnapshot else {
                    print("Failed to fetch documents with error: \(String(describing: error))")
                    return
                }
                
                // Read the pantry data
                self.parsePantrySnapshot(snapshot: querySnapshot)
            }
    }
    
    // Start listening for shopping list changes from database
    func setupShoppingListener() {
        // Check if user is logged in
        guard let userId = currentUser?.uid else {
            print("No user logged in - can't set up shopping listener")
            return
        }
        
        // Connect to shopping collection in database
        shoppingItemsRef = database.collection("shoppingItems")
        
        // Only get items for THIS user
        // Watch for changes and run this code when they happen
        shoppingListener = shoppingItemsRef?
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener() { (querySnapshot, error) in
                // Check if we got data back
                guard let querySnapshot = querySnapshot else {
                    print("Failed to fetch shopping documents: \(String(describing: error))")
                    return
                }
                
                // Read the shopping data
                self.parseShoppingSnapshot(snapshot: querySnapshot)
            }
    }
    
    // Read pantry data from Firebase and update our lists
    func parsePantrySnapshot(snapshot: QuerySnapshot) {
        snapshot.documentChanges.forEach { (change) in
            let data = change.document.data()
            
            let pantryItem = Pantry()
            pantryItem.id = change.document.documentID
            pantryItem.name = data["name"] as? String
            pantryItem.quantity = data["quantity"] as? Int
            pantryItem.calories = data["calories"] as? Int
            pantryItem.date = (data["date"] as? Timestamp)?.dateValue()
            
            if let categoryRaw = data["category"] as? Int {
                pantryItem.category = FoodCategory(rawValue: categoryRaw)
            }
            
            pantryItem.userId = data["userId"] as? String
            pantryItem.barcode = data["barcode"] as? String
            
            // NEW: Read nutritional data fields
            pantryItem.fat = data["fat"] as? Double
            pantryItem.carbs = data["carbs"] as? Double
            pantryItem.protein = data["protein"] as? Double
            pantryItem.nutritionGrade = data["nutritionGrade"] as? String
            
            if change.type == .added {
                defaultPantry.insert(pantryItem, at: Int(change.newIndex))
            }
            else if change.type == .modified {
                defaultPantry.remove(at: Int(change.oldIndex))
                defaultPantry.insert(pantryItem, at: Int(change.newIndex))
            }
            else if change.type == .removed {
                defaultPantry.remove(at: Int(change.oldIndex))
            }
        }
        
        listeners.invoke { (listener) in
            if listener.listenerType == ListenerType.pantry || listener.listenerType == ListenerType.all {
                listener.onPantryChange(change: .update, pantryItems: self.defaultPantry)
            }
        }
    }
    
    // Read shopping data from Firebase and update our lists
    func parseShoppingSnapshot(snapshot: QuerySnapshot) {
        // Go through each change (add, modify, delete)
        snapshot.documentChanges.forEach { (change) in
            // Get the data
            let data = change.document.data()
            
            // Create a shopping item object
            let shoppingItem = ShoppingItem()
            // Set the item's ID
            shoppingItem.id = change.document.documentID
            // Read all data from Firebase
            shoppingItem.name = data["name"] as? String
            shoppingItem.quantity = data["quantity"] as? Int
            // Default to false if not found
            shoppingItem.isPurchased = data["isPurchased"] as? Bool ?? false
            shoppingItem.calories = data["calories"] as? Int
            // Convert category from number back to enum
            if let categoryRaw = data["category"] as? Int {
                shoppingItem.category = FoodCategory(rawValue: categoryRaw)
            }
            shoppingItem.userId = data["userId"] as? String
            
            // Handle the type of change
            if change.type == .added {
                // A new item was added, insert it
                defaultShoppingList.insert(shoppingItem, at: Int(change.newIndex))
            }
            else if change.type == .modified {
                // An item was modified, remove old and insert new
                defaultShoppingList.remove(at: Int(change.oldIndex))
                defaultShoppingList.insert(shoppingItem, at: Int(change.newIndex))
            }
            else if change.type == .removed {
                // An item was deleted, remove it
                defaultShoppingList.remove(at: Int(change.oldIndex))
            }
        }
        
        // Tell all listening screens that shopping list changed
        listeners.invoke { (listener) in
            if listener.listenerType == ListenerType.shopping || listener.listenerType == ListenerType.all {
                // Send updated shopping list
                listener.onShoppingListChange(change: .update, shoppingItems: self.defaultShoppingList)
            }
        }
    }
    
    // Create a new account
    func signUp(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Ask Firebase to create a new user
        authController.createUser(withEmail: email, password: password) { authResult, error in
            // Check for errors
            if let error = error {
                // Send error back
                completion(.failure(error))
                return
            }
            
            // Account created successfully
            if let user = authResult?.user {
                print("Account created: \(user.email ?? "")")
                // Save the current user
                self.currentUser = user
                // Start listening for pantry changes
                self.setupPantryListener()
                // Start listening for shopping changes
                self.setupShoppingListener()
                
                // Tell all screens that user logged in
                self.listeners.invoke { listener in
                    if listener.listenerType == .auth || listener.listenerType == .all {
                        listener.onAuthChange(user: User(id: user.uid, email: user.email))
                    }
                }
                
                // Send success with user ID
                completion(.success(user.uid))
            }
        }
    }
    
    // Log in to an account
    func signIn(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Ask Firebase to sign in the user
        authController.signIn(withEmail: email, password: password) { authResult, error in
            // Check for errors
            if let error = error {
                // Send error back
                completion(.failure(error))
                return
            }
            
            // Sign in successful
            if let user = authResult?.user {
                print("Signed in: \(user.email ?? "")")
                // Save the current user
                self.currentUser = user
                // Start listening for pantry changes
                self.setupPantryListener()
                // Start listening for shopping changes
                self.setupShoppingListener()
                
                // Tell all screens that user logged in
                self.listeners.invoke { listener in
                    if listener.listenerType == .auth || listener.listenerType == .all {
                        listener.onAuthChange(user: User(id: user.uid, email: user.email))
                    }
                }
                
                // Send success with user ID
                completion(.success(user.uid))
            }
        }
    }
    
    // Log out of account
    func signOut() throws {
        // Sign out from Firebase
        try authController.signOut()
        // Clear the current user
        currentUser = nil
        // Clear pantry items
        defaultPantry.removeAll()
        // Clear shopping items
        defaultShoppingList.removeAll()
        
        // Tell all screens that user logged out
        listeners.invoke { listener in
            if listener.listenerType == .auth || listener.listenerType == .all {
                listener.onAuthChange(user: nil)
            }
            if listener.listenerType == .pantry || listener.listenerType == .all {
                // Send empty pantry
                listener.onPantryChange(change: .update, pantryItems: [])
            }
            if listener.listenerType == .shopping || listener.listenerType == .all {
                // Send empty shopping list
                listener.onShoppingListChange(change: .update, shoppingItems: [])
            }
        }
    }
}
