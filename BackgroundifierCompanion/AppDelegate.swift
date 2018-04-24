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
    var menu: NSMenu!
    var preferences: Preferences?
    
    var data: (name: String, folder: String, cycling: Bool)!
    
    var currentUrl: URL { return URL.init(fileURLWithPath: (data.folder as NSString).appendingPathComponent(data.name)) }
    var originalUrl: URL { return URL.init(fileURLWithPath: (hardcodedOriginPath.path as NSString).appendingPathComponent(data.name)) }
    var bgifyURL: URL { return hardcodedBackgroundifierPath.appendingPathComponent("Contents").appendingPathComponent("MacOS").appendingPathComponent("Backgroundifier") }
    
    let conn = _CGSDefaultConnection()
    var monitor: FileChangeMonitor?
    
    // TODO: set these in preferences
    let hardcodedBackgroundifierPath = URL.init(fileURLWithPath: "/Applications/Backgroundifier.app", isDirectory: true, relativeTo: nil)
    let hardcodedOutputPath = URL.init(fileURLWithPath: "/Users/archagon/Pictures/Backgroundifier/Output", isDirectory: true, relativeTo: nil)
    let hardcodedOriginPath = URL.init(fileURLWithPath: "/Users/archagon/Pictures/Backgroundifier/Curated Art/Inspiration (Watched)", isDirectory: true, relativeTo: nil)
    let hardcodedArchivePath = URL.init(fileURLWithPath: "/Users/archagon/Pictures/Backgroundifier/Curated Art/Archive", isDirectory: true, relativeTo: nil)
    
    enum MenuItem: Int
    {
        case cycle = 0
        case separator1
        case imageName
        case separator2
        case open
        case openReal
        case archive
        case archiveKeep
        case delete
        case separator3
        case prefs
        case quit
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.statusItem.image = NSImage.init(named: NSImage.Name(rawValue: "MenuIcon"))

        createMenu: do
        {
            let menu = NSMenu.init()
            
            menu.autoenablesItems = false
            menu.delegate = self
            
            let cycleItem = NSMenuItem.init(title: "Next Image", action: #selector(clickedCycle), keyEquivalent: "c")
            menu.addItem(cycleItem)
            assert(menu.items.count - 1 == MenuItem.cycle.rawValue)
            
            let sep1 = NSMenuItem.separator()
            menu.addItem(sep1)
            assert(menu.items.count - 1 == MenuItem.separator1.rawValue)
            
            let imageNameItem = NSMenuItem.init(title: "<null>.jpg", action: nil, keyEquivalent: "")
            menu.addItem(imageNameItem)
            assert(menu.items.count - 1 == MenuItem.imageName.rawValue)
            
            let sep2 = NSMenuItem.separator()
            menu.addItem(sep2)
            assert(menu.items.count - 1 == MenuItem.separator2.rawValue)
            //sep2.isHidden = true
            
            let openItem = NSMenuItem.init(title: "🔍 Reveal Image", action: #selector(clickedOpen), keyEquivalent: "r")
            //openItem.indentationLevel = 1
            menu.addItem(openItem)
            assert(menu.items.count - 1 == MenuItem.open.rawValue)
            
            let openRealItem = NSMenuItem.init(title: "🔍 Reveal Displayed Image", action: #selector(clickedOpenDisplayed), keyEquivalent: "r")
            openRealItem.keyEquivalentModifierMask = [NSEvent.ModifierFlags.option]
            openRealItem.isAlternate = true
            //openRealItem.indentationLevel = 1
            menu.addItem(openRealItem)
            assert(menu.items.count - 1 == MenuItem.openReal.rawValue)
            
            //🗄
            let archiveItem = NSMenuItem.init(title: "🗂 Archive Image", action: #selector(clickedArchive), keyEquivalent: "a")
            //archiveItem.indentationLevel = 1
            menu.addItem(archiveItem)
            assert(menu.items.count - 1 == MenuItem.archive.rawValue)
            
            let archiveKeepItem = NSMenuItem.init(title: "🗂 Archive and Keep Image", action: #selector(clickedArchiveKeep), keyEquivalent: "a")
            archiveKeepItem.keyEquivalentModifierMask = [NSEvent.ModifierFlags.option]
            archiveKeepItem.isAlternate = true
            //archiveKeepItem.indentationLevel = 1
            menu.addItem(archiveKeepItem)
            assert(menu.items.count - 1 == MenuItem.archiveKeep.rawValue)
            
            //🚫⛔️
            let deleteItem = NSMenuItem.init(title: "🗑 Delete Image", action: #selector(clickedDelete), keyEquivalent: "d")
            //deleteItem.indentationLevel = 1
            menu.addItem(deleteItem)
            assert(menu.items.count - 1 == MenuItem.delete.rawValue)
            
            let sep3 = NSMenuItem.separator()
            menu.addItem(sep3)
            assert(menu.items.count - 1 == MenuItem.separator3.rawValue)
            
            let prefsItem = NSMenuItem.init(title: "Preferences…", action: #selector(clickedPreferences), keyEquivalent: "")
            menu.addItem(prefsItem)
            assert(menu.items.count - 1 == MenuItem.prefs.rawValue)
            
            let quitItem = NSMenuItem.init(title: "Quit", action: #selector(clickedQuit), keyEquivalent: "q")
            menu.addItem(quitItem)
            assert(menu.items.count - 1 == MenuItem.quit.rawValue)
            
            self.menu = menu
        }
        
        if let button = statusItem.button
        {
            button.action = #selector(statusBarClicked)
            button.sendAction(on: [.leftMouseDown, .rightMouseUp])
        }
        
        // AB: actually, we want to preserve the last seen image in case something changes out from under us
        //NotificationCenter.default.addObserver(forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: nil)
        //{ notification in
        //    self.refreshMenu()
        //}
        
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: nil, queue: nil)
        { n in
            if n.object as? Preferences == self.preferences
            {
                self.preferences = nil
            }
        }
        
        refreshMenu()
        initMonitor()
    }
    
    func refreshMenu()
    {
        self.data = wallpaper(forSpace: currentSpace(), display: currentDisplay())
        
        #if DEBUG
        print("Image: \(data!)")
        #endif
        
        let buffer = 15
        var truncatedString = data.name
        if truncatedString.count > buffer * 2 + 1
        {
            truncatedString =
                truncatedString[truncatedString.startIndex..<truncatedString.index(truncatedString.startIndex, offsetBy: buffer)]
                + "…"
                + truncatedString[truncatedString.index(truncatedString.endIndex, offsetBy: -buffer)..<truncatedString.endIndex]
        }
        
        self.menu.item(at: MenuItem.cycle.rawValue)?.isEnabled = data.cycling
        
        self.menu.item(at: MenuItem.imageName.rawValue)?.isEnabled = false
        //self.menu.item(at: MenuItem.imageName.rawValue)?.attributedTitle = NSAttributedString.init(string: "Test", attributes: [ NSAttributedStringKey.foregroundColor : NSColor.blue ])
        self.menu.item(at: MenuItem.imageName.rawValue)?.title = truncatedString
        self.menu.item(at: MenuItem.imageName.rawValue)?.toolTip = "\((data.folder as NSString).appendingPathComponent(data.name))"
        
        self.menu.item(at: MenuItem.open.rawValue)?.isEnabled = true
        self.menu.item(at: MenuItem.archive.rawValue)?.isEnabled = true
        self.menu.item(at: MenuItem.delete.rawValue)?.isEnabled = true
        
        self.menu.item(at: MenuItem.open.rawValue)?.isEnabled = true
        self.menu.item(at: MenuItem.openReal.rawValue)?.isEnabled = true
        self.menu.item(at: MenuItem.archive.rawValue)?.isEnabled = true
        self.menu.item(at: MenuItem.archiveKeep.rawValue)?.isEnabled = true
        self.menu.item(at: MenuItem.delete.rawValue)?.isEnabled = true
        
        disablingExceptions: do
        {
            if !currentFileExistsInCorrectDirectory()
            {
                self.menu.item(at: MenuItem.open.rawValue)?.isEnabled = false
                self.menu.item(at: MenuItem.archive.rawValue)?.isEnabled = false
                self.menu.item(at: MenuItem.archiveKeep.rawValue)?.isEnabled = false
                self.menu.item(at: MenuItem.delete.rawValue)?.isEnabled = false
            }
            
            if !originalFileExists()
            {
                self.menu.item(at: MenuItem.open.rawValue)?.isEnabled = false
                self.menu.item(at: MenuItem.archive.rawValue)?.isEnabled = false
                self.menu.item(at: MenuItem.archiveKeep.rawValue)?.isEnabled = false
            }
        }
        
        self.menu.item(at: MenuItem.prefs.rawValue)?.isEnabled = true
        self.menu.item(at: MenuItem.quit.rawValue)?.isEnabled = true
    }
    
/////////////////////////////////
// MARK: - Directory Monitoring -
/////////////////////////////////
    
    func initMonitor()
    {
        let monitoredUrl = URL.init(fileURLWithPath: "/Users/archagon/Pictures/Backgroundifier/Curated Art/Archive/monitor")
        let monitor = FileChangeMonitor.init(inDirectory: monitoredUrl)
        monitor.delegate = self
        monitor.startMonitoring()
        self.monitor = monitor
    }
}

extension AppDelegate: FileChangeMonitorDelegate
{
    func fileChangeMonitorDidObserveChange(_ directoryMonitor: FileChangeMonitor, additions: Set<URL>, deletions: Set<URL>)
    {
        for addition in additions
        {
            let success = backgroundify(addition)
            
            if success
            {
                print("Backgroundified \(addition)")
            }
            else
            {
                print("ERROR: failed to Backgroundify \(addition)")
            }
        }
        for deletion in deletions
        {
            print("Deleted \(deletion)")
        }
    }
}

///////////////////////
// MARK: - Validation -
///////////////////////

extension AppDelegate
{
    func currentFileExistsInCorrectDirectory() -> Bool
    {
        let url = currentUrl
        
        // AB: only track files which are in our assigned output directory
        if url.deletingLastPathComponent() != hardcodedOutputPath { return false }
        
        if !FileManager.default.fileExists(atPath: url.path) { return false }
        if url.hasDirectoryPath { return false }
        
        return true
    }
    
    func originalFileExists() -> Bool
    {
        let url = originalUrl
        
        if !FileManager.default.fileExists(atPath: url.path) { return false }
        if url.hasDirectoryPath { return false }
        
        return true
    }
    
    func bgifyExists() -> Bool
    {
        let url = bgifyURL
        
        if !FileManager.default.fileExists(atPath: url.path) { return false }
        if !FileManager.default.isExecutableFile(atPath: url.path) { return false }
        
        return true
    }
    
    func generateArchivePath() -> Bool
    {
        if !hardcodedArchivePath.hasDirectoryPath { return false }
        
        if !FileManager.default.fileExists(atPath: hardcodedArchivePath.path)
        {
            print("WARNING: archive directory does not exist, creating at \(hardcodedArchivePath)")
            
            do
            {
                try FileManager.default.createDirectory(at: hardcodedArchivePath, withIntermediateDirectories: true, attributes: nil)
            }
            catch
            {
                assert(false, "ERROR: \(error)")
                return false
            }
        }
        
        return true
    }
}

/////////////////////////////
// MARK: - Button Callbacks -
/////////////////////////////

extension AppDelegate
{
    @objc func statusBarClicked(sender: NSStatusBarButton)
    {
        let event = NSApp.currentEvent!
        
        if event.type == NSEvent.EventType.rightMouseUp
        {
            refreshImage()
        }
        else
        {
            refreshMenu()
            
            //self.statusItem.menu = self.menu
            self.statusItem.popUpMenu(self.menu)
            //statusItem.menu = nil
        }
    }
    
    @objc func clickedCycle(_ item: NSMenuItem)
    {
        refreshImage()
    }
    
    @objc func clickedOpen(_ item: NSMenuItem)
    {
        show(originalUrl)
    }
    
    @objc func clickedOpenDisplayed(_ item: NSMenuItem)
    {
        show(currentUrl)
    }
    
    @objc func clickedArchive(_ item: NSMenuItem)
    {
        if archive()
        {
            delete()
        }
    }
    
    @objc func clickedArchiveKeep(_ item: NSMenuItem)
    {
        let _ = archive()
    }
    
    @objc func clickedDelete(_ item: NSMenuItem)
    {
        delete()
    }
    
    @objc func clickedPreferences(_ item: NSMenuItem)
    {
        if let prefs = self.preferences
        {
            prefs.window?.makeKeyAndOrderFront(self)
            prefs.window?.orderFrontRegardless()

            return
        }
        
        let prefs = Preferences.init(windowNibName: NSNib.Name.init("Preferences"))
        
        if
            let window = prefs.window,
            let frame = self.statusItem.button?.window?.frame
        {
            window.setFrameOrigin(NSMakePoint(frame.origin.x + frame.size.width / 2.0 - window.frame.size.width / 2.0, frame.origin.y - frame.size.height - window.frame.height))
        }
        
        prefs.window?.makeKeyAndOrderFront(self)
        prefs.window?.orderFrontRegardless()
        
        self.preferences = prefs
    }
    
    @objc func clickedQuit(_ item: NSMenuItem)
    {
        NSApp.terminate(self)
    }
}

///////////////////////
// MARK: - File Calls -
///////////////////////

extension AppDelegate
{
    func show(_ url: URL)
    {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    func archive() -> Bool
    {
        if !originalFileExists() || !currentFileExistsInCorrectDirectory()
        {
            return false
        }
        
        if !generateArchivePath()
        {
            return false
        }
        
        var destinationURL = hardcodedArchivePath.appendingPathComponent(data.name)
        
        for i in 0..<1000
        {
            if FileManager.default.fileExists(atPath: destinationURL.path)
            {
                let name = (data.name as NSString).deletingPathExtension
                let ext = (data.name as NSString).pathExtension
                let newName = ("\(name) (\(i + 1))" as NSString).appendingPathExtension(ext)!
                
                destinationURL = hardcodedArchivePath.appendingPathComponent(newName)
            }
            else
            {
                break
            }
        }
        
        if FileManager.default.fileExists(atPath: destinationURL.path)
        {
            print("ERROR: too many archived duplicates, aborting")
            return false
        }
        
        do
        {
            try FileManager.default.copyItem(at: originalUrl, to: destinationURL)
        }
        catch
        {
            assert(false, "ERROR: \(error)")
            return false
        }
        
        return true
    }
    
    func delete()
    {
        var urls: [URL] = []
        
        if originalFileExists() { urls.append(originalUrl) }
        if currentFileExistsInCorrectDirectory() { urls.append(currentUrl) }
        
        refreshImage()
        
        NSWorkspace.shared.recycle(urls, completionHandler: nil)
    }
    
    func backgroundify(_ file: URL) -> Bool
    {
        if !bgifyExists()
        {
            print("ERROR: Backgroundifier executable not found at \(bgifyURL.path)")
            return false
        }

        if file.hasDirectoryPath || !FileManager.default.fileExists(atPath: file.path)
        {
            print("ERROR: image file missing")
            return false
        }
        
        let out = URL.init(fileURLWithPath: "/Users/archagon/Pictures/Backgroundifier/Curated Art/Archive/monitor/encode/\((file.lastPathComponent as NSString).deletingPathExtension).jpg")
        
        if out.hasDirectoryPath
        {
            print("ERROR: invalid image output")
            return false
        }
        
        // TODO: figure out how to expand sandbox to include output folder
        let task = Process()
        task.launchPath = bgifyURL.path
        task.arguments = ["-i", file.path, "-o", out.path, "-w", "2560", "-h", "1600"]
        task.launch()
        task.waitUntilExit()
        
        print("Exited: \(task.terminationStatus)")
        
        return task.terminationStatus == 0
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
        
        let options = space.desktopImageOptions(for: screen) ?? [:]
        
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

///////////////////////////
// MARK: - System Queries -
///////////////////////////

extension AppDelegate
{
    func displayInfo() -> NSDictionary
    {
        guard let info = CGSCopyManagedDisplaySpaces(conn) as? NSArray else
        {
            assert(false, "could not retrieve info from connection")
            return NSDictionary()
        }
        
        guard let displayInfo = info.firstObject as? NSDictionary else
        {
            assert(false, "could not retrieve display info from connection info")
            return NSDictionary()
        }
        
        return displayInfo
    }
    
    func currentSpace() -> String
    {
        let info = displayInfo()
        
        guard let currentSpaceId = (info["Current Space"] as? NSDictionary)?["uuid"] as? String else
        {
            assert(false, "could not retrieve current space ID from display info")
            return ""
        }
        
        return currentSpaceId
    }
    
    func currentDisplay() -> String
    {
        let info = displayInfo()
        
        guard let displayId = info["Display Identifier"] as? String else
        {
            assert(false, "could not retrieve display ID from display info")
            return ""
        }
        
        return displayId
    }
    
    func wallpaper(forSpace space: String, display: String) -> (name: String, folder: String, cycling: Bool)
    {
        guard let screen = NSScreen.main, let pictureUrl = NSWorkspace.shared.desktopImageURL(for: screen) else
        {
            assert(false, "could not retrieve picture URL")
            return ("", "", false)
        }
        
        let displayId = CGSGetDisplayForUUID(display as NSString)
        
        guard let picture = DesktopPictureCopyDisplayForSpace(displayId, 0, space as NSString) else
        {
            assert(false, "could not retrieve picture info")
            return ("", "", false)
        }
        defer
        {
            picture.release()
        }
        
        let pictureDict = picture.takeUnretainedValue() as NSDictionary
        
        let cycle = pictureDict["Change"] != nil
        //let random = pictureDict["Random"] as? Bool ?? false
        
        let folder = pictureUrl.hasDirectoryPath
        
        //print("\(pictureDict)")
        //print("url: \(pictureUrl)")
        //print("Cycling: \(cycle), random: \(random), folder: \(folder)")
        
        assert((!cycle && !folder) || (cycle && folder))
        
        if cycle
        {
            guard let lastName = pictureDict["LastName"] as? String else
            {
                assert(false, "could not retrieve name from picture info")
                return ("", "", false)
            }
            
            //let newChangePath = pictureDict["NewChangePath"] as? String
            if let changePath = pictureDict["ChangePath"] as? String
            {
                assert(URL.init(fileURLWithPath: changePath, isDirectory: true) == pictureUrl, "NSWorkspace and DesktopPictureCopyDisplay directory URLs differ")
            }
                
            return (lastName, pictureUrl.path, true)
        }
        else
        {
            let name = pictureUrl.lastPathComponent
            let path = pictureUrl.deletingLastPathComponent().path
            
            return (name, path, false)
        }
    }
}
