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

class TasksViewController: UITableViewController, UISearchResultsUpdating {

    var list: List!
    let realm = try! Realm()
    lazy var allTasks: Results<Task> = { self.realm.objects(Task.self) }()
    let searchController = UISearchController(searchResultsController: nil)
    var filteredTasks : Results<Task>!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Add a add button that adds a task
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewTask(_:)))
        self.navigationItem.rightBarButtonItem = addButton
        
        // Set the list's name as title
        self.title = list.name
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    var tasksForSelectedList: Results<Task> {
        get {
            return allTasks.filter("list.dateCreated == %@", list.dateCreated)
        }
    }
    
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
        
        // Add an "Add" button
        newTaskAlert.addAction(UIAlertAction(title: "Add", style: .default, handler: { (addAlertAction) in
            
            let nameTextField = newTaskAlert.textFields?.first
            
            let indexPath = IndexPath(row: self.tableView.numberOfRows(inSection: 0), section: 0)
            
            
            let newTask = Task()
            newTask.name = (nameTextField?.text)!
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
    
    
    //MARK : Table View DataSource

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
    
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredTasks = self.allTasks.filter("name CONTAINS[c] %@", searchText)
        
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }

}

