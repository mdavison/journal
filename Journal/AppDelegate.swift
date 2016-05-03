//
//  AppDelegate.swift
//  Journal
//
//  Created by Morgan Davison on 3/11/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit
import CoreData
import FBSDKCoreKit
import Fabric
import TwitterKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?
    lazy var coreDataStack = CoreDataStack()
    var twitter = JournalTwitter()
    var facebook = JournalFacebook()
    var settings: Settings?
    //var signInViewController: SignInViewController?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Override point for customization after application launch.
        setSettings()
        
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
        splitViewController.delegate = self

        let masterNavigationController = splitViewController.viewControllers[0] as! UINavigationController
        let tabBarController = masterNavigationController.viewControllers[0] as! UITabBarController
        let tabBarMasterNavController = tabBarController.viewControllers![0] as! UINavigationController
        let masterViewController = tabBarMasterNavController.viewControllers[0] as! MasterViewController
        masterViewController.managedObjectContext = coreDataStack.managedObjectContext
        masterViewController.coreDataStack = coreDataStack
        
        let tabBarCalendarNavController = tabBarController.viewControllers![1] as! UINavigationController
        let calendarViewController = tabBarCalendarNavController.viewControllers[0] as! CalendarCollectionViewController
        calendarViewController.coreDataStack = coreDataStack
        
        let tabBarSettingsNavController = tabBarController.viewControllers![2] as! UINavigationController
        let settingsViewController = tabBarSettingsNavController.viewControllers[0] as! SettingsTableViewController
        settingsViewController.coreDataStack = coreDataStack
        
        let entryNavigationController = splitViewController.viewControllers[1] as! UINavigationController
        //let entryController = entryNavigationController.topViewController as! EntryViewController
        
        let entryTabBarController = entryNavigationController.topViewController as! UITabBarController
        let entryController = entryTabBarController.viewControllers![0] as! EntryViewController
        //let entryController = (entryTabBarController.viewControllers![0] as! UINavigationController).topViewController as! EntryViewController
        
        entryController.coreDataStack = coreDataStack
        
        twitter.coreDataStack = coreDataStack
        facebook.coreDataStack = coreDataStack
        
        Fabric.with([Twitter.self])
        
        twitter.requestTweets()
        //twitter.logout()
        
        let facebookApplication = FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        facebook.requestPosts()
        //facebook.logout()

        //return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        //return true
        return facebookApplication
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        coreDataStack.saveContext()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        // Determine if user needs to enter password
        authenticate()
        
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        coreDataStack.saveContext()
    }

    // MARK: - Split view

    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
        
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? EntryViewController else { return false }
//        if topAsDetailController.detailItem == nil {
//            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
//            return true
//        }
        if topAsDetailController.entry == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }
    
    
    // MARK: - Helper Methods
    
    private func authenticate() {
        if let settings = settings {
            if let passwordRequired = settings.password_required {
                if passwordRequired == false {
                    JournalVariables.userIsAuthenticated = true
                }
            } else {
                // passwordRequired is nil
                JournalVariables.userIsAuthenticated = true
            }
        } else {
            // There are no settings yet
            JournalVariables.userIsAuthenticated = true
        }
    }
    
    private func setSettings() {
        let fetchRequest = NSFetchRequest(entityName: "Settings")
        
        do {
            if let settingsArray = try coreDataStack.managedObjectContext.executeFetchRequest(fetchRequest) as? [Settings] {
                if let setting = settingsArray.last {
                    settings = setting
                }
            }
        } catch let error as NSError {
            NSLog("Error: \(error) " + "description \(error.localizedDescription)")
        }
    }
    
}

