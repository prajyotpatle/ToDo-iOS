//
//  Task.swift
//  To-Do
//
//  Created by Vaibhav Gote on 20/03/17.
//
//

import Foundation
import RealmSwift

class Task: Object {
    
    dynamic var name = ""
    dynamic var dateCreated = Date()
    dynamic var isCompleted = false
    dynamic var priority = "Low"
    dynamic var list: List!
    
}
