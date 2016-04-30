//
//  LoadingView.swift
//  HueKit
//
//  Created by Goktug Yilmaz on 02/06/15.
//  Copyright (c) 2015 Goktug Yilmaz. All rights reserved.
//

import UIKit

public struct LoadingView {

    public struct Settings {
        public static var BackgroundColor = UIColor(patternImage: UIImage(named: "stardust")!)
        public static var ActivityColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1.0)
        public static var TextColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0)
        public static var FontName = "System"
        public static var SuccessIcon = "happy_face"
        public static var FailIcon = "sad_face"
        public static var SuccessText = "Hue Bridges found"
        public static var FailText = "No Hue Bridges found"
        public static var SuccessColor = UIColor(red: 68/255, green: 118/255, blue: 4/255, alpha: 1.0)
        public static var FailColor = UIColor(red: 255/255, green: 75/255, blue: 56/255, alpha: 1.0)
        public static var ActivityWidth = UIScreen.ScreenWidth / Settings.WidthDivision
        public static var ActivityHeight = ActivityWidth / 3
        public static var WidthDivision: CGFloat {
            get {
                if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
                    return  3.5
                } else {
                    return 1.6
                }
            }
        }
    }
    
    private static var instance: LoadingView?
    private static var hidingInProgress = false
    private static var updatingInProgress = false

    /// Disable UI stops users touch actions until LoadingView is hidden. Return success status
    public static func show(text: String, disableUI: Bool) -> Bool {
        guard instance == nil else {
            print("LoadingView: You still have an active activity, please stop that before creating a new one")
            return false
        }
        
        guard Utils.shared.topViewController() != nil else {
            print("LoadingView Error: You don't have any views set. You may be calling them in viewDidLoad. Try viewDidAppear instead.")
            return false
        }
        // Separate creation from showing
        instance = LoadingView(text: text, disableUI: disableUI)
        dispatch_async(dispatch_get_main_queue()) {
            instance?.showLoadingView()
        }
        return true
    }
    
    public static func showWithDelay(text: String, disableUI: Bool, seconds: Double) -> Bool {
        let showValue = show(text, disableUI: disableUI)
        delay(seconds) { () -> () in
            hide(success: true, animated: false)
        }
        return showValue
    }
    
    /// Returns success status
    public static func hide(success success: Bool? = nil, animated: Bool = false) -> Bool {
        guard instance != nil else {
            print("LoadingView: You don't have an activity instance")
            return false
        }
        
        guard hidingInProgress == false else {
            print("LoadingView: Hiding already in progress")
            return false
        }
        
        if !NSThread.currentThread().isMainThread {
            dispatch_async(dispatch_get_main_queue()) {
                instance?.hideLoadingView(success: success, animated: animated)
            }
        } else {
            instance?.hideLoadingView(success: success, animated: animated)
        }
        
        return true
    }

    /// Updates the message and allows expanding the window for more information
    public static func update(newText: String, animated: Bool = false) -> Bool {
        guard instance != nil else {
            print("LoadingView: You don't have an activity instance")
            return false
        }

        guard updatingInProgress == false else {
            print("LoadingView: Updating already in progress")
            return false
        }

        if !NSThread.currentThread().isMainThread {
            dispatch_async(dispatch_get_main_queue()) {
                instance?.updateLoadingView(newText, animated: animated)
            }
        } else {
            instance?.updateLoadingView(newText, animated: animated)
        }

        return true
    }


    private static func delay(seconds: Double, after: ()->()) {
        let queue = dispatch_get_main_queue()
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
        dispatch_after(time, queue, after)
    }
    
    private class LoadingView: UIView {
        var textLabel: UILabel!
        var activityView: UIActivityIndicatorView!
        var icon: UILabel!

        var imageView: UIImageView!
        var UIDisabled = false
        
        convenience init(text: String, disableUI: Bool) {
            self.init(frame: CGRect(x: 0, y: 0, width: Settings.ActivityWidth, height: Settings.ActivityHeight))
            center = CGPoint(x: UIScreen.mainScreen().bounds.midX, y: UIScreen.mainScreen().bounds.midY)
            autoresizingMask = [.FlexibleTopMargin, .FlexibleLeftMargin, .FlexibleBottomMargin, .FlexibleRightMargin]
            backgroundColor = Settings.BackgroundColor
            alpha = 1
            layer.cornerRadius = 8
            createShadow()
            
            let yPosition = frame.height/2 - 20
            
            activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
            activityView.frame = CGRect(x: 10, y: yPosition, width: 40, height: 40)
            activityView.color = Settings.ActivityColor
            activityView.startAnimating()
            activityView.viewForBaselineLayout().backgroundColor = UIColor(patternImage: UIImage(named: "stardust")!)


            textLabel = UILabel(frame: CGRect(x: 60, y: yPosition, width: Settings.ActivityWidth - 70, height: 40))
            textLabel.textColor = Settings.TextColor
            textLabel.font = UIFont(name: Settings.FontName, size: 30)
            textLabel.adjustsFontSizeToFitWidth = true
            textLabel.minimumScaleFactor = 0.1
            textLabel.textAlignment = NSTextAlignment.Center
            textLabel.text = text
            
            if disableUI {
                UIApplication.sharedApplication().beginIgnoringInteractionEvents()
                UIDisabled = true
            }
        }
        
        func showLoadingView() {
            addSubview(activityView)
            addSubview(textLabel)
            
            Utils.shared.topViewController()!.view.addSubview(self)
        }
        
        func createShadow() {
            layer.shadowPath = createShadowPath().CGPath
            layer.masksToBounds = false
            layer.shadowColor = UIColor.blackColor().CGColor
            layer.shadowOffset = CGSizeMake(0, 0)
            layer.shadowRadius = 5
            layer.shadowOpacity = 0.5
        }
        
        func createShadowPath() -> UIBezierPath {
            let myBezier = UIBezierPath()
            myBezier.moveToPoint(CGPoint(x: -3, y: -3))
            myBezier.addLineToPoint(CGPoint(x: frame.width + 3, y: -3))
            myBezier.addLineToPoint(CGPoint(x: frame.width + 3, y: frame.height + 3))
            myBezier.addLineToPoint(CGPoint(x: -3, y: frame.height + 3))
            myBezier.closePath()
            return myBezier
        }
        
        func hideLoadingView(success success: Bool?, animated: Bool) {
            hidingInProgress = true
            if UIDisabled {
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
            }
            
            var animationDuration: Double = 0
            if success != nil {
                if success! {
                    animationDuration = 0.5
                } else {
                    animationDuration = 1
                }
            }


            imageView = UIImageView(image:UIImage(named: Settings.FailIcon))
            imageView.frame = CGRect(x: 10, y: frame.height/2 - 20, width: 40, height: 40)
            imageView.viewForBaselineLayout().backgroundColor = UIColor(patternImage: UIImage(named: "stardust")!)

            if animated {
                textLabel.fadeTransition(animationDuration)
            }
            
            if success != nil {
                if success! {
                    imageView.frame = CGRect(x: 10, y: frame.height/2 - 20, width: 40, height: 40)
                    imageView.image = UIImage(named: Settings.SuccessIcon)
                    imageView.viewForBaselineLayout().backgroundColor = UIColor(patternImage: UIImage(named: "stardust")!)
                    textLabel.text = Settings.SuccessText
                } else {
                    imageView.frame = CGRect(x: 10, y: frame.height/2 - 20, width: 40, height: 40)
                    imageView.image = UIImage(named: Settings.FailIcon)
                    imageView.viewForBaselineLayout().backgroundColor = UIColor(patternImage: UIImage(named: "stardust")!)
                    textLabel.text = Settings.FailText

                }
            }

            addSubview(imageView)

            if animated {
                imageView.alpha = 0
                activityView.stopAnimating()
                UIView.animateWithDuration(animationDuration, animations: {
                    self.imageView.alpha = 1
                    }, completion: { (value: Bool) in
                        self.callSelectorAsync(#selector(UIView.removeFromSuperview), delay: animationDuration)
                        instance = nil
                        hidingInProgress = false
                })
            } else {
                activityView.stopAnimating()
                self.callSelectorAsync(#selector(UIView.removeFromSuperview), delay: animationDuration)
                instance = nil
                hidingInProgress = false
            }
        }

        func updateLoadingView(newText: String, animated: Bool) {
            updatingInProgress = true
            if UIDisabled {
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
            }

            let animationDuration: Double = 0.5

            imageView = UIImageView(image:UIImage(named: Settings.FailIcon))
            imageView.frame = CGRect(x: 10, y: frame.height/2 - 20, width: 40, height: 40)
            imageView.viewForBaselineLayout().backgroundColor = UIColor(patternImage: UIImage(named: "stardust")!)


            //Animation might not work, check with and without this in place
            if animated {
                textLabel.fadeTransition(animationDuration)
                textLabel.text = newText
                updatingInProgress = false

            } else {
                textLabel.text = newText
                updatingInProgress = true

            }

        }

    }
}

private extension UIView {
    /// Extension: insert view.fadeTransition right before changing content
    func fadeTransition(duration: CFTimeInterval) {
        let animation: CATransition = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.type = kCATransitionFade
        animation.duration = duration
        self.layer.addAnimation(animation, forKey: kCATransitionFade)
    }
}

private extension NSObject {
    func callSelectorAsync(selector: Selector, delay: NSTimeInterval) {
        let timer = NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: selector, userInfo: nil, repeats: false)
        NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
    }
}

private extension UIScreen {
    class var Orientation: UIInterfaceOrientation {
        get {
            return UIApplication.sharedApplication().statusBarOrientation
        }
    }
    class var ScreenWidth: CGFloat {
        get {
            if UIInterfaceOrientationIsPortrait(Orientation) {
                return UIScreen.mainScreen().bounds.size.width
            } else {
                return UIScreen.mainScreen().bounds.size.height
            }
        }
    }
    class var ScreenHeight: CGFloat {
        get {
            if UIInterfaceOrientationIsPortrait(Orientation) {
                return UIScreen.mainScreen().bounds.size.height
            } else {
                return UIScreen.mainScreen().bounds.size.width
            }
        }
    }
}

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
