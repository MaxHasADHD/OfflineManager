//
//  AppDelegate.swift
//  OfflineManager
//
//  Created by Maximilian Litteral on 4/15/16.
//  Copyright © 2016 Maximilian Litteral. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    lazy var session: NSURLSession = {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration)
        return session
    }()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        // Offline manager
        OfflineManager.handleOfflineOperation = self.handleOfflineOperation
        OfflineManager.defaultManager.startHandlingOperations()
        
        OfflineManager.defaultManager.maxConcurrentOperations = 1
        OfflineManager.defaultManager.waitTimeBetweenOperations = 10
        
        // Add operations
        let imageURLs = [
            "http://www.contentamp.com/wp-content/uploads/2013/04/meme7.jpg",
            "http://funny-pictures-blog.com/wp-content/uploads/funny-pictures/MEME---My-EX.jpg",
            "http://memecrunch.com/meme/11HI4/thank-you/image.png"
        ]
        for imageURL in imageURLs {
            OfflineManager.defaultManager.append(OfflineOperation(operationID: "ImageDownloadOperation", userInfo: ["URLString": imageURL], object: nil))
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        OfflineManager.defaultManager.saveOperations()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

// MARK: - OfflineManager
extension AppDelegate {
    func handleOfflineOperation(operation: OfflineOperation, fromManager: OfflineManager, completion: ((result: OperationResult) -> Void)) {
        
        guard let urlString = operation.userInfo?["URLString"] as? String,
            URL = NSURL(string: urlString) else {
                completion(result: OperationResult.Failed)
                return
        }
        
        self.session.downloadTaskWithURL(URL) { (url, response, error) in
            guard error == nil else {
                completion(result: .Failed)
                return
            }
            
            guard let HTTPResponse = response as? NSHTTPURLResponse
                where HTTPResponse.statusCode == 200 else {
                    completion(result: .Failed)
                    return
            }
            
            completion(result: .Success)
        }.resume()
    }
}

