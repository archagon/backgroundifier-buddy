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
            
            let item1 = NSMenuItem.init(title: "Item 1", action: nil, keyEquivalent: "e")
            menu.addItem(item1)
            assert(menu.items.count - 1 == MenuItem.item1.rawValue)
            
            let item2 = NSMenuItem.init(title: "Item 2", action: nil, keyEquivalent: "f")
            menu.addItem(item2)
            assert(menu.items.count - 1 == MenuItem.item2.rawValue)
            
            let sep1 = NSMenuItem.separator()
            menu.addItem(sep1)
            assert(menu.items.count - 1 == MenuItem.separator1.rawValue)
            
            self.statusItem.menu = menu
        }
    }
}
