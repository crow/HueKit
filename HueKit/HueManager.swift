//
//  HueManager.swift
//  HueKit
//
//  Created by David Crow on 1/22/16.
//  Copyright © 2016 David Crow. All rights reserved.
//

import UIKit
import HueSDK_iOS


public extension PHLight {

    public func isInGroup(groupName:String) -> Bool {

        return true
    }
}

/**
 * HueKit
 *
 * Simple Hue wrapper for simple Hue applications
 *
 */
public class HueManager: NSObject {

    public static let shared = HueManager()

    public let hueHeartBeatInterval: Float = 0.5

    public let transitionTime: Float = 0.0

    public let phHueSDK: PHHueSDK = PHHueSDK()

    public var lights: [NSString: PHLight] = [NSString: PHLight]()

    let savedBridges:Dictionary = [String:String]()
    let HueKitBridgeKey = "huekit-last-bridge-key"

    var strobeTimer: NSTimer?

    var bridgeSearch: PHBridgeSearching = PHBridgeSearching(upnpSearch: true, andPortalSearch: true, andIpAdressSearch: true)
    public let notificationManager = PHNotificationManager.defaultManager()

    public override init() {
        super.init()

        phHueSDK.startUpSDK()
        phHueSDK.enableLogging(true)
        registerForNotifications()
    }


// MARK: - Connection and Bridge Management

    // Search for beidges needs to be called before HueManager begins searching for bridges
    public func searchForBridges () {
//        // No need for heartbeat while searching for bridge
//        disableLocalHeartbeat()

        searchForBridgesSimulatorRedirect()

//        LoadingView.show("Searching for Hue Bridges", disableUI: true)
//
//        bridgeSearch.startSearchWithCompletionHandler { (bridgesFound: [NSObject : AnyObject]!) -> Void in
//
//            if (bridgesFound.count <= 0) {
//                // Show the push button view
//                LoadingView.hide(success: bridgesFound.count > 0, animated: true)
//                self.showRetryPromptSheet("No Hue Bridges Found", message: "Try checking your WiFi connection")
//
//                return
//            }
//
//            /**
//            Only checks the first hub. A single hub can support up to 50 lights, this is more than
//            enough for the vast majority of use cases. This functionality can be improved later, but will
//            require a selection mechanism to appear on the UI. This could be accomplished with a series 
//            of prompts, a tableview, etc. This wrapper is intended for basic use cases.
//            */
//            if let ip = bridgesFound?[bridgesFound!.keys.first!] where ip as? String != nil {
//
//                self.phHueSDK.setBridgeToUseWithId("HueBridge", ipAddress: ip as? String)
//
//                self.phHueSDK.startPushlinkAuthentication()
//
//                // Show the push button view
//                LoadingView.hide(success: bridgesFound.count > 0, animated: true)
//            }
//        }
    }

    // Search for beidges needs to be called before HueManager begins searching for bridges
    public func searchForBridgesSimulatorRedirect() {
        // No need for heartbeat while searching for bridge
        disableLocalHeartbeat()

        LoadingView.show("Searching for Hue Bridges", disableUI: true)


        //172.16.69.168 work
        //192.168.0.2 home
        self.phHueSDK.setBridgeToUseWithId("HueBridge", ipAddress:"172.16.69.168")

        self.phHueSDK.startPushlinkAuthentication()

        // Show the push button view
        LoadingView.hide(success: true, animated: true)

    }

    func disconnectBridges () {
        self.phHueSDK.disableLocalConnection()
    }

    /*
     * Called every heartbeat interval upon successful connection
     */
    func localConnection () {
        /*
         * Update array of lights for display in table view
         * this is necessary to properly respond to a user manually
         * switching lights on/off. Polling sucks but is required here.
         */
        updateLightsArray()
    }

    func noLocalConnection () {
        // TODO: Give prop
        /**
         Authentication failed because we couldn't connect to the bridge due to connectivity issues, inform
         the user about this and tell him to resolve any connectivity issues (connect to the right wireless
         networkfor example)
         */
        showRetryPromptSheet("No Hue Bridges Found", message: "Try checking your WiFi connection")
    }

    func notAuthenticated () {
        /**
         Not authenticated, start the pushlink process
         */
    }

    func authenticationSuccess () {
        enableLocalHeartbeat()

        LoadingView.hide(success: true, animated: true)
    }

    func authenticationFailed () {
        /**
         Authentication failed because time limit was reached, inform the user about this and let him try again
         */

        LoadingView.hide(success: false, animated: true)

        showRetryPromptSheet("Authentication Failed", message: "Push button authentication timed out")
    }

    func noLocalBridge () {
        // TODO: remove this
        print("Authentication failed because the SDK has not been configured yet to connect to a specific bridge address. This is a coding error, make sure you have called [PHHueSDK setBridgeToUseWithIpAddress:macAddress:] before starting the pushlink process")
    }

    func buttonNotPressed () {
        LoadingView.show("Authenticating", disableUI: true)
    }

// MARK: - Hue Heartbeat control

    /// Starts the local heartbeat with a 10 second interval
    func enableLocalHeartbeat() {
        // Set heartbeat interval
        self.phHueSDK.setLocalHeartbeatInterval(hueHeartBeatInterval, forResourceType: RESOURCES_LIGHTS)

        // The heartbeat processing collects data from the bridge so now try to see if we have a bridge already connected
        let cache = PHBridgeResourcesReader.readBridgeResourcesCache()
        if cache?.bridgeConfiguration?.ipaddress != nil {
            // TODO: Send connecting notifcation if you end up wrapping the HueSDK
            phHueSDK.enableLocalConnection()
        } else {
            //NSUserDefaults.standardUserDefaults().setObject(<#T##value: AnyObject?##AnyObject?#>, forKey: <#T##String#>)
            searchForBridges()
        }
    }

    func disableLocalHeartbeat() {
        phHueSDK.disableLocalConnection()
    }

// MARK: - HueKit Core Functionality

    func updateGroup(groupName: String, lightIds: [String], completion: (() -> ())?) {

        let bridgeSendAPI = PHBridgeSendAPI()

        bridgeSendAPI.createGroupWithName(groupName, lightIds: lightIds) { (groupName, lightIds) in
            completion?()
        }

    }

    // Updates all reachable lights
    public func updateLightsArray() {
        let cache = PHBridgeResourcesReader.readBridgeResourcesCache()

        if let cacheLights = cache.lights {
            self.lights = cacheLights as! [NSString: PHLight]
        }
    }

    // Might not want to expose this, since it can't correctly forward completion handler
    // Updates all reachable lights with specified state
    public func updateLights(lightState:PHLightState) {
//        let cache = PHBridgeResourcesReader.readBridgeResourcesCache()
//        let bridgeSendAPI = PHBridgeSendAPI()
//
//        // remove all light objects, so only fresh objects are present
//        lights.removeAll()
//
//        for light in cache.lights.values {
//            // don't update state of non-reachable lights
//
//            if light.lightState!.reachable == 0 {
//                continue
//            }
//
//            lights.append(light as! HKLight)
//
//            let lightState = PHLightState()
//
//            // Send lightstate to light
//            bridgeSendAPI.updateLightStateForId(light.identifier, withLightState: lightState, completionHandler: { (errors: [AnyObject]!) -> () in
//
//                if errors != nil {
//                    let message = String(format: NSLocalizedString("Errors %@", comment: ""), errors)
//                    NSLog("Response: \(message)")
//                }
//            })
//        }
    }

    // Updates specified light with specified state
    public func updateLight(light:PHLight, lightState:PHLightState, completion: ((errors:[AnyObject]?)->())?) {
        let bridgeSendAPI = PHBridgeSendAPI()

        if light.lightState!.reachable == 0 {
            return
        }

        // Set transition time to exposed transition time (defaults to minimum of 0)
        lightState.transitionTime = self.transitionTime

        // Send lightstate to light
        bridgeSendAPI.updateLightStateForId(light.identifier, withLightState: lightState, completionHandler: { (errors: [AnyObject]!) -> () in

            if errors != nil {
                let message = String(format: NSLocalizedString("Errors %@", comment: ""), errors)
                NSLog("Response: \(message)")
                completion?(errors: errors)
            }

            completion?(errors: nil)
        })
    }

    // Strobes lights with lightState at strobeRate times per second (should not exceed 10)
    public func strobeLights (lightState:PHLightState, strobeRate:Double, completion: ((errors:[AnyObject]?)->())?)  {

        guard strobeRate > 0 else {
            return
        }

        // Invalidate the last strobe timer if it exists
        self.strobeTimer?.invalidate()

        NSTimer.schedule(repeatInterval: 1/strobeRate) { timer in
            self.strobeTimer = timer
            self.updateLights(lightState)
        }
    }

    // MARK: - Helpers

    func showRetryPromptSheet (title: String, message: String) {

        let optionMenu = UIAlertController(title: title, message: message, preferredStyle: .ActionSheet)

        let retryScanAction = UIAlertAction(title: "Retry", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            /**
             This repeats the whole search and restarts the pushlink authentication if
             one or more bridges are frond, which isn't necessary. This could
             potentially see if any bridges are available to connect to discoveredBridges
             instead of searching again. This is a little more concise.
             */
            HueManager.shared.searchForBridges()
        })

        optionMenu.addAction(retryScanAction)

        if let topViewController:UIViewController = Utils().topViewController() {
            topViewController.presentViewController(optionMenu, animated: true, completion: nil)
        }
    }

    func registerForNotifications () {
        // Connection notifications
        notificationManager.registerObject(self, withSelector: #selector(localConnection) , forNotification: LOCAL_CONNECTION_NOTIFICATION)
        notificationManager.registerObject(self, withSelector: #selector(noLocalConnection), forNotification: NO_LOCAL_CONNECTION_NOTIFICATION)
        notificationManager.registerObject(self, withSelector: #selector(notAuthenticated), forNotification: NO_LOCAL_AUTHENTICATION_NOTIFICATION)

        // Push Linking notifications
        notificationManager.registerObject(self, withSelector: #selector(HueManager.authenticationSuccess), forNotification: PUSHLINK_LOCAL_AUTHENTICATION_SUCCESS_NOTIFICATION)
        notificationManager.registerObject(self, withSelector: #selector(HueManager.authenticationFailed), forNotification: PUSHLINK_LOCAL_AUTHENTICATION_FAILED_NOTIFICATION)
        notificationManager.registerObject(self, withSelector: #selector(HueManager.noLocalConnection), forNotification: PUSHLINK_NO_LOCAL_CONNECTION_NOTIFICATION)
        notificationManager.registerObject(self, withSelector: #selector(HueManager.noLocalBridge), forNotification: PUSHLINK_NO_LOCAL_BRIDGE_KNOWN_NOTIFICATION)
        notificationManager.registerObject(self, withSelector: #selector(HueManager.buttonNotPressed), forNotification: PUSHLINK_BUTTON_NOT_PRESSED_NOTIFICATION)
    }
}

