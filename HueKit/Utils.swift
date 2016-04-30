//
//  Utils.swift
//  HueKit
//
//  Created by David Crow on 2/1/16.
//  Copyright © 2016 David Crow. All rights reserved.
//

import UIKit

class Utils: NSObject {

    static let shared = Utils()

    internal func mainWindow () -> UIWindow {
        if let appDelegate: UIApplicationDelegate = UIApplication.sharedApplication().delegate! {
            var window: UIWindow!


            if appDelegate.respondsToSelector(Selector("window")) {
                window = appDelegate.window!
            }

            return window
        }

        return UIApplication.sharedApplication().windows.first!
    }

    func topViewController () -> UIViewController? {
        let window: UIWindow = mainWindow()
        var topController: UIViewController
        var presented: Bool = false
        var presentationStyle: UIModalPresentationStyle

        guard window.rootViewController != nil else {
            return UIViewController.init()
        }

        topController = window.rootViewController!
        presentationStyle = topController.modalPresentationStyle
        // Iterate through any presented view controllers and find the top-most presentation context
        while (topController.presentedViewController != nil) {
            presented = true
            // UIModalPresentationCurrentContext allows a view controller to use the presentation style of its modal parent.
            if (topController.presentedViewController?.modalPresentationStyle != UIModalPresentationStyle.CurrentContext) {
                presentationStyle = (topController.presentedViewController?.modalPresentationStyle)!
            }

            topController = topController.presentedViewController!
        }

        // Custom modal presentation could leave us in an unpredictable display state
        if (presented && presentationStyle == UIModalPresentationStyle.Custom) {
            print("top view controller is using a custom presentation style, returning nil");
            return nil
        }

        return topController
    }
}
