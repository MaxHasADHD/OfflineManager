//
//  MLOfflineManager.swift
//  MLOfflineManager
//
//  Created by Maximilian Litteral on 4/15/16.
//  Copyright © 2016 Maximilian Litteral. All rights reserved.
//

import Foundation

enum MLOperationResult {
    case Success
    case Retry(interval: NSTimeInterval)
    case Failed
}

class MLOfflineManager: NSObject {
    
    // Type aliases
    typealias SuccessCompletionClosure = ((result: MLOperationResult) -> Void)
    
    // Static
    static let defaultManager = MLOfflineManager()
    static var handleOfflineOperation: ((operation: MLOfflineOperation, fromManager: MLOfflineManager, completion: SuccessCompletionClosure) -> Void)?
    
    // Public
    private(set) var reachability: Reachability?
    private(set) var name: String
    
    // Private
    private var operations: [MLOfflineOperation] = []
    
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
        let dictOperations = self.operations.map { $0.dictionaryRepresentation() }
        print("Saving \(self.operations.count) operations")
        NSUserDefaults.standardUserDefaults().setObject(dictOperations, forKey: self.name)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func loadOperations() {
        if let dictOperations = NSUserDefaults.standardUserDefaults().objectForKey(self.name) as? [[String: AnyObject]] {
            self.operations  = dictOperations.flatMap { MLOfflineOperation(dictionaryRepresentation: $0) }
            print("Loaded \(self.operations.count) operations")
        }
        else {
            print("Nothing in defaults")
        }
    }
    
    // MARK: Add / Remove operations
    
    func append(operation: MLOfflineOperation) {
        self.operations.append(operation)
        self.tryOperation(operation)
    }
    
    func tryOperation(operation: MLOfflineOperation) {
        guard reachability?.currentReachabilityStatus != .NotReachable else { return }
        
        MLOfflineManager.handleOfflineOperation?(operation: operation, fromManager: self, completion: { [weak self] (response) in
            guard let wSelf = self else { return }
            
            switch response {
            case .Success:
                print("Woohoo! Success")
                wSelf.removeOperation(operation)
                wSelf.checkForNextOperation()
            case .Retry(let interval):
                print("Will retry in \(interval) seconds")
                wSelf.wait(seconds: interval, block: {
                    wSelf.tryOperation(operation)
                })
            case .Failed:
                print("Will retry at a later time")
            }
        })
    }
    
    func removeOperation(operation: MLOfflineOperation) {
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
        guard let operation = self.operations.last else { return }
        self.tryOperation(operation)
    }
}
