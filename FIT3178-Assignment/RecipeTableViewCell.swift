//
//  RecipeTableViewCell.swift
//  FIT3178-Assignment
//
//  Created by Ojaswi Pandey on 14/10/2025.
//
//  A custom table cell that displays a recipe
//  Shows recipe image, title, ingredient info, and missing ingredient badge
//  Layout: Image on left, recipe info on right

import UIKit

class RecipeTableViewCell: UITableViewCell {
    
    // recipeImageView = The photo of the recipe on the left side
    // Has rounded corners and gray background if no image
    let recipeImageView: UIImageView = {
        let iv = UIImageView()
        // Fill the image to cover the space
        iv.contentMode = .scaleAspectFill
        // Cut off any parts that go outside the bounds
        iv.clipsToBounds = true
        // Add rounded corners
        iv.layer.cornerRadius = 8
        // Gray background while loading
        iv.backgroundColor = .systemGray5
        return iv
    }()
    
    // titleLabel = The recipe name displayed at the top
    // Can be up to 2 lines if the name is long
    let titleLabel: UILabel = {
        let label = UILabel()
        // Make text bold and slightly larger
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        // Allow 2 lines maximum
        label.numberOfLines = 2
        return label
    }()
    
    // descriptionLabel = Shows number of ingredients and likes
    // Color is gray to distinguish from the title
    let descriptionLabel: UILabel = {
        let label = UILabel()
        // Smaller font for secondary info
        label.font = UIFont.systemFont(ofSize: 14)
        // Gray color for secondary text
        label.textColor = .secondaryLabel
        // Allow 2 lines
        label.numberOfLines = 2
        return label
    }()
    
    // missingBadge = Orange badge showing "missing ingredients"
    // Hidden if all ingredients are available
    let missingBadge: UIView = {
        let view = UIView()
        // Orange background for warning
        view.backgroundColor = .systemOrange
        // Rounded corners
        view.layer.cornerRadius = 12
        // Hidden by default until configured
        view.isHidden = true
        return view
    }()
    
    // badgeLabel = Text inside the missing badge
    // Shows number of missing ingredients
    let badgeLabel: UILabel = {
        let label = UILabel()
        // Small bold font for badge
        label.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        // White text on orange background
        label.textColor = .white
        // Center the text
        label.textAlignment = .center
        return label
    }()
    
    // availableBadge = Green badge showing "All available"
    // Shown if all ingredients are available
    let availableBadge: UIView = {
        let view = UIView()
        // Green background for success
        view.backgroundColor = .systemGreen
        // Rounded corners
        view.layer.cornerRadius = 12
        // Hidden by default until configured
        view.isHidden = true
        return view
    }()
    
    // availableLabel = Text inside the available badge
    // Shows checkmark with "All available"
    let availableLabel: UILabel = {
        let label = UILabel()
        // Small bold font for badge
        label.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        // White text on green background
        label.textColor = .white
        // Show checkmark symbol
        label.text = "✓ All available"
        // Center the text
        label.textAlignment = .center
        return label
    }()
    
    // Initialize the cell (called when created programmatically)
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        // Set up all the UI elements and constraints
        setupUI()
    }
    
    // Initialize the cell (called from storyboard)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        // Set up all the UI elements and constraints
        setupUI()
    }
    
    func setupUI() {
        // Add all UI elements to the cell
        contentView.addSubview(recipeImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(missingBadge)
        // Add badge label inside the badge
        missingBadge.addSubview(badgeLabel)
        contentView.addSubview(availableBadge)
        // Add available label inside the badge
        availableBadge.addSubview(availableLabel)
        
        // FIXED: Make sure text adapts to Dark Mode
        titleLabel.textColor = .label
        descriptionLabel.textColor = .secondaryLabel
        
        // Disable automatic layout (we'll use Auto Layout instead)
        recipeImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        missingBadge.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        availableBadge.translatesAutoresizingMaskIntoConstraints = false
        availableLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Set up Auto Layout constraints
        NSLayoutConstraint.activate([
            // RECIPE IMAGE LAYOUT
            // Image on the left side with 16pt margin
            recipeImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            // Image at the top with 12pt margin
            recipeImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            // Image at the bottom with 12pt margin
            recipeImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            // Image is 100 pixels wide
            recipeImageView.widthAnchor.constraint(equalToConstant: 100),
            // Image is 100 pixels tall (square)
            recipeImageView.heightAnchor.constraint(equalToConstant: 100),
            
            // TITLE LABEL LAYOUT
            // Title starts where image ends, with 12pt gap
            titleLabel.leadingAnchor.constraint(equalTo: recipeImageView.trailingAnchor, constant: 12),
            // Title at the top with 12pt margin
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            // Title extends to the right edge with 16pt margin
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // DESCRIPTION LABEL LAYOUT
            // Description starts at same position as title
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            // Description below title with 4pt gap
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            // Description has same width as title
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            // MISSING BADGE LAYOUT
            // Badge on the left side, aligned with title
            missingBadge.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            // Badge at the bottom with 12pt margin
            missingBadge.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            // Badge height is 24 pixels
            missingBadge.heightAnchor.constraint(equalToConstant: 24),
            
            // BADGE LABEL INSIDE MISSING BADGE
            // Label has 8pt padding on left
            badgeLabel.leadingAnchor.constraint(equalTo: missingBadge.leadingAnchor, constant: 8),
            // Label has 8pt padding on right
            badgeLabel.trailingAnchor.constraint(equalTo: missingBadge.trailingAnchor, constant: -8),
            // Label fills top of badge
            badgeLabel.topAnchor.constraint(equalTo: missingBadge.topAnchor),
            // Label fills bottom of badge
            badgeLabel.bottomAnchor.constraint(equalTo: missingBadge.bottomAnchor),
            
            // AVAILABLE BADGE LAYOUT
            // Badge on the left side, aligned with title
            availableBadge.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            // Badge at the bottom with 12pt margin
            availableBadge.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            // Badge height is 24 pixels
            availableBadge.heightAnchor.constraint(equalToConstant: 24),
            
            // AVAILABLE LABEL INSIDE AVAILABLE BADGE
            // Label has 8pt padding on left
            availableLabel.leadingAnchor.constraint(equalTo: availableBadge.leadingAnchor, constant: 8),
            // Label has 8pt padding on right
            availableLabel.trailingAnchor.constraint(equalTo: availableBadge.trailingAnchor, constant: -8),
            // Label fills top of badge
            availableLabel.topAnchor.constraint(equalTo: availableBadge.topAnchor),
            // Label fills bottom of badge
            availableLabel.bottomAnchor.constraint(equalTo: availableBadge.bottomAnchor)
        ])
    }
    // Fill in the cell with recipe data
    func configure(with recipe: Recipe) {
        // Display the recipe name
        titleLabel.text = recipe.title
        
        // Get ingredient counts
        let used = recipe.usedIngredientCount ?? 0
        let missing = recipe.missedIngredientCount ?? 0
        // Display used ingredients and likes
        descriptionLabel.text = "\(used) ingredients • \(recipe.likes ?? 0) likes"
        
        // Show appropriate badge based on missing ingredients
        if missing > 0 {
            // Show orange "missing" badge
            missingBadge.isHidden = false
            availableBadge.isHidden = true
            // Show how many are missing
            badgeLabel.text = "!!!!!! \(missing) missing"
        } else {
            // Show green "all available" badge
            missingBadge.isHidden = true
            availableBadge.isHidden = false
        }
        
        // Load and display the recipe image
        if let imageUrl = recipe.image {
            loadImage(from: imageUrl)
        } else {
            // Show placeholder photo icon if no image
            recipeImageView.image = UIImage(systemName: "photo")
        }
    }
    
    // Download and display image from URL
    func loadImage(from urlString: String) {
        // Check if URL is valid
        guard let url = URL(string: urlString) else { return }
        
        // Download the image in the background so it doesn't freeze the app
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            // Check if we got image data
            if let data = data, let image = UIImage(data: data) {
                // Update the image on the main thread
                DispatchQueue.main.async {
                    self?.recipeImageView.image = image
                }
            }
        }.resume()
    }
    
    // Clean up when cell is reused for a different row
    override func prepareForReuse() {
        super.prepareForReuse()
        // Clear the old image
        recipeImageView.image = nil
        // Clear the old title
        titleLabel.text = nil
        // Clear the old description
        descriptionLabel.text = nil
        // Hide badges
        missingBadge.isHidden = true
        availableBadge.isHidden = true
    }
}
