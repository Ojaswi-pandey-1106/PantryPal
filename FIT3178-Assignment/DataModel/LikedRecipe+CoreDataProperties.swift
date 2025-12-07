//
//  LikedRecipe+CoreDataProperties.swift
//  FIT3178-Assignment
//
//  Created by Ojaswi Pandey on 8/11/2025.
//
//

import Foundation
import CoreData

// This extension adds properties (data fields) to LikedRecipe
extension LikedRecipe {
    
    // Use this when you want to show all liked recipes to the user
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LikedRecipe> {
        return NSFetchRequest<LikedRecipe>(entityName: "LikedRecipe")
    }
    
    // recipeId = The recipe's ID number
    @NSManaged public var recipeId: Int32
    // title = The name of the recipe
    @NSManaged public var title: String?
    // image = The picture/photo of the recipe
    @NSManaged public var image: String?
    // dateAdded = When did the user like this recipe?
    @NSManaged public var dateAdded: Date?

}
// Swift handles everything automatically here
extension LikedRecipe : Identifiable {

}
