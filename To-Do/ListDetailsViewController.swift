//
//  ListDetailsViewController.swift
//  To-Do
//
//  Created by Vaibhav Gote on 14/05/17.
//
//

import UIKit
import RealmSwift

enum Type {
    case TypeList
    case TypeTask
}

class ListDetailsViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var textFieldPriority: UITextField!
    @IBOutlet weak var textFieldName: UITextField!
    var type : Type!
    
    let realm = try! Realm()
    var list : List?
    var task : Task?
    var isEditable = false
    var selectedPriority = 1
    
    
    //MARK:- ViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }
    
    
    //MARK:- Initial Setup
    
    func setupView() {
        
        if type == .TypeList {
            
            title = "List Details"
            if let todoList = list {
                
                setupTextFieldsWithName(todoList.name, andPriority: todoList.priority)
            }
            
        } else if type == .TypeTask{
            
            title = "Task Details"
            
            if let todoTask = task {
                setupTextFieldsWithName(todoTask.name, andPriority: todoTask.priority)
            }
        }
        
        
        // Setup the priority textfield
        textFieldPriority.delegate = self
        
        // Create a pickerView
        let priorityPicker = UIPickerView()
        priorityPicker.dataSource = self
        priorityPicker.delegate = self
        
        // Create a toolbar
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 44))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.prioritySelected(_:)))
        toolbar.items = [flexibleSpace, doneButton]
        
        textFieldPriority.inputView = priorityPicker
        textFieldPriority.inputAccessoryView = toolbar
        
    }
    
    
    func setupTextFieldsWithName(_ name : String, andPriority priority :  Int) {
        
        // Setup name textfield
        textFieldName.text = name
        
        // Setup priority textfield
        if priority == 1 {
            textFieldPriority?.text = "Low"
        } else if priority == 2 {
            textFieldPriority?.text = "Medium"
        } else if priority == 3 {
            textFieldPriority?.text = "High"
        }
        
    }
    
    
    //MARK:- Actions
    
    @IBAction func editSaveTapped(_ sender: UIBarButtonItem) {
        if isEditable {
            // Save the list or task details
            if type == .TypeList {
                
                realm.beginWrite()

                list?.name = textFieldName.text!
                list?.priority = selectedPriority
                
                try! self.realm.commitWrite()
                
            } else if type == .TypeTask {
                
                realm.beginWrite()
                
                task?.name = textFieldName.text!
                task?.priority = selectedPriority
                
                try! self.realm.commitWrite()
                
            }
            
            // Change the title of the button
            sender.title = "Edit"
            
            
            // Turn off the editing of textfields
            toggleTheEditingOfTextFields(false)
            
            
            // Show success alert
            let alert = UIAlertController(title: "Success", message: "Details saved successfully", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            
            
            // Set the bool flag to false
            isEditable = false
        } else {
            // Change the title of the button
            sender.title = "Save"
            
            // Turn on the editing of textfields
            toggleTheEditingOfTextFields(true)
            
            
            // Set the bool falg to true
            isEditable = true
        }
    }
    
    
    func prioritySelected(_ sender: Any) {
        
        // Dismiss the picker view
        textFieldPriority?.resignFirstResponder()
        
        // Change the textField's text based on the selected priority
        if selectedPriority == 1 {
            textFieldPriority?.text = "Low"
        } else if selectedPriority == 2 {
            textFieldPriority?.text = "Medium"
        } else if selectedPriority == 3 {
            textFieldPriority?.text = "High"
        }
        
    }
    
    
    //MARK:- Helpers
    
    func toggleTheEditingOfTextFields(_ shouldTurnOn : Bool) {
        
        // Enable/Disable the user interaction of the textfields
        textFieldName.isUserInteractionEnabled = shouldTurnOn
        textFieldPriority.isUserInteractionEnabled = shouldTurnOn
        
        // Make the keyboards appear or disappear
        if shouldTurnOn {
            textFieldName.becomeFirstResponder()
        } else {
            view.endEditing(true)
        }
        
    }
    

    
    //MARK:- TextField Delagate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Make the next textfield active
        textFieldPriority.becomeFirstResponder()
        
        return true
        
    }
    
    
    // MARK:- Picker View Datasource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 3
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch row {
        case 0:
            return "Low"
        case 1:
            return "Medium"
        case 2:
            return "High"
        default:
            return ""
        }
    }
    
    
    
    // MARK:- Picker View Delegate
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch row {
        case 0:
            selectedPriority = 1
            break
        case 1:
            selectedPriority = 2
            break
        case 2:
            selectedPriority = 3
            break
        default: break
            
        }
    }
    
}
