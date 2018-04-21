//
//  AppDelegate.swift
//  BackgroundifierCompanion
//
//  Created by Alexei Baboulevitch on 2018-4-21.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate
{
    var statusItem: NSStatusItem!
    
    enum MenuItem: Int
    {
        case item1 = 0
        case item2
        case separator1
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        createMenu: do
        {
            let menu = NSMenu.init()
            
            menu.autoenablesItems = false
            menu.delegate = self
            
            let item1 = NSMenuItem.init(title: "Item 1", action: #selector(queryScreen), keyEquivalent: "e")
            menu.addItem(item1)
            assert(menu.items.count - 1 == MenuItem.item1.rawValue)
            
            let item2 = NSMenuItem.init(title: "Cycle Background", action: #selector(refreshScreen), keyEquivalent: "f")
            menu.addItem(item2)
            assert(menu.items.count - 1 == MenuItem.item2.rawValue)
            
            let sep1 = NSMenuItem.separator()
            menu.addItem(sep1)
            assert(menu.items.count - 1 == MenuItem.separator1.rawValue)
            
            self.statusItem.menu = menu
        }
    }
    
    @objc func queryScreen(_ item: NSMenuItem)
    {
        let sharedWorkspace = NSWorkspace.shared
        let screens = NSScreen.screens
        
        for (i,screen) in screens.enumerated()
        {
            let img = sharedWorkspace.desktopImageURL(for: screen)
            print("BG \(i): \(img?.debugDescription ?? "nil")")
        }
        
        getImage()
    }
    
    @objc func refreshScreen(_ item: NSMenuItem)
    {
        refreshImage()
    }
    
    func getImage() -> String
    {
        let str = RetrieveBackground.background(forDesktop: 0, screen: 0)
        
        return str!
    }
    
    func refreshImage()
    {
        let space = NSWorkspace.shared
        
        guard let screen = NSScreen.main else
        {
            print("WARNING: no screen currently active")
            return
        }
        
        guard let url = space.desktopImageURL(for: screen) else
        {
            print("WARNING: no desktop image for current screen")
            return
        }
        
        guard let options = space.desktopImageOptions(for: screen) else
        {
            print("WARNING: no desktop image options for current screen")
            return
        }
        
        do
        {
            try space.setDesktopImageURL(url, for: screen, options: options)
        }
        catch
        {
            print("ERROR: \(error)")
        }
    }
}
