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
    
    // 1 = Low, 2 = Medium, 3 = High
    dynamic var priority = 1
    
    dynamic var list: List!
    
}
