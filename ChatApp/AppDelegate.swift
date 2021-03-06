//
//  AppDelegate.swift
//  ChatApp
//
//  Created by venkat on 31/03/17.
//  Copyright © 2017 Photon Interactive. All rights reserved.
//

import UIKit
import XMPPFramework

protocol ChatDelegate {
    func newBuddyOnline(buddyName: String);
    func buddyWentOffline(buddyName: String);
    func didDisconnect();
}

protocol MessageDelegate {
    func newMessageReceived(messageContent: AnyObject);
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?;
    var xmppStream: XMPPStream?;
    var password: String?;
    var isOpen: Bool?;

    // MARK:- Delegate
    var chatDelegate:ChatDelegate?
    var messageDelegate:MessageDelegate?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true;
    }

    func applicationWillResignActive(_ application: UIApplication) {
        disconnect();
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        let isConnected = connect();
        print("\(isConnected)");
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func setupStream() {
        xmppStream = XMPPStream();
        xmppStream?.addDelegate(self, delegateQueue: DispatchQueue.main);
    }

    // MARK: - Custom
    
    func goOnline() {
        let presence: XMPPPresence = XMPPPresence.init();
        xmppStream?.send(presence);
    }
    
    func goOffline() {
        let presence: XMPPPresence = XMPPPresence.init(type: "unavailable");
        xmppStream?.send(presence);
    }

    func connect() -> Bool {
        setupStream();
        
        let defaults = UserDefaults.standard;
        let jabberID: String = defaults.value(forKey: "userID") as! String;
        let myPassword: String = defaults.value(forKey: "userPassword") as! String;
        
        if !(xmppStream?.isDisconnected())! {
            return true;
        }
        
//        if jabberID == nil || myPassword == nil {
//            return false
//        }
        
        xmppStream?.myJID = XMPPJID(string: jabberID);
        password = myPassword;
        
        do {
            try xmppStream?.connect(withTimeout: XMPPStreamTimeoutNone);
        } catch let error {
            print(error.localizedDescription);
            return false;
        }
        
        return true;
    }
    
    func disconnect() {
        goOffline();
        xmppStream?.disconnect();
    }
    
    func xmppStreamDidConnect(_ sender: XMPPStream!) {
         // connection to the server successful
        isOpen = true;
        do {
            try xmppStream?.authenticate(withPassword: password);
        } catch let error {
            print(error.localizedDescription);
        }

    }

    func xmppStreamDidAuthenticate(_ sender: XMPPStream!) {
        // authentication successful
        goOnline()
    }
    
    func xmppStream(_ sender: XMPPStream!, didReceive message: XMPPMessage!) {
        // message received
    }
    
    func xmppStream(_ sender: XMPPStream!, didReceivePresence presence: XMPPPresence!) {
        // a buddy went offline/online
        let presenceType: String = presence.type();
        let myUsername: String = sender.myJID.user
        let presenceFromUser: String = presence.from().user
        
        if presenceFromUser != myUsername {
            
            if presenceType == "available" {
                chatDelegate?.newBuddyOnline(buddyName: String(format: "%@%@%@", presenceFromUser, "jerry.local"))
            } else if presenceType == "unavailable" {
                chatDelegate?.buddyWentOffline(buddyName: String(format: "%@%@%@", presenceFromUser, "jerry.local"))
            }
            
        }
    }
    
}

