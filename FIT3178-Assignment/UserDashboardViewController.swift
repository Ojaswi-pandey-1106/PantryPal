//
//  UserDashboardViewController.swift
//  FIT3178-Assignment
//
//  PantryPal - Personalized Health Dashboard
//
//  This screen shows the user's health metrics and calorie intake recommendations
//  User can input their weight and height using steppers or text fields
//  App calculates BMI and suggests daily calorie intake based on fitness goals

import UIKit

class UserDashboardViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var weightTextField: UITextField!
    
    @IBOutlet weak var heightTextField: UITextField!
    
    @IBOutlet weak var bmiTextField: UITextField!
    
    @IBOutlet weak var weightStepper: UIStepper!
    
    @IBOutlet weak var heightStepper: UIStepper!
    
    @IBOutlet weak var tableView: UITableView!
    
    var currentWeight: Double = 70.0
        var currentHeight: Double = 170.0
        var calorieData: [(goal: String, deficit: String, percentage: String, calories: Int)] = []
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            // Apply modern styling
            applyStandardBackground()
            styleAllComponents()
            
            tableView.dataSource = self
            tableView.delegate = self
            tableView.register(CalorieIntakeCell.self, forCellReuseIdentifier: "CalorieCell")
            tableView.rowHeight = 100
            tableView.separatorStyle = .none
            tableView.backgroundColor = .clear
            tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            view.addGestureRecognizer(tapGesture)
            
            setupSteppers()
            updateWeightDisplay()
            updateHeightDisplay()
            calculateBMI()
            calculateCalories()
            setupCameraButton()
            setupInfoButton()
        }
        
        // MARK: - Setup Methods
        
        func setupInfoButton() {
            UIHelper.addInfoButton(
                to: self,
                message: """
                💪 Health Dashboard
                
                Track your health metrics and get personalized calorie recommendations!
                
                How to use:
                • ⚖️ Use steppers to adjust your weight
                • 📏 Use steppers to adjust your height
                • 📊 View your calculated BMI
                • 🎯 See personalized calorie goals
                
                Calorie Goals:
                • Maintain Weight: Keep current weight
                • Mild Weight Loss: Lose 0.25kg/week
                • Weight Loss: Lose 0.5kg/week
                
                Note: BMI is calculated using the formula: weight (kg) / height² (m)
                
                Tip: These recommendations assume moderate activity level. Adjust based on your lifestyle!
                """,
                title: "Dashboard Help"
            )
        }
        
        func styleAllComponents() {
            // Style text fields with modern appearance
            UIHelper.styleTextField(weightTextField)
            UIHelper.styleTextField(heightTextField)
            UIHelper.styleTextField(bmiTextField)
            
            // Make text fields read-only
            weightTextField.isUserInteractionEnabled = false
            heightTextField.isUserInteractionEnabled = false
            bmiTextField.isUserInteractionEnabled = false
            
            // Center text in fields
            weightTextField.textAlignment = .center
            heightTextField.textAlignment = .center
            bmiTextField.textAlignment = .center
            
            // Bold fonts
            weightTextField.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
            heightTextField.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
            bmiTextField.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
            
            // Style steppers
            weightStepper.tintColor = .primaryBlue
            heightStepper.tintColor = .primaryBlue
        }
        
        func setupCameraButton() {
            let cameraButton = UIBarButtonItem(
                image: UIImage(systemName: "camera.fill"),
                style: .plain,
                target: self,
                action: #selector(openBarcodeScanner)
            )
            cameraButton.tintColor = .primaryBlue
            navigationItem.leftBarButtonItem = cameraButton
        }
        
        @objc func openBarcodeScanner() {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let scannerVC = storyboard.instantiateViewController(withIdentifier: "BarcodeScannerViewController") as! BarcodeScannerViewController
            let navController = UINavigationController(rootViewController: scannerVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        }
        
        @objc func dismissKeyboard() {
            view.endEditing(true)
        }
        
        func setupSteppers() {
            weightStepper.minimumValue = 30
            weightStepper.maximumValue = 200
            weightStepper.stepValue = 1
            weightStepper.value = currentWeight
            
            heightStepper.minimumValue = 100
            heightStepper.maximumValue = 250
            heightStepper.stepValue = 1
            heightStepper.value = currentHeight
        }
        
        @IBAction func weightStepperChanged(_ sender: UIStepper) {
            currentWeight = sender.value
            updateWeightDisplay()
            calculateBMI()
            calculateCalories()
            tableView.reloadData()
        }
        
        @IBAction func heightStepperChanged(_ sender: UIStepper) {
            currentHeight = sender.value
            updateHeightDisplay()
            calculateBMI()
            calculateCalories()
            tableView.reloadData()
        }
        
        func updateWeightDisplay() {
            weightTextField.text = "\(Int(currentWeight)) kg"
        }
        
        func updateHeightDisplay() {
            heightTextField.text = "\(Int(currentHeight)) cm"
        }
        
        func calculateBMI() {
            let heightInMeters = currentHeight / 100
            let bmi = currentWeight / (heightInMeters * heightInMeters)
            
            // Add emoji based on BMI range
            let bmiEmoji: String
            if bmi < 18.5 {
                bmiEmoji = "⚠️"
            } else if bmi < 25 {
                bmiEmoji = "✅"
            } else if bmi < 30 {
                bmiEmoji = "⚠️"
            } else {
                bmiEmoji = "🔴"
            }
            
            bmiTextField.text = "\(bmiEmoji) \(String(format: "%.1f", bmi))"
        }
        
        func calculateCalories() {
            let basalMetabolicRate = (10 * currentWeight) + (6.25 * currentHeight) - 161
            let maintenanceCalories = Int(basalMetabolicRate * 1.55)
            
            calorieData = [
                ("Maintain weight", "0kg/week", "100%", maintenanceCalories),
                ("Mild weight loss", "0.25kg/week", "84%", Int(Double(maintenanceCalories) * 0.84)),
                ("Weight loss", "0.5kg/week", "69%", Int(Double(maintenanceCalories) * 0.69))
            ]
            
            tableView.reloadData()
        }
        
        // MARK: - Table View Data Source
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return calorieData.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CalorieCell", for: indexPath) as! CalorieIntakeCell
            let data = calorieData[indexPath.row]
            cell.configure(goal: data.goal, deficit: data.deficit, percentage: data.percentage, calories: data.calories)
            return cell
        }
        
        func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            return "🎯 Your Daily Calorie Goals"
        }
        
        func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
            if let headerView = view as? UITableViewHeaderFooterView {
                headerView.textLabel?.textColor = .primaryText
                headerView.textLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
            }
        }
    }

    // MARK: - Improved Calorie Intake Cell

    class CalorieIntakeCell: UITableViewCell {
        
        let containerView = UIView()
        let leftBox = UIView()
        let rightBox = UIView()
        let goalLabel = UILabel()
        let deficitLabel = UILabel()
        let percentageLabel = UILabel()
        let caloriesLabel = UILabel()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupUI()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupUI()
        }
        
        func setupUI() {
            selectionStyle = .none
            contentView.backgroundColor = .clear
            backgroundColor = .clear
            
            // Container with shadow
            containerView.backgroundColor = .clear
            contentView.addSubview(containerView)
            containerView.translatesAutoresizingMaskIntoConstraints = false
            
            // LEFT BOX - Modern gradient-style background
            leftBox.backgroundColor = UIColor.primaryGreen.withAlphaComponent(0.15)
            leftBox.layer.cornerRadius = 12
            leftBox.layer.borderWidth = 1.5
            leftBox.layer.borderColor = UIColor.primaryGreen.cgColor
            containerView.addSubview(leftBox)
            leftBox.translatesAutoresizingMaskIntoConstraints = false
            
            // RIGHT BOX - Clean white background
            rightBox.backgroundColor = .cardBackground
            rightBox.layer.cornerRadius = 12
            rightBox.layer.shadowColor = UIColor.black.cgColor
            rightBox.layer.shadowOffset = CGSize(width: 0, height: 2)
            rightBox.layer.shadowOpacity = 0.08
            rightBox.layer.shadowRadius = 4
            containerView.addSubview(rightBox)
            rightBox.translatesAutoresizingMaskIntoConstraints = false
            
            // GOAL LABEL
            goalLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            goalLabel.textColor = .primaryGreen
            goalLabel.textAlignment = .center
            goalLabel.numberOfLines = 2
            leftBox.addSubview(goalLabel)
            goalLabel.translatesAutoresizingMaskIntoConstraints = false
            
            // DEFICIT LABEL
            deficitLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            deficitLabel.textColor = .secondaryText
            deficitLabel.textAlignment = .center
            leftBox.addSubview(deficitLabel)
            deficitLabel.translatesAutoresizingMaskIntoConstraints = false
            
            // PERCENTAGE LABEL
            percentageLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
            percentageLabel.textColor = .systemGray
            percentageLabel.textAlignment = .center
            rightBox.addSubview(percentageLabel)
            percentageLabel.translatesAutoresizingMaskIntoConstraints = false
            
            // CALORIES LABEL
            caloriesLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
            caloriesLabel.textColor = .primaryText
            caloriesLabel.textAlignment = .center
            rightBox.addSubview(caloriesLabel)
            caloriesLabel.translatesAutoresizingMaskIntoConstraints = false
            
            // LAYOUT CONSTRAINTS
            NSLayoutConstraint.activate([
                // Container
                containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
                containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
                
                // Left Box
                leftBox.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                leftBox.topAnchor.constraint(equalTo: containerView.topAnchor),
                leftBox.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                leftBox.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.48),
                
                // Right Box
                rightBox.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                rightBox.topAnchor.constraint(equalTo: containerView.topAnchor),
                rightBox.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                rightBox.leadingAnchor.constraint(equalTo: leftBox.trailingAnchor, constant: 8),
                
                // Goal Label
                goalLabel.centerXAnchor.constraint(equalTo: leftBox.centerXAnchor),
                goalLabel.centerYAnchor.constraint(equalTo: leftBox.centerYAnchor, constant: -8),
                goalLabel.leadingAnchor.constraint(equalTo: leftBox.leadingAnchor, constant: 8),
                goalLabel.trailingAnchor.constraint(equalTo: leftBox.trailingAnchor, constant: -8),
                
                // Deficit Label
                deficitLabel.centerXAnchor.constraint(equalTo: leftBox.centerXAnchor),
                deficitLabel.topAnchor.constraint(equalTo: goalLabel.bottomAnchor, constant: 4),
                
                // Percentage Label
                percentageLabel.centerXAnchor.constraint(equalTo: rightBox.centerXAnchor),
                percentageLabel.topAnchor.constraint(equalTo: rightBox.topAnchor, constant: 16),
                
                // Calories Label
                caloriesLabel.centerXAnchor.constraint(equalTo: rightBox.centerXAnchor),
                caloriesLabel.centerYAnchor.constraint(equalTo: rightBox.centerYAnchor, constant: 6)
            ])
        }
        
        func configure(goal: String, deficit: String, percentage: String, calories: Int) {
            // Add emoji based on goal
            let emoji: String
            switch goal {
            case "Maintain weight":
                emoji = "⚖️"
            case "Mild weight loss":
                emoji = "📉"
            case "Weight loss":
                emoji = "🎯"
            default:
                emoji = "📊"
            }
            
            goalLabel.text = "\(emoji) \(goal)"
            deficitLabel.text = deficit
            percentageLabel.text = "(\(percentage) of maintenance)"
            caloriesLabel.text = "\(calories)\nCalories/day"
            caloriesLabel.numberOfLines = 2
        }
}
