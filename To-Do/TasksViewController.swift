//
//  TasksViewController.swift
//  To-Do
//
//  Created by Prajyot on 20/03/2017.
//
//

import UIKit
import RealmSwift
import Realm

class TasksViewController: UITableViewController, UISearchResultsUpdating, UIPickerViewDelegate, UIPickerViewDataSource {

    // MARK:- Variables
    
    var list: List!
    let realm = try! Realm()
    lazy var allTasks: Results<Task> = { self.realm.objects(Task.self) }()
    let searchController = UISearchController(searchResultsController: nil)
    var filteredTasks : Results<Task>!
    var selectedPriority = "Low"
    var tasksForSelectedList: Results<Task> {
        get {
            return allTasks.filter("list.dateCreated == %@", list.dateCreated)
        }
    }
    
    
    // MARK:- ViewController LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Add a searchController
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        
        // Add a add button that adds a task
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewTask(_:)))
        self.navigationItem.rightBarButtonItem = addButton
        
        // Set the list's name as title
        self.title = list.name
    }
    
    
    // MARK:- Actions
    
    func insertNewTask(_ sender: Any) {
        
        // Show a alertController asking the new task's name
        let newTaskAlert = UIAlertController(title: "Add New Task", message: "Enter the name of the task", preferredStyle: .alert)
        
        // Add a textField to enter the name
        newTaskAlert.addTextField { (nameTextFiled) in
            // Configure the textFiled
            nameTextFiled.placeholder = "name of the task"
            nameTextFiled.clearButtonMode = .whileEditing
            nameTextFiled.borderStyle = .roundedRect
        }
        
        // Add a textField to enter the priority
        newTaskAlert.addTextField { (nameTextFiled) in
            // Configure the textFiled
            nameTextFiled.placeholder = "priority"
            nameTextFiled.text = "Low"
            nameTextFiled.clearButtonMode = .whileEditing
            nameTextFiled.borderStyle = .roundedRect
            
            // Create a pickerView
            let priorityPicker = UIPickerView()
            priorityPicker.dataSource = self
            priorityPicker.delegate = self
            
            // Create a toolbar
            let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 44))
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.prioritySelected(_:)))
            toolbar.items = [flexibleSpace, doneButton]
            
            nameTextFiled.inputView = priorityPicker
            nameTextFiled.inputAccessoryView = toolbar
        }
        
        // Add an "Add" button
        newTaskAlert.addAction(UIAlertAction(title: "Add", style: .default, handler: { (addAlertAction) in
            
            let nameTextField = newTaskAlert.textFields?.first
            
            let indexPath = IndexPath(row: self.tableView.numberOfRows(inSection: 0), section: 0)
            
            
            let newTask = Task()
            newTask.name = (nameTextField?.text)!
            newTask.priority = self.selectedPriority
            newTask.list = self.list
            self.realm.beginWrite()
            self.realm.add(newTask)
            try! self.realm.commitWrite()
            self.tableView.insertRows(at: [indexPath], with: .automatic)
            
        }))
        
        // Add a "Cancel" button
        newTaskAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // Keep the "Add" button disabled at first
        //newListAlert.actions.first?.isEnabled = false
        
        // Show the alert
        present(newTaskAlert, animated: true, completion: nil)
        
    }
    
    func prioritySelected(_ sender: Any) {
        
        let newListAlert = self.presentedViewController as! UIAlertController
        let priorityTextFieled = newListAlert.textFields?.last
        priorityTextFieled?.text = selectedPriority;
        priorityTextFieled?.resignFirstResponder()
        
    }
    
    
    //MARK:- Table View DataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredTasks.count
        }
        
        return tasksForSelectedList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // Get the corresponding task, depending upon  whether we are searching or not
        let task : Task
        if searchController.isActive && searchController.searchBar.text != "" {
            task = filteredTasks[indexPath.row]
        } else {
            task = tasksForSelectedList[indexPath.row]
        }
        
        // Set the name
        cell.textLabel?.text = task.name
        
        // Check if task is completed, and indicate via a checkmark
        cell.accessoryType = (task.isCompleted) ? .checkmark : .none
        
        return cell
        
    }
    
    
    // MARK:- TableView Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Get the selected cell, and the corresponding task
        let cell = tableView.cellForRow(at: indexPath)
        let task = tasksForSelectedList[indexPath.row]
        
        // Toggle its "isCompleted" state
        self.realm.beginWrite()
        task.isCompleted = !task.isCompleted
        try! self.realm.commitWrite()
        
        // Update it on the cell
        cell?.accessoryType = (task.isCompleted) ? .checkmark : .none
        
        tableView.deselectRow(at: indexPath, animated: true)
        
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
            selectedPriority = "Low"
        case 1:
            selectedPriority = "Medium"
        case 2:
            selectedPriority = "High"
        default: break
            
        }
    }
    
    
    // MARK:- Helpers
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredTasks = self.tasksForSelectedList.filter("name CONTAINS[c] %@", searchText)
        
        tableView.reloadData()
    }
    
    
    // MARK:- UISearchUpdating Delegate
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }

}

