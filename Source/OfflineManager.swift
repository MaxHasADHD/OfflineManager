//
//  OfflineManager.swift
//  OfflineManager
//
//  Created by Maximilian Litteral on 4/15/16.
//  Copyright © 2016 Maximilian Litteral. All rights reserved.
//

import Foundation

enum OperationResult {
    case Success
    case Retry(interval: NSTimeInterval)
    case Failed
}

class OfflineManager: NSObject {
    
    // Type aliases
    typealias SuccessCompletionClosure = ((result: OperationResult) -> Void)
    
    // Static
    static let defaultManager = OfflineManager()
    static var handleOfflineOperation: ((operation: OfflineOperation, fromManager: OfflineManager, completion: SuccessCompletionClosure) -> Void)?
    
    // Public
    private(set) var reachability: Reachability?
    private(set) var name: String
    
    /// Maximum number of operations that can run at the same time. Default is set to 0, which means there is no limit.
    var maxConcurrentOperations: Int = 0
    /// Wait time between operations. This does not effect when new operations start if maxConcurrentOperations is 0, or if the maximimum has not been reached yet. Default is 0.
    var waitTimeBetweenOperations: NSTimeInterval = 0
    
    // Private
    private var operations: [OfflineOperation] = []
    private var numberOfRunningOperations: Int = 0
    
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
        self.checkForNextOperation()
    }
    
    // MARK: Save and Load
    
    func saveOperations() {
        print("Saving \(self.operations.count) operations")
        
        let archivedData = NSKeyedArchiver.archivedDataWithRootObject(self.operations)
        NSUserDefaults.standardUserDefaults().setObject(archivedData, forKey: self.name)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func loadOperations() {
        if let data = NSUserDefaults.standardUserDefaults().objectForKey(self.name) as? NSData,
            operations = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [OfflineOperation] {
            self.operations = operations
            print("Loaded \(self.operations.count) operations")
        }
        else {
            print("Nothing in defaults")
        }
    }
    
    // MARK: Add / Remove operations
    
    func append(operation: OfflineOperation) {
        self.operations.append(operation)
        
        if self.maxConcurrentOperations == 0 ||
            self.numberOfRunningOperations != self.maxConcurrentOperations {
            self.tryOperation(operation)
        }
    }
    
    func tryOperation(operation: OfflineOperation) {
        guard reachability?.currentReachabilityStatus != .NotReachable else { return }
        
        self.numberOfRunningOperations += 1 // Increase number of running operations
        operation.state == .Running
        
        OfflineManager.handleOfflineOperation?(operation: operation, fromManager: self, completion: { [weak self] (response) in
            guard let wSelf = self else { return }
            wSelf.numberOfRunningOperations -= 1 // Decerment number of running operations
    
            switch response {
            case .Success:
                print("Woohoo! Success")
                wSelf.removeOperation(operation)
                wSelf.checkForNextOperation()
            case .Retry(let interval):
                operation.state == .Preparing
                print("Will retry in \(interval) seconds")
                wSelf.wait(seconds: interval, block: {
                    wSelf.tryOperation(operation)
                })
            case .Failed:
                operation.state == .Failed
                print("Will retry at a later time")
                wSelf.checkForNextOperation()
            }
        })
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
    
    // MARK: - Private
    
    private func wait(seconds seconds: Double, block: (() -> Void)) {
        let delay = seconds * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        
        dispatch_after(time, dispatch_get_main_queue(), { () -> Void in
            block()
        })
    }
    
    private func checkForNextOperation() {
        let operationsCount = self.operations.count
        guard operationsCount > 0 else { return print("All finished!") }
        
        for i in (0..<operationsCount).reverse() {
            guard self.maxConcurrentOperations == 0 ||
                self.numberOfRunningOperations != self.maxConcurrentOperations else { return } // Maximum number of operation are running
            let operation = self.operations[i]
            
            guard operation.state == .Ready else { continue } // Find operation that is not running
            
            if self.waitTimeBetweenOperations > 0 {
                operation.state == .Preparing
                self.wait(seconds: self.waitTimeBetweenOperations, block: { [weak self] in
                    guard let wSelf = self else { return }
                    wSelf.tryOperation(operation)
                })
                return // Wait before running
            }
            else {
                self.tryOperation(operation)
            }
        }
    }
}
