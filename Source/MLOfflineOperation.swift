//
//  MLOfflineOperation.swift
//  MLOfflineManager
//
//  Created by Maximilian Litteral on 4/15/16.
//  Copyright © 2016 Maximilian Litteral. All rights reserved.
//

import Foundation

protocol Dictionariable {
    func dictionaryRepresentation() -> [String: AnyObject]
    init?(dictionaryRepresentation: [String: AnyObject]?)
}

struct MLOfflineOperation {
    let operationID: String
    let userInfo: [String: AnyObject]?
    let object: AnyObject?
}

// MARK: - Hashable & Equatable
extension MLOfflineOperation: Hashable {
    var hashValue: Int {
        get {
            if let info = userInfo,
                obj = object {
                return info.description.hashValue ^ self.operationID.hashValue ^ obj.hashValue
            }
            if let info = userInfo {
                return info.description.hashValue ^ self.operationID.hashValue
            }
            else if let obj = object {
                return obj.hashValue ^ self.operationID.hashValue
            }
            
            return self.operationID.hashValue
        }
    }
}

func ==(lhs: MLOfflineOperation, rhs: MLOfflineOperation) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

// MARK: - Dictionariable
extension MLOfflineOperation: Dictionariable {
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
