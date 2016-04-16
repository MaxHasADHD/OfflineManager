#MLOfflineManager

MLOfflineManager helps restore and retry common network operations once internet is reachable. If a network operation fails, MLOperationManager will retry when app launches or when internet is available.

##Installation
###Manual
Just drop the contents of the **Source** folder into your project. That's it!

##Instructions

###Setup
**AppDelegate.swift**
```
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Override point for customization after application launch.
    
    ...
            
    // Offline manager
    MLOfflineManager.handleOfflineOperation = self.handleOfflineOperation
    MLOfflineManager.defaultManager.startHandlingOperations()
            
    return true
}

// MARK: - MLOfflineManager
extension AppDelegate {
    func handleOfflineOperation(operation: MLOfflineOperation, fromManager: MLOfflineManager, completion: ((response: MLOperationResponse) -> Void)) {
        // Handle operations here
    }
}

```

###Add Operation
```
let operation = MLOfflineOperation(operationID: "updateStatus", userInfo: ["status": "Hello, world!"], object: nil)
MLOfflineManager.defaultManager.append(operation)
```

##TODO List
- [x] Run operation if network is reachable
- [x] Retry operations
- [ ] Run operations on specified network (WiFi/LTE)

##License
The MIT License (MIT)

Copyright (c) 2016 Maximilian Litteral

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.