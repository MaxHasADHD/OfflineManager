//
//  OfflineManager.swift
//  OfflineManager
//
//  Created by Maximilian Litteral on 4/15/16.
//  Copyright © 2016 Maximilian Litteral. All rights reserved.
//

import Foundation

class OfflineManager: NSObject {
    
    // Type aliases
    typealias SuccessCompletionClosure = ((success: Bool) -> Void)
    
    // Static
    static let defaultManager = OfflineManager()
    static var handleOfflineOperation: ((operation: OfflineOperation, fromManager: OfflineManager, completion: SuccessCompletionClosure) -> Void)?
    
    // Public
    private(set) var reachability: Reachability?
    private(set) var name: String
    
    // Private
    private var operations: [OfflineOperation] = []
    
    // MARK: - Lifecycle
    
    convenience init?(name: String) {
        guard name != "DefaultOfflineManager" else { return nil }
        self.init()
        self.name = name
    }
    
    override init() {
        self.name = "DefaultOfflineManager"
        
        super.init()
        
        self.loadOperations()
        
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
            
            reachability!.whenReachable = { reachability in
                // this is called on a background thread, but UI updates must
                // be on the main thread, like this:
                dispatch_async(dispatch_get_main_queue()) {
                    if reachability.isReachableViaWiFi() {
                        print("Reachable via WiFi")
                    } else {
                        print("Reachable via Cellular")
                    }
                }
            }
            reachability!.whenUnreachable = { reachability in
                // this is called on a background thread, but UI updates must
                // be on the main thread, like this:
                dispatch_async(dispatch_get_main_queue()) {
                    print("Not reachable")
                }
            }
        }
        catch let error as NSError {
            print("Unable to create Reachability: \(error)")
        }
    }
    
    deinit {
        self.reachability?.stopNotifier()
        // Save operations?
    }
    
    // MARK: - Actions
    
    func startHandlingOperations() {
        if reachability?.currentReachabilityStatus != .NotReachable {
            // Perform last operation
            guard let operation = self.operations.last else { return }
            OfflineManager.handleOfflineOperation?(operation: operation, fromManager: self, completion: { (success) in
                print("Woohoo! Operation complete. Now removing it")
                self.removeOperation(operation)
            })
        }
    }
    
    // MARK: Save and Load
    
    func saveOperations() {
        let dictOperations = self.operations.map { $0.dictionaryRepresentation() }
        print("Saving \(self.operations.count) operations")
        NSUserDefaults.standardUserDefaults().setObject(dictOperations, forKey: self.name)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func loadOperations() {
        if let dictOperations = NSUserDefaults.standardUserDefaults().objectForKey(self.name) as? [[String: AnyObject]] {
            self.operations  = dictOperations.flatMap { OfflineOperation(dictionaryRepresentation: $0) }
            print("Loaded \(self.operations.count) operations")
        }
        else {
            print("Nothing in defaults")
        }
    }
    
    // MARK: Add / Remove operations
    
    func append(operation: OfflineOperation) {
        self.operations.append(operation)
        
        if reachability?.currentReachabilityStatus != .NotReachable {
            print("connected")
            OfflineManager.handleOfflineOperation?(operation: operation, fromManager: self, completion: { (success) in
                print("Woohoo! Operation complete. Now removing it")
                self.removeOperation(operation)
            })
        }
    }
    
    func removeOperation(operation: OfflineOperation) {
        if let last = self.operations.last where last == operation {
            self.operations.removeLast()
        }
        else {
            guard let index = self.operations.indexOf(operation) else { return }
            self.operations.removeAtIndex(index)
        }
    }
}
