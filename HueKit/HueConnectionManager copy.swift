//
//  HueConnectionManager.swift
//  Huebeat
//
//  Created by David Crow on 1/22/16.
//  Copyright © 2016 David Crow. All rights reserved.
//

import UIKit

/**
 * Hue wrapper
 */
public class HueConnectionManager: NSObject {

    public static let shared = HueConnectionManager()

    public let hueHeartBeatInterval: Float = 0.5

    let phHueSDK: PHHueSDK = PHHueSDK()

    public var lights: [PHLight] = [PHLight]()

    var bridgeSearch: PHBridgeSearching = PHBridgeSearching(upnpSearch: true, andPortalSearch: true, andIpAdressSearch: true)
    let notificationManager = PHNotificationManager.defaultManager()

    override init() {
        super.init()

        phHueSDK.startUpSDK()
        phHueSDK.enableLogging(true)
        registerForNotifications()
    }

    // Search for beidges needs to be called before HueConnectionManager begins searching for bridges
    func searchForBridges () {
        // No need for heartbeat while searching for bridge
        disableLocalHeartbeat()

        LoadingView.show("Searching for Hue Bridges", disableUI: true)

        bridgeSearch.startSearchWithCompletionHandler { (bridgesFound: [NSObject : AnyObject]!) -> Void in

            if (bridgesFound.count <= 0) {
                // Show the push button view
                LoadingView.hide(success: bridgesFound.count > 0, animated: true)
                self.showRetryPromptSheet("No Hue Bridges Found", message: "Try checking your WiFi connection")

                return
            }

            /**
            Only checks the first hub. A single hub can support up to 50 lights, this is more than
            enough for the vast majority of use cases. This functionality can be improved later, but will
            require a selection mechanism to appear on the UI. This could be accomplished with a series 
            of prompts, a tableview, etc.
            */
            if let ip = bridgesFound?[bridgesFound!.keys.first!] where ip as? String != nil {

                self.phHueSDK.setBridgeToUseWithId("HueBridge", ipAddress: ip as? String)

                self.phHueSDK.startPushlinkAuthentication()

                // Show the push button view
                LoadingView.hide(success: bridgesFound.count > 0, animated: true)
            }

        }
    }

    func disconnectBridges () {
        self.phHueSDK.disableLocalConnection()
    }

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
            HueConnectionManager.shared.searchForBridges()
        })

        optionMenu.addAction(retryScanAction)

        if let topViewController:UIViewController = Utils().topViewController() {
            topViewController.presentViewController(optionMenu, animated: true, completion: nil)
        }
    }


    // MARK: - Heartbeat control

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
            searchForBridges()
        }
    }

    /// Stops the local heartbeat
    func disableLocalHeartbeat() {
        phHueSDK.disableLocalConnection()
    }

    func registerForNotifications () {
        // Connection notifications
        notificationManager.registerObject(self, withSelector: #selector(localConnection) , forNotification: LOCAL_CONNECTION_NOTIFICATION)
        notificationManager.registerObject(self, withSelector: #selector(noLocalConnection), forNotification: NO_LOCAL_CONNECTION_NOTIFICATION)
        notificationManager.registerObject(self, withSelector: #selector(notAuthenticated), forNotification: NO_LOCAL_AUTHENTICATION_NOTIFICATION)

        // Push Linking notifications
        notificationManager.registerObject(self, withSelector: #selector(HueConnectionManager.authenticationSuccess), forNotification: PUSHLINK_LOCAL_AUTHENTICATION_SUCCESS_NOTIFICATION)
        notificationManager.registerObject(self, withSelector: #selector(HueConnectionManager.authenticationFailed), forNotification: PUSHLINK_LOCAL_AUTHENTICATION_FAILED_NOTIFICATION)
        notificationManager.registerObject(self, withSelector: #selector(HueConnectionManager.noLocalConnection), forNotification: PUSHLINK_NO_LOCAL_CONNECTION_NOTIFICATION)
        notificationManager.registerObject(self, withSelector: #selector(HueConnectionManager.noLocalBridge), forNotification: PUSHLINK_NO_LOCAL_BRIDGE_KNOWN_NOTIFICATION)
        notificationManager.registerObject(self, withSelector: #selector(HueConnectionManager.buttonNotPressed), forNotification: PUSHLINK_BUTTON_NOT_PRESSED_NOTIFICATION)
    }

    func updateLights() {
        let cache = PHBridgeResourcesReader.readBridgeResourcesCache()
        let bridgeSendAPI = PHBridgeSendAPI()

        // remove all light objects, so only fresh objects are present
        lights.removeAll()

        for light in cache.lights!.values {
            // don't update state of non-reachable lights

            if light.lightState!.reachable == 0 {
                continue
            }

            lights.append(light as! PHLight)

            let lightState = PHLightState()

//            if light.type.value == DIM_LIGHT.rawValue {
//                    // Lux bulbs just get a random brightness
//                    lightState.brightness = Int(arc4random()) % 254
//            } else {
//                    lightState.hue = Int(arc4random()) % maxHue
//                    lightState.brightness = 254
//                    lightState.saturation = 254
//            }

            // Send lightstate to light
            bridgeSendAPI.updateLightStateForId(light.identifier, withLightState: lightState, completionHandler: { (errors: [AnyObject]!) -> () in

                if errors != nil {
                    let message = String(format: NSLocalizedString("Errors %@", comment: ""), errors)
                    NSLog("Response: \(message)")
                }
            })
            
        }
    }


    /**
     Called every heartbeat interval upon successful connection
     */
    func localConnection () {
        updateLights()
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
}
