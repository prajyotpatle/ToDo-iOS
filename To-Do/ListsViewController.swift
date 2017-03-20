//
//  MasterViewController.swift
//  To-Do
//
//  Created by Prajyot on 20/03/2017.
//
//

import UIKit

class MasterViewController: UITableViewController, UITextFieldDelegate {

    var detailViewController: DetailViewController? = nil
    var objects = [String]()


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewObject(_ sender: Any) {
        
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
            
            self.objects.insert((nameTextField?.text)!, at: 0)
            let indexPath = IndexPath(row: 0, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
            
        }))
        
        // Add a "Cancel" button
        newListAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // Keep the "Add" button disabled at first
        newListAlert.actions.first?.isEnabled = false
        
        // Show the alert
        present(newListAlert, animated: true, completion: nil)
        
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = objects[indexPath.row]
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
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
        return objects.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let object = objects[indexPath.row]
        cell.textLabel!.text = object
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            objects.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        // Get the source and destination Indexes
        let sourceIndex = sourceIndexPath.row
        let destinationIndex = destinationIndexPath.row
        
        /* Remove the object from its source index and
         insert it at destination index */
        let sourceObject = objects.remove(at: sourceIndex)
        objects.insert(sourceObject, at: destinationIndex)
        
    }
    
    // MARK:- Table View Delegate

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // MARK:- Text Field Delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        //let addAction = newListAlert.actions.first
        
        // Enable or Disable the "Add" button
        //addAction?.isEnabled = (textField.text?.characters.count)! > 0
        
        return true
    }


}

