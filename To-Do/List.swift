//
//  List.swift
//  To-Do
//
//  Created by Vaibhav Gote on 20/03/17.
//
//

import Foundation
import RealmSwift

class List: Object {
    
    dynamic var name = ""
    dynamic var dateCreated = Date()
    dynamic var priority = "Low"
    
}
