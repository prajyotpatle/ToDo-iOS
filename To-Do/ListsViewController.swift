//
//  ListsViewController.swift
//  To-Do
//
//  Created by Prajyot on 20/03/2017.
//
//

import UIKit
import RealmSwift

class ListsViewController: UITableViewController, UITextFieldDelegate, UISearchResultsUpdating {

    var detailViewController: TasksViewController? = nil
    var objects = [String]()
    let realm = try! Realm()
    lazy var lists: Results<List> = { self.realm.objects(List.self) }()
    lazy var tasks: Results<Task> = { self.realm.objects(Task.self) }()
    let searchController = UISearchController(searchResultsController: nil)
    var filteredLists : Results<List>!


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        lists = self.realm.objects(List.self)
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewList(_:)))
        self.navigationItem.rightBarButtonItem = addButton
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewList(_ sender: Any) {
        
        // Show a alertController asking the new list's name
        let newListAlert = UIAlertController(title: "Add New To-Do List", message: "Enter the name of the list", preferredStyle: .alert)
        
        // Add a textField to enter the name
        newListAlert.addTextField { (nameTextFiled) in
            // Configure the textFiled
            nameTextFiled.placeholder = "name of the list"
            nameTextFiled.clearButtonMode = .whileEditing
            nameTextFiled.borderStyle = .roundedRect
            nameTextFiled.delegate = self
        }
        
        // Add an "Add" button
        newListAlert.addAction(UIAlertAction(title: "Add", style: .default, handler: { (addAlertAction) in
            
            let nameTextField = newListAlert.textFields?.first
            
            let indexPath = IndexPath(row: self.tableView.numberOfRows(inSection: 0), section: 0)
            
            
            let newList = List()
            newList.name = (nameTextField?.text)!
            self.realm.beginWrite()
            self.realm.add(newList)
            try! self.realm.commitWrite()
            self.tableView.insertRows(at: [indexPath], with: .automatic)
            
        }))
        
        // Add a "Cancel" button
        newListAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // Keep the "Add" button disabled at first
        //newListAlert.actions.first?.isEnabled = false
        
        // Show the alert
        present(newListAlert, animated: true, completion: nil)
        
    }
    
    
    func tasksForList(_ list: List) -> Results<Task> {
        
        return tasks.filter("list.dateCreated == %@ AND isCompleted == false", list.dateCreated)
        
    }
    

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
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
        }
    }

    // MARK: - Table View DataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredLists.count
        }
        
        return lists.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let list : List
        if searchController.isActive && searchController.searchBar.text != "" {
            list = filteredLists[indexPath.row]
        } else {
            list = lists[indexPath.row]
        }
    
        cell.textLabel?.text = list.name
        cell.detailTextLabel?.text = String(format: "%d", tasksForList(list).count)
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
    
    
    // MARK:- Text Field Delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
//        let newListAlert = self.presentedViewController as! UIAlertController
//        let addAction = newListAlert.actions.first
//        
//        if ((range.location == 0 && range.length == 0) || (range.location == 1 && range.length == 1)) {
//            addAction?.isEnabled = true
//        }else{
//            addAction?.isEnabled = false
//        }
        
        return true;
    }
    
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredLists = self.lists.filter("name CONTAINS[c] %@", searchText)
        
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }

}

