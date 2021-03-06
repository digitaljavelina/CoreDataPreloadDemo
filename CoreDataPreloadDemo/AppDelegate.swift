//
//  AppDelegate.swift
//  CoreDataPreloadDemo
//
//  Created by Simon Ng on 13/5/15.
//  Copyright (c) 2015 AppCoda. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    // parse CSV file
    
    func parseCSV(contentsofURL: NSURL, encoding: NSStringEncoding) -> [(name: String, detail: String, price: String)]? {
        
        // load the CSV file and parse it
        
        let delimiter = ","
        var items: [(name: String, detail: String, price: String)]?
        
        do {
            let content = try String(contentsOfURL: contentsofURL, encoding: encoding)
            items = []
            let lines: [String] = content.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet()) as [String]
            
            for line in lines {
                var values: [String] = []
                if line != "" {
                    
                    // for a line with double quotes, use NSScanner to perform the parsing
                    
                    if line.rangeOfString("\"") != nil {
                        var textToScan: String = line
                        var value: NSString?
                        var textScanner: NSScanner = NSScanner(string: textToScan)
                        while textScanner.string != "" {
                            if (textScanner.string as NSString).substringToIndex(1) == "\"" {
                                textScanner.scanLocation += 1
                                textScanner.scanUpToString("\"", intoString: &value)
                                textScanner.scanLocation += 1
                            } else {
                                textScanner.scanUpToString(delimiter, intoString: &value)
                            }
                            
                            // store the value into the values array
                            
                            values.append(value as! String)
                            
                            // retrieve the unscanned remainder of the String
                            
                            if textScanner.scanLocation < textScanner.string.characters.count {
                                textToScan = (textScanner.string as NSString).substringFromIndex(textScanner.scanLocation + 1)
                            } else {
                                textToScan = ""
                            }
                            
                            textScanner = NSScanner(string: textToScan)
                        }
                        
                        // for a line without double quotes, simply separate the string by using the delimeter (e.g., comma)
                        
                    } else {
                        values = line.componentsSeparatedByString(delimiter)
                    }
                    
                    // put the values into the tuple and add it to the items array
                    
                    let item = (name: values[0], detail: values[1], price: values[2])
                    items?.append(item)
                }
            }
            
        } catch {
            print(error)
            
        }
        
            return items
    }
    
    func preloadData() {
        // load the data file or just return if it cannot be found
        
        // use this line to pull from a local csv
        // guard let contentsOfURL = NSBundle.mainBundle().URLForResource("menudata", withExtension: "csv") else {
        
        // use this line to pull from a remote csv
        guard let remoteURL = NSURL(string: "https://googledrive.com/host/0ByZhaKOAvtNGTHhXUUpGS3VqZnM/menudata.csv") else {
            return
        }
        
        // remove all items before preloading
        
        removeData()
        
        // use "contentsofURL" instead of "remoteURL" for local csv
        if let items = parseCSV(remoteURL, encoding: NSUTF8StringEncoding) {
            
            // preload the menu items
            
            for item in items {
                let menuItem = NSEntityDescription.insertNewObjectForEntityForName("MenuItem", inManagedObjectContext: managedObjectContext) as! MenuItem
                menuItem.name = item.name
                menuItem.detail = item.detail
                menuItem.price = (item.price as NSString).doubleValue
                
                do {
                    try managedObjectContext.save()
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func removeData() {
        // remove the existing items
        
        let fetchRequest = NSFetchRequest(entityName: "MenuItem")
        
        do {
            let menuItems = try managedObjectContext.executeFetchRequest(fetchRequest) as! [MenuItem]
            for menuItem in menuItems {
                managedObjectContext.deleteObject(menuItem)
            }
        } catch {
            print(error)
        }
    }


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // print app documents directory to console
        
        print(applicationDocumentsDirectory.path)
        
        /* only preload data from CSV file once for local CSV
        
        let defaults = NSUserDefaults.standardUserDefaults()
        let isPreloaded = defaults.boolForKey("isPreloaded")
        if !isPreloaded {
            preloadData()
            defaults.setBool(true, forKey: "isPreloaded")
        } */
        
        // preload data every launch if csv is remote
        
        preloadData()
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
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
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.appcoda.CoreDataDemo" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
        }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("CoreDataDemo", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("CoreDataDemo.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
        }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }

}

