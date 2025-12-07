//
//  Recipe.swift
//  FIT3178-Assignment
//
//  Created by Ojaswi Pandey on 14/10/2025.
//
//  Data model for a recipe fetched from the API
//  Stores recipe info like title, image, ingredients, cooking details
//  Also defines Ingredient class for individual ingredients in a recipe

import Foundation
import UIKit

// Recipe = A single recipe from the Spoonacular API
class Recipe: NSObject, Codable {
    
    // id = The unique ID for this recipe from the API
    var id: Int?
    
    // title = The name of the recipe
    var title: String?
    
    // image = URL link to the recipe's photo
    var image: String?
    
    // imageType = The type of image file (e.g., "jpg", "png")
    var imageType: String?
    
    // usedIngredientCount = How many ingredients from the pantry are in this recipe
    // This shows how well the recipe matches the user's pantry items
    var usedIngredientCount: Int?
    
    // missedIngredientCount = How many ingredients are NOT in the pantry
    // User would need to buy these if they want to make the recipe
    var missedIngredientCount: Int?
    
    // missedIngredients = Array of ingredients that are missing
    // Contains Ingredient objects with details like amount and unit
    var missedIngredients: [Ingredient]?
    
    // usedIngredients = Array of ingredients that are in the pantry
    // Contains Ingredient objects showing what user already has
    var usedIngredients: [Ingredient]?
    
    // unusedIngredients = Array of ingredients that are available but not needed
    var unusedIngredients: [Ingredient]?
    
    // likes = How many people have liked this recipe on the API
    var likes: Int?
    
    // readyInMinutes = How long it takes to cook the recipe
    // In minutes (e.g., 30 means 30 minutes)
    var readyInMinutes: Int?
    
    // servings = How many servings the recipe makes
    var servings: Int?
    
    // summary = A brief description of the recipe
    var summary: String?
    
    // instructions = Step-by-step cooking instructions
    var instructions: String?
    
    // Compute whether this recipe has any missing ingredients
    // Returns true if there are ingredients not in pantry
    var hasMissingIngredients: Bool {
        return (missedIngredientCount ?? 0) > 0
    }
    
    // Computed property to show missing ingredients message
    var missingIngredientsText: String {
        // Check if there are missing ingredients
        guard let count = missedIngredientCount, count > 0 else {
            // If none missing, return success message
            return "All ingredients available"
        }
        // If missing, return message with count
        return "\(count) ingredient\(count == 1 ? "" : "s") missing"
    }
    
    // Initialize a Recipe with basic info
    init(id: Int?, title: String?, image: String?) {
        // Save the recipe ID
        self.id = id
        // Save the recipe name
        self.title = title
        // Save the recipe image URL
        self.image = image
        // Initialize parent class
        super.init()
    }
    
    // Convenience initializer - creates an empty recipe
    convenience override init() {
        // Call main init with all nil values
        self.init(id: nil, title: nil, image: nil)
    }
}

// Ingredient = A single ingredient in a recipe
class Ingredient: NSObject, Codable {
    
    // id = The unique ID for this ingredient from the API
    var id: Int?
    
    // name = The name of the ingredient (e.g., "milk", "eggs")
    var name: String?
    
    // original = The original text from the recipe (e.g., "2 cups flour")
    var original: String?
    
    // amount = How much of this ingredient (e.g., 2)
    var amount: Double?
    
    // unit = What unit to measure in (e.g., "cups", "tablespoons", "grams")
    var unit: String?
    
    // image = URL to the ingredient's photo
    var image: String?

    // Formatted text to display the ingredient nicely
    var displayText: String {
        // Start with the ingredient name
        var text = name ?? "Unknown ingredient"
        
        // If we have amount and unit, add them to the front
        if let amount = amount, let unit = unit, !unit.isEmpty {
            text = "\(amount) \(unit) \(text)"
        }
        return text
    }
}
