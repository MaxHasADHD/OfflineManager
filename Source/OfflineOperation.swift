//
//  OfflineOperation.swift
//  OfflineManager
//
//  Created by Maximilian Litteral on 4/15/16.
//  Copyright © 2016 Maximilian Litteral. All rights reserved.
//

import Foundation

enum OperationState {
    case Ready
    case Preparing
    case Running
    case Failed
}

class OfflineOperation: NSObject, NSCoding {
    
    // Public
    let operationID: String
    let userInfo: [String: AnyObject]?
    let object: AnyObject?
    
    var state: OperationState = .Ready
    
    // MARK: - Lifecycle
    
    required init?(coder aDecoder: NSCoder) {
        guard let operationID = aDecoder.decodeObjectForKey("operationID") as? String else { return nil }
        self.operationID = operationID
        self.userInfo = aDecoder.decodeObjectForKey("userInfo") as? [String: AnyObject]
        self.object = aDecoder.decodeObjectForKey("object")
        
        super.init()
    }
    
    init(operationID: String, userInfo: [String: AnyObject]? = nil, object: AnyObject? = nil) {
        self.operationID = operationID
        self.userInfo = userInfo
        self.object = object
        
        super.init()
    }
}

extension OfflineOperation {
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(operationID, forKey: "operationID")
        
        if let userInfo = userInfo {
            aCoder.encodeObject(userInfo, forKey: "userInfo")
        }
        
        if let obj = object {
            aCoder.encodeObject(obj, forKey: "object")
        }
    }
}
