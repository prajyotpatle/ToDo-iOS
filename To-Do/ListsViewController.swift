//
//  ListsViewController.swift
//  To-Do
//
//  Created by Prajyot on 20/03/2017.
//
//

import UIKit
import RealmSwift

enum SortOrder {
    case Name
    case Date
    case Priority
}

class ListsViewController: UITableViewController, UITextFieldDelegate, UISearchResultsUpdating, UIPickerViewDataSource, UIPickerViewDelegate {

    var detailViewController: TasksViewController? = nil
    var objects = [String]()
    let realm = try! Realm()
    lazy var lists: Results<List> = { self.realm.objects(List.self) }()
    lazy var tasks: Results<Task> = { self.realm.objects(Task.self) }()
    let searchController = UISearchController(searchResultsController: nil)
    var filteredLists : Results<List>!
    var selectedPriority = 1
    var sortedLists: Results<List> {
        get {
            return lists.sorted(byKeyPath: "dateCreated", ascending: true)
        }
    }
    
    // The current sort order of the lists
    var currentSortOrder = SortOrder.Date
    
    // The ascending/descending sort orders of respective attributes
    var nameSortOrderIsAscending = true
    var dateSortOrderIsAscending = false
    var prioritySortOrderIsAscending = true

    
    // MARK:- ViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Lists"
        
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        // Add a searchController
        searchController.searchResultsUpdater = self
        searchController.searchBar.barStyle = .default
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar

        // Create bar button items
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewList(_:)))
        let sortButton = UIBarButtonItem(image: UIImage.init(named: "sort"), style: .plain, target: self, action: #selector(showSortOptions(_:)))
        
        // Add right bar button items
        self.navigationItem.rightBarButtonItems = [sortButton, addButton]
        
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? TasksViewController
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
        
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.reloadRows(at: [selectedIndexPath], with: .automatic)
        }
        
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }

    
    // MARK:- Actions

    func insertNewList(_ sender: Any) {
        
        // Show a alertController asking the new list's name
        let newListAlert = UIAlertController(title: "Add New To-Do List", message: "Enter the name of the list", preferredStyle: .alert)
        
        // Add a textField to enter the name
        newListAlert.addTextField { (nameTextFiled) in
            // Configure the textFiled
            nameTextFiled.placeholder = "Name of the list"
            nameTextFiled.clearButtonMode = .whileEditing
            nameTextFiled.borderStyle = .roundedRect
            nameTextFiled.delegate = self
        }
        
        // Add a textField to enter the priority
        newListAlert.addTextField { (priorityTextField) in
            // Configure the textFiled
            priorityTextField.placeholder = "Priority"
            priorityTextField.text = "Low"
            priorityTextField.borderStyle = .roundedRect
            priorityTextField.delegate = self
            
            // Create a pickerView
            let priorityPicker = UIPickerView()
            priorityPicker.dataSource = self
            priorityPicker.delegate = self
            
            // Create a toolbar
            let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 44))
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.prioritySelected(_:)))
            toolbar.items = [flexibleSpace, doneButton]
            
            priorityTextField.inputView = priorityPicker
            priorityTextField.inputAccessoryView = toolbar
        }
        
        // Add an "Add" button
        newListAlert.addAction(UIAlertAction(title: "Add", style: .default, handler: { (addAlertAction) in
            
            let nameTextField = newListAlert.textFields?.first
            
            let indexPath = IndexPath(row: self.tableView.numberOfRows(inSection: 0), section: 0)
            
            // Create a list and save to Realm Database
            let newList = List()
            newList.name = (nameTextField?.text)!
            newList.priority = self.selectedPriority
            self.realm.beginWrite()
            self.realm.add(newList)
            try! self.realm.commitWrite()
            self.tableView.insertRows(at: [indexPath], with: .automatic)
            
        }))
        
        // Make the "Add" button disabled by default
        newListAlert.actions.first?.isEnabled = false
        
        // Add a "Cancel" button
        newListAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // Keep the "Add" button disabled at first
        //newListAlert.actions.first?.isEnabled = false
        
        // Show the alert
        present(newListAlert, animated: true, completion: nil)
        
    }
    
    func prioritySelected(_ sender: Any) {
        
        // Dismiss the picker view
        
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
            
            self.lists = self.lists.sorted(byKeyPath: "name", ascending: self.nameSortOrderIsAscending)
            
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
            
            self.lists = self.lists.sorted(byKeyPath: "dateCreated", ascending: self.dateSortOrderIsAscending)
            
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
            
            self.lists = self.lists.sorted(byKeyPath: "priority", ascending: self.prioritySortOrderIsAscending)
            
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
    
    

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowTasks" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                
                // Get the selected List
                let list : List
                if searchController.isActive && searchController.searchBar.text != "" {
                    list = filteredLists[indexPath.row]
                } else {
                    list = lists[indexPath.row]
                }
                
                // Pass it to the TasksViewController
                let controller = (segue.destination as! UINavigationController).topViewController as! TasksViewController
                controller.list = list
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        } else if segue.identifier == "ShowListDetails" {
            
            // Take the selected index path
            let selectedIndexPath = sender as! IndexPath
            
            // Take the list details view cotroller
            let listDetailsViewController = (segue.destination as! UINavigationController).topViewController as! ListDetailsViewController
            
            // Set the type
            listDetailsViewController.type = .TypeList
            
            // Pass the corresponding list to the view controller
            if searchController.isActive && searchController.searchBar.text != "" {
                listDetailsViewController.list = filteredLists[selectedIndexPath.row]
            } else {
                listDetailsViewController.list = lists[selectedIndexPath.row]
            }
        }
    }

    // MARK: - Table View DataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredLists.count
        } else {
            return lists.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListCell", for: indexPath) as! ListCell
        
        let list : List
        if searchController.isActive && searchController.searchBar.text != "" {
            list = filteredLists[indexPath.row]
        } else {
            list = lists[indexPath.row]
        }
    
        // Set the name
        cell.labelName.text = list.name
        
        // Set the date
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateStyle = .medium
        cell.labelDate.text = formatter.string(from: list.dateCreated)
        
        // Set the incomplete tasks
        cell.labelRemainingTasks.text = String(format: "%d", incompleteTasksForList(list))
        
        // Set the priority color
        switch list.priority {
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
        
        // Return the cell after setting it up
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let list = lists[indexPath.row]
            self.realm.beginWrite()
            self.realm.delete(list)
            try! self.realm.commitWrite()
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }

    
    // MARK:- Table View Delegate

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        
        performSegue(withIdentifier: "ShowListDetails", sender: indexPath)
        
    }
    
    
    // MARK:- Text Field Delegate
    
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
    
    
    // MARK:- Helpers
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredLists = self.lists.filter("name CONTAINS[c] %@", searchText)
        
        tableView.reloadData()
    }
    
    func incompleteTasksForList(_ list: List) -> Int {
        
        return tasks.filter("list.dateCreated == %@ AND isCompleted == false", list.dateCreated).count
        
    }
    
    
    // MARK:- UISearchUpdatingDelgate
    
    func updateSearchResults(for searchController: UISearchController) {
        
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    
    // MARK:- Segue methods
    
    

}


extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
}

