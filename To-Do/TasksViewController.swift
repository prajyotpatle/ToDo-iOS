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

class TasksViewController: UITableViewController, UISearchResultsUpdating, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {

    // MARK:- Variables
    
    var list: List!
    let realm = try! Realm()
    lazy var allTasks: Results<Task> = { self.realm.objects(Task.self) }()
    let searchController = UISearchController(searchResultsController: nil)
    var filteredTasks : Results<Task>!
    var selectedPriority = 1
    
    private var _tasks : Results<Task>!
    var tasksForSelectedList: Results<Task> {
        get {
            return allTasks.filter("list.dateCreated == %@", list.dateCreated)
        }
        set {
            allTasks = newValue
        }
    }
    
    // The current sort order of the tasks
    var currentSortOrder = SortOrder.Date
    
    // The ascending/descending sort orders of respective attributes
    var nameSortOrderIsAscending = true
    var dateSortOrderIsAscending = false
    var prioritySortOrderIsAscending = true
    
    
    // MARK:- ViewController LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        // Add a searchController
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        
        // Create "Add" and "Sort" navigationbar buttons
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewTask(_:)))
        let sortButton = UIBarButtonItem(image: UIImage.init(named: "sort"), style: .plain, target: self, action: #selector(showSortOptions(_:)))
        
        self.navigationItem.rightBarButtonItems = [sortButton, addButton]
        
        // Set the list's name as title
        self.title = list.name
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Reload the tableView
        tableView.reloadData()
    }
    
    
    
    // MARK:- Actions
    
    func insertNewTask(_ sender: Any) {
        
        // Show a alertController asking the new task's name
        let newTaskAlert = UIAlertController(title: "Add New Task", message: "Enter the name of the task", preferredStyle: .alert)
        
        // Add a textField to enter the name
        newTaskAlert.addTextField { (nameTextFiled) in
            // Configure the textFiled
            nameTextFiled.placeholder = "Name of the task"
            nameTextFiled.clearButtonMode = .whileEditing
            nameTextFiled.borderStyle = .roundedRect
            nameTextFiled.delegate = self
        }
        
        // Add a textField to enter the priority
        newTaskAlert.addTextField { (nameTextFiled) in
            // Configure the textFiled
            nameTextFiled.placeholder = "Priority"
            nameTextFiled.text = "Low"
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
        
        // Make the "Add" action disabled by dafault
        newTaskAlert.actions.first?.isEnabled = false
        
        // Add a "Cancel" button
        newTaskAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // Show the alert
        present(newTaskAlert, animated: true, completion: nil)
        
    }
    
    func prioritySelected(_ sender: Any) {
        
        let newListAlert = self.presentedViewController as! UIAlertController
        let priorityTextFieled = newListAlert.textFields?.last
        priorityTextFieled?.resignFirstResponder()
        
        // Change the textField's text based on the selected priority
        if selectedPriority == 1 {
            priorityTextFieled?.text = "Low"
        } else if selectedPriority == 2 {
            priorityTextFieled?.text = "Medium"
        } else if selectedPriority == 3 {
            priorityTextFieled?.text = "High"
        }
        
    }
    
    
    func showSortOptions(_ sender: Any) {
        
        let actionSheet = UIAlertController(title: "Sort By", message: "Select a sort order", preferredStyle: .actionSheet)
        
        // Make appropriate strings according to the sort order and ascending/sescending order
        var nameString = "Name"
        var dateString = "Date"
        var priorityString = "Priority"
        
        switch currentSortOrder {
            
        case .Name:
            if nameSortOrderIsAscending {
                nameString = "Name ↓"
            } else {
                nameString = "Name ↑"
            }
            break
            
        case .Date:
            if dateSortOrderIsAscending {
                dateString = "Date ↑"
            } else {
                dateString = "Date ↓"
            }
            break
            
        case .Priority:
            if prioritySortOrderIsAscending {
                priorityString = "Priority ↓"
            } else {
                priorityString = "Priority ↑"
            }
            break
        }
        
        
        // Add a "Name" action
        actionSheet.addAction(UIAlertAction(title: nameString, style: .default, handler: { (actionSheet) in
            
            self.tasksForSelectedList = self.tasksForSelectedList.sorted(byKeyPath: "name", ascending: self.nameSortOrderIsAscending)
            
            // Toggle the nameSortOrder
            self.nameSortOrderIsAscending = !self.nameSortOrderIsAscending
            
            // Change the current sort Order
            self.currentSortOrder = .Name
            
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
            })
            
        }))
        
        
        // Add a "Date" action
        actionSheet.addAction(UIAlertAction(title: dateString, style: .default, handler: { (actionSheet) in
            
            self.tasksForSelectedList = self.tasksForSelectedList.sorted(byKeyPath: "dateCreated", ascending: self.dateSortOrderIsAscending)
            
            // Toggle the dateSortOrder
            self.dateSortOrderIsAscending = !self.dateSortOrderIsAscending
            
            // Change the current sort Order
            self.currentSortOrder = .Date
            
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
            })
            
        }))
        
        
        // Add a "Priority" action
        actionSheet.addAction(UIAlertAction(title: priorityString, style: .default, handler: { (actionSheet) in
            
            self.tasksForSelectedList = self.tasksForSelectedList.sorted(byKeyPath: "priority", ascending: self.prioritySortOrderIsAscending)
            
            // Toggle the prioritySortOrder
            self.prioritySortOrderIsAscending = !self.prioritySortOrderIsAscending
            
            // Change the current sort Order
            self.currentSortOrder = .Priority
            
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
            })
            
        }))
        
        // Add a "Cancel" action
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true, completion: nil)
        
    }
    
    
    //MARK:- TextField Delagete
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        // Take the "Add" action on alertViewController
        let newListAlert = self.presentedViewController as! UIAlertController
        let addAction = newListAlert.actions.first
        
        // Make the "Add" action enabled/disabled
        if ((textField.text?.lengthOfBytes(using: .utf8))! > 1 || (string.lengthOfBytes(using: .utf8) > 0 && !(string == ""))){
            addAction?.isEnabled = true
        } else {
            addAction?.isEnabled = false
        }
        
        return true;
        
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        
        // Take the "Add" action on alertViewController
        let newListAlert = self.presentedViewController as! UIAlertController
        let addAction = newListAlert.actions.first
        
        // Make the "Add" action disabled
        addAction?.isEnabled = false
        
        return true
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskCell
        
        // Get the corresponding task, depending upon  whether we are searching or not
        let task : Task
        if searchController.isActive && searchController.searchBar.text != "" {
            task = filteredTasks[indexPath.row]
        } else {
            task = tasksForSelectedList[indexPath.row]
        }
        
        // Set the name
        cell.labelName.text = task.name
        
        // Set the date
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateStyle = .medium
        cell.labelDate.text = formatter.string(from: list.dateCreated)
        
        // Set the priority color
        switch task.priority {
        case 1: // Low priority
            cell.priorityView.backgroundColor = UIColor(netHex: 0x2ECC71)
            break
        case 2: // Medium priority
            cell.priorityView.backgroundColor = UIColor(netHex: 0xF1C40F)
            break
        case 3: // High priority
            cell.priorityView.backgroundColor = UIColor(netHex: 0xE74C3C)
            break
        default:
            break
        }
        
        // Check if task is completed, and indicate via a checkmark
        cell.imageViewCheckbox.image = (task.isCompleted) ? #imageLiteral(resourceName: "checkbox_checked") : #imageLiteral(resourceName: "checkbox_unchecked")
        
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let task = tasksForSelectedList[indexPath.row]
            self.realm.beginWrite()
            self.realm.delete(task)
            try! self.realm.commitWrite()
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    
    // MARK:- TableView Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Get the selected cell, and the corresponding task
        let cell = tableView.cellForRow(at: indexPath) as! TaskCell
        
        let task : Task
        if searchController.isActive && searchController.searchBar.text != "" {
            task = filteredTasks[indexPath.row]
        } else {
            task = tasksForSelectedList[indexPath.row]
        }
        
        // Toggle its "isCompleted" state
        self.realm.beginWrite()
        task.isCompleted = !task.isCompleted
        try! self.realm.commitWrite()
        
        // Update it on the cell
        cell.imageViewCheckbox.image = (task.isCompleted) ? #imageLiteral(resourceName: "checkbox_checked") : #imageLiteral(resourceName: "checkbox_unchecked")
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        
        performSegue(withIdentifier: "ShowTaskDetails", sender: indexPath)
        
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
        case 1:
            selectedPriority = 2
        case 2:
            selectedPriority = 3
        default: break
            
        }
    }
    
    
    
    //MARK:- Segue Methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "ShowTaskDetails" {
            
            // Take the selected index path
            let selectedIndexPath = sender as! IndexPath
            
            // Take the list details view cotroller
            let taskDetailsViewController = (segue.destination as! UINavigationController).topViewController as! ListDetailsViewController
            
            // Set the type
            taskDetailsViewController.type = .TypeTask
            
            // Pass the corresponding list to the view controller
            if searchController.isActive && searchController.searchBar.text != "" {
                taskDetailsViewController.task = filteredTasks[selectedIndexPath.row]
            } else {
                taskDetailsViewController.task = tasksForSelectedList[selectedIndexPath.row]
            }
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

