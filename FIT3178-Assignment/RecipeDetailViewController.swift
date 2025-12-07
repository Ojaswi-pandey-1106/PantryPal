//
//  RecipeDetailViewController.swift
//  FIT3178-Assignment
//
//  Displays full recipe details with step-by-step instructions and timers
//  Shows recipe image, ingredients, cooking time, and interactive instructions
//  Each instruction with a duration gets an automatic timer button

import UIKit

class RecipeDetailViewController: UIViewController {
    
    // MARK: - Properties
    
    // recipe = The recipe to display details for
    var recipe: Recipe?
    
    // recipeId = The ID used to fetch full details from API
    var recipeId: Int?
    
    // apiService = Service to fetch recipe details
    let apiService = RecipeAPIService()
    
    // MARK: - UI Components
    
    // scrollView = Allows scrolling through all content
    let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = .lightBackground
        return sv
    }()
    
    // contentView = Container for all content inside scroll view
    let contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    // recipeImageView = Large image at the top
    let recipeImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray5
        return iv
    }()
    
    // titleLabel = Recipe name
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 0
        label.textColor = .label
        return label
    }()
    
    // timeLabel = Cooking time
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel  // FIXED: Was .secondaryText
        return label
    }()
    
    // servingsLabel = Number of servings
    let servingsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel  // FIXED: Was .secondaryText
        return label
    }()
    
    // instructionsLabel = Section header
    let instructionsLabel: UILabel = {
        let label = UILabel()
        label.text = "Instructions"
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label  // FIXED: Was .primaryText
        return label
    }()
    
    // instructionsStackView = Container for all instruction steps
    let instructionsStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        sv.alignment = .fill
        return sv
    }()
    
    // loadingIndicator = Shows while fetching data
    let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        fetchRecipeDetails()
    }
    
    // MARK: - Setup
    
    func setupUI() {
        view.backgroundColor = .lightBackground
        title = "Recipe Details"
        
        // Add all views
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(recipeImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(servingsLabel)
        contentView.addSubview(instructionsLabel)
        contentView.addSubview(instructionsStackView)
        
        view.addSubview(loadingIndicator)
        
        // Disable autoresizing masks
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        recipeImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        servingsLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionsStackView.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // ScrollView fills the screen
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView inside ScrollView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Recipe Image at top
            recipeImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            recipeImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            recipeImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            recipeImageView.heightAnchor.constraint(equalToConstant: 250),
            
            // Title below image
            titleLabel.topAnchor.constraint(equalTo: recipeImageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Time below title
            timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            // Servings next to time
            servingsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            servingsLabel.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 20),
            
            // Instructions header
            instructionsLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 24),
            instructionsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            instructionsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Instructions stack
            instructionsStackView.topAnchor.constraint(equalTo: instructionsLabel.bottomAnchor, constant: 12),
            instructionsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            instructionsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            instructionsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            // Loading indicator centered
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        loadingIndicator.hidesWhenStopped = true
    }
    
    // MARK: - Data Fetching
    
    func fetchRecipeDetails() {
        guard let id = recipeId ?? recipe?.id else {
            showError(message: "Recipe ID not found")
            return
        }
        
        loadingIndicator.startAnimating()
        
        apiService.fetchRecipeDetails(recipeId: id) { [weak self] recipe, error in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                
                if let error = error {
                    self?.showError(message: "Failed to load recipe: \(error.localizedDescription)")
                    return
                }
                
                if let recipe = recipe {
                    self?.recipe = recipe
                    self?.displayRecipe(recipe)
                }
            }
        }
    }
    
    // MARK: - Display Recipe
    
    func displayRecipe(_ recipe: Recipe) {
        // Set title
        titleLabel.text = recipe.title
        
        // Set time
        if let time = recipe.readyInMinutes {
            timeLabel.text = "⏱️ \(time) min"
        }
        
        // Set servings
        if let servings = recipe.servings {
            servingsLabel.text = "🍽️ \(servings) servings"
        }
        
        // Load image
        if let imageUrl = recipe.image {
            loadImage(from: imageUrl)
        }
        
        // Parse and display instructions
        parseInstructions(recipe.instructions)
    }
    
    // Parse instructions and create step views
    func parseInstructions(_ instructionsText: String?) {
        guard let text = instructionsText, !text.isEmpty else {
            let noInstructionsLabel = UILabel()
            noInstructionsLabel.text = "No instructions available for this recipe."
            noInstructionsLabel.textColor = .secondaryText
            noInstructionsLabel.numberOfLines = 0
            instructionsStackView.addArrangedSubview(noInstructionsLabel)
            return
        }
        
        // Remove HTML tags if present
        let cleanText = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // Split into sentences (basic approach)
        let sentences = cleanText.components(separatedBy: ". ").filter { !$0.isEmpty }
        
        for (index, sentence) in sentences.enumerated() {
            let stepView = createStepView(stepNumber: index + 1, instruction: sentence)
            instructionsStackView.addArrangedSubview(stepView)
        }
    }
    
    // Create a single instruction step with optional timer
    func createStepView(stepNumber: Int, instruction: String) -> UIView {
        let container = UIView()
        UIHelper.styleCardView(container, cornerRadius: 12, shadowOpacity: 0.05)
        container.backgroundColor = .white
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Step number and text
        let stepLabel = UILabel()
        stepLabel.text = "Step \(stepNumber)"
        stepLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        stepLabel.textColor = .systemBlue
        
        let instructionLabel = UILabel()
        instructionLabel.text = instruction
        instructionLabel.font = UIFont.systemFont(ofSize: 15)
        instructionLabel.numberOfLines = 0
        instructionLabel.textColor = .label
        
        stackView.addArrangedSubview(stepLabel)
        stackView.addArrangedSubview(instructionLabel)
        
        // Check if instruction contains a time duration
        if let duration = extractDuration(from: instruction) {
            let timerButton = UIButton(type: .system)
            timerButton.setTitle("⏱️ Start \(duration) min timer", for: .normal)
            timerButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            UIHelper.styleButton(timerButton, color: .accentOrange)
            timerButton.addTarget(self, action: #selector(timerButtonTapped(_:)), for: .touchUpInside)
            timerButton.tag = duration
            
            stackView.addArrangedSubview(timerButton)
            
            NSLayoutConstraint.activate([
                timerButton.heightAnchor.constraint(equalToConstant: 40)
            ])
        }
        
        container.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
        
        return container
    }
    
    // Extract duration from instruction text (e.g., "5 minutes", "10 mins")
    func extractDuration(from text: String) -> Int? {
        let patterns = [
            "(\\d+)\\s*minutes?",
            "(\\d+)\\s*mins?",
            "(\\d+)\\s*minute",
            "(\\d+)\\s*min"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    if let durationRange = Range(match.range(at: 1), in: text) {
                        if let duration = Int(text[durationRange]) {
                            return duration
                        }
                    }
                }
            }
        }
        return nil
    }
    
    // MARK: - Timer Action
    
    @objc func timerButtonTapped(_ sender: UIButton) {
        let duration = sender.tag
        startTimer(duration: duration)
    }
    
    func startTimer(duration: Int) {
        let alert = UIAlertController(
            title: "⏱️ Timer Started",
            message: "Timer set for \(duration) minutes. You'll be notified when it's done!",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        
        // Schedule notification after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(duration * 60)) { [weak self] in
            self?.showTimerComplete(duration: duration)
        }
    }
    
    func showTimerComplete(duration: Int) {
        let alert = UIAlertController(
            title: "⏰ Timer Complete!",
            message: "\(duration) minutes have elapsed. Check your cooking step!",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Image Loading
    
    func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.recipeImageView.image = image
                }
            }
        }.resume()
    }
    
    // MARK: - Error Handling
    
    func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
