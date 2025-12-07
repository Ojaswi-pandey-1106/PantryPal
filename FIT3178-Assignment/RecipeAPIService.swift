//
//  RecipeAPIService.swift
//  FIT3178-Assignment
//
//  Created by Ojaswi Pandey on 14/10/2025.
//
//  Communicates with Spoonacular Recipe API to fetch recipes
//  Methods to search recipes by ingredients, get details, and download images
//  Handles all network requests and JSON parsing

import UIKit

class RecipeAPIService {
    
    // API_KEY = The authentication key for Spoonacular API
    // Required to make requests to the API
    let API_KEY = "58d903219f9d42dc9b2699e1f2f8d721"
    
    // BASE_URL = The main URL for Spoonacular recipe API
    // All recipe endpoints start with this URL
    private let BASE_URL = "https://api.spoonacular.com/recipes"
    
    
    // Search for recipes based on ingredient names
    // ingredients = Array of ingredient names (e.g., ["milk", "eggs", "bread"])
    // completion = Callback that returns recipes or error when done
    func fetchRecipesByIngredients(ingredients: [String], completion: @escaping ([Recipe]?, Error?) -> Void) {
        
        // Convert ingredient array to comma-separated string
        let ingredientsString = ingredients.joined(separator: ",")
        
        // Build the full URL for the API request
        // Parameters:
        // - apiKey: Authentication key
        // - ingredients: The ingredients to search for
        // - number: How many recipes to return (100 is maximum)
        // - ranking: 2 means rank by used ingredients (best matches first)
        // - ignorePantry: false means include common pantry items
        let urlString = "\(BASE_URL)/findByIngredients?apiKey=\(API_KEY)&ingredients=\(ingredientsString)&number=100&ranking=2&ignorePantry=false"
        
        // Encode the URL to handle special characters (spaces, etc)
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            // If URL is invalid, send back an error
            completion(nil, NSError(domain: "Invalid URL", code: -1, userInfo: nil))
            return
        }
        
        // Make the network request
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            // Check if there was a network error
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                // Send back the error
                completion(nil, error)
                return
            }
            
            // Check if we got data back
            guard let data = data else {
                print("No data received!!")
                // Send back an error
                completion(nil, NSError(domain: "No data", code: -1, userInfo: nil))
                return
            }
            
            // Try to parse the JSON data
            do {
                // Create a JSON decoder
                let decoder = JSONDecoder()
                // Decode the JSON data into Recipe objects
                let recipes = try decoder.decode([Recipe].self, from: data)
                print("Successfully fetched!! \(recipes.count) recipes")
                // Send back the recipes
                completion(recipes, nil)
            } catch {
                // If JSON parsing failed, send back the error
                print("JSON parsing error!!: \(error)")
                completion(nil, error)
            }
        }
        
        // Start the network request
        task.resume()
    }

    // Get detailed information about a specific recipe
    // recipeId = The ID of the recipe to get details for
    func fetchRecipeDetails(recipeId: Int, completion: @escaping (Recipe?, Error?) -> Void) {
        
        // Build the URL for getting recipe details
        // Pass the recipe ID in the URL
        let urlString = "\(BASE_URL)/\(recipeId)/information?apiKey=\(API_KEY)"
        
        // Check if URL is valid
        guard let url = URL(string: urlString) else {
            // If URL is invalid, send back an error
            completion(nil, NSError(domain: "Invalid URL", code: -1, userInfo: nil))
            return
        }
        
        print("Fetching recipe details for ID....: \(recipeId)")
        
        // Make the network request
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            // Check if there was a network error
            if let error = error {
                // Send back the error
                completion(nil, error)
                return
            }
            
            // Check if we got data back
            guard let data = data else {
                // Send back an error
                completion(nil, NSError(domain: "No data", code: -1, userInfo: nil))
                return
            }
            
            // Try to parse the JSON data
            do {
                // Create a JSON decoder
                let decoder = JSONDecoder()
                // Decode the JSON data into a single Recipe object
                let recipe = try decoder.decode(Recipe.self, from: data)
                print("Successfully fetched recipe details!!")
                // Send back the recipe
                completion(recipe, nil)
            } catch {
                // If JSON parsing failed, send back the error
                print("JSON parsing error!!: \(error)")
                completion(nil, error)
            }
        }
        
        // Start the network request
        task.resume()
    }
    
    // MARK: - Download Image
    
    // Download an image from a URL
    // urlString = The URL of the image to download
    // completion = Callback that returns the image or nil if failed
    func downloadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        // Check if the URL string is valid
        guard let url = URL(string: urlString) else {
            // If URL is invalid, send back nil
            completion(nil)
            return
        }
        
        // Make the network request to download the image
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            // Check if we got data and can convert it to an image
            if let data = data, let image = UIImage(data: data) {
                // Send back the image
                completion(image)
            } else {
                // If failed, send back nil
                completion(nil)
            }
        }
        
        // Start the network request
        task.resume()
    }
}
