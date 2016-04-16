//
//  OfflineOperation.swift
//  OfflineManager
//
//  Created by Maximilian Litteral on 4/15/16.
//  Copyright © 2016 Maximilian Litteral. All rights reserved.
//

import Foundation

protocol Dictionariable {
    func dictionaryRepresentation() -> [String: AnyObject]
    init?(dictionaryRepresentation: [String: AnyObject]?)
}

struct OfflineOperation {
    let operationID: String
    let userInfo: [String: AnyObject]?
    let object: AnyObject?
}

// MARK: - Hashable & Equatable
extension OfflineOperation: Hashable {
    var hashValue: Int {
        get {
            return self.operationID.hash * (object?.hash ?? 1) * (userInfo?.description.hash ?? 1)
        }
    }
}

func ==(lhs: OfflineOperation, rhs: OfflineOperation) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

// MARK: - Dictionariable
extension OfflineOperation: Dictionariable {
    func dictionaryRepresentation() -> [String: AnyObject] {
        
        var representation: [String: AnyObject] = [
            "operationID": operationID,
        ]
        representation["userInfo"] = userInfo
        representation["object"] = object

        return representation
    }
    
    init?(dictionaryRepresentation: [String: AnyObject]?) {
        guard let values = dictionaryRepresentation else { return nil }
        if let operationID = values["operationID"] as? String {
            
            self.operationID = operationID
            self.userInfo = values["userInfo"] as? [String: AnyObject]
            self.object = values["object"]
        }
        else {
            return nil
        }
    }
}