//
//  List.swift
//  To-Do
//
//  Created by Vaibhav Gote on 20/03/17.
//
//

import Foundation
import RealmSwift

enum Priority {
    case low
    case medium
    case high
}

class List: Object {
    
    // Name of the list
    dynamic var name = ""
    
    // Date on which the list was created
    dynamic var dateCreated = Date()
    
    // Priority of the list
    // 1 = Low, 2 = Medium, 3 = High
    dynamic var priority = 1
    
}
