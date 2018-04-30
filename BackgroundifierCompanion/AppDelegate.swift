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
    
    var currentUrl: URL? { return URL.init(fileURLWithPath: (data.folder as NSString).appendingPathComponent(data.name)) }
    var originalUrl: URL? { return AppDelegate.urlForKey(.sourcePath)?.appendingPathComponent(data.name) }
    
    let conn = _CGSDefaultConnection()
    var monitor: FileChangeMonitor?
    var desktopHasBeenToggled: Bool = false
    
    enum MenuItem: Int
    {
        case cycle = 0
        case separator1
        case imageName
        case separator2
        case open
        case openReal
        case favorite
        case archive
        case archiveKeep
        case delete
        case separator3
        case dock
        case desktop
        case separator4
        case prefs
        case quit
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        if !UserDefaults.standard.bool(forKey: Preferences.DefaultsKeys.firstLaunch.rawValue)
        {
            if
                let backgroundifierPath = URL.init(string: "/")?.appendingPathComponent("Applications").appendingPathComponent("Backgroundifier.app"),
                FileManager.default.fileExists(atPath: backgroundifierPath.path)
            {
                UserDefaults.standard.set(backgroundifierPath.absoluteString, forKey: Preferences.DefaultsKeys.backgroundifierPath.rawValue)
            }
            
            UserDefaults.standard.set(true, forKey: Preferences.DefaultsKeys.firstLaunch.rawValue)
            UserDefaults.standard.synchronize()
        }
        
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.statusItem.image = NSImage.init(named: NSImage.Name(rawValue: "MenuIcon"))

        createMenu: do
        {
            let menu = NSMenu.init()
            
            menu.autoenablesItems = false
            menu.delegate = self
            
            let cycleItem = NSMenuItem.init(title: "Next Image", action: #selector(clickedCycle), keyEquivalent: "n")
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
            openItem.toolTip = "Shows the source image in the Finder."
            menu.addItem(openItem)
            assert(menu.items.count - 1 == MenuItem.open.rawValue)
            
            let openRealItem = NSMenuItem.init(title: "🔍 Reveal Wallpaper", action: #selector(clickedOpenDisplayed), keyEquivalent: "r")
            openRealItem.keyEquivalentModifierMask = [NSEvent.ModifierFlags.option]
            openRealItem.isAlternate = true
            //openRealItem.indentationLevel = 1
            openRealItem.toolTip = "Shows the wallpaper image in the Finder."
            menu.addItem(openRealItem)
            assert(menu.items.count - 1 == MenuItem.openReal.rawValue)
            
            let favoriteItem = NSMenuItem.init(title: "⭐️ Favorite Image", action: #selector(clickedFavorite), keyEquivalent: "f")
            //openRealItem.indentationLevel = 1
            favoriteItem.toolTip = "Adds a tag to the source image to mark it as a favorite."
            menu.addItem(favoriteItem)
            assert(menu.items.count - 1 == MenuItem.favorite.rawValue)
            
            //🗄
            let archiveItem = NSMenuItem.init(title: "🗂 Archive Image", action: #selector(clickedArchive), keyEquivalent: "a")
            //archiveItem.indentationLevel = 1
            archiveItem.toolTip = "Deletes the wallpaper image and moves the source image to the Archive directory."
            menu.addItem(archiveItem)
            assert(menu.items.count - 1 == MenuItem.archive.rawValue)
            
            let archiveKeepItem = NSMenuItem.init(title: "🗂 Archive and Keep Image", action: #selector(clickedArchiveKeep), keyEquivalent: "a")
            archiveKeepItem.keyEquivalentModifierMask = [NSEvent.ModifierFlags.option]
            archiveKeepItem.isAlternate = true
            //archiveKeepItem.indentationLevel = 1
            archiveKeepItem.toolTip = "Copies the source image to the Archive directory."
            menu.addItem(archiveKeepItem)
            assert(menu.items.count - 1 == MenuItem.archiveKeep.rawValue)
            
            //🚫⛔️
            let deleteItem = NSMenuItem.init(title: "🗑 Delete Image", action: #selector(clickedDelete), keyEquivalent: "d")
            //deleteItem.indentationLevel = 1
            deleteItem.toolTip = "Moves the wallpaper and source images to the Trash."
            menu.addItem(deleteItem)
            assert(menu.items.count - 1 == MenuItem.delete.rawValue)
            
            let sep3 = NSMenuItem.separator()
            menu.addItem(sep3)
            assert(menu.items.count - 1 == MenuItem.separator3.rawValue)
            
            let dockItem = NSMenuItem.init(title: "Refresh Wallpaper Cache", action: #selector(clickedDock), keyEquivalent: "")
            dockItem.toolTip = "Restarts the Dock. It seems that new wallpapers sometimes won't appear in rotation until this is done."
            menu.addItem(dockItem)
            assert(menu.items.count - 1 == MenuItem.dock.rawValue)
            
            let desktopItem = NSMenuItem.init(title: "Toggle Desktop Icons", action: #selector(clickedDesktop), keyEquivalent: "")
            desktopItem.toolTip = "Shows/hides the Desktop icons for better wallpaper visibility. Restarts the Finder in the process. Takes a few seconds to execute."
            menu.addItem(desktopItem)
            assert(menu.items.count - 1 == MenuItem.desktop.rawValue)
            
            let sep4 = NSMenuItem.separator()
            menu.addItem(sep4)
            assert(menu.items.count - 1 == MenuItem.separator4.rawValue)
            
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
            button.sendAction(on: [.leftMouseDown, .rightMouseDown])

            let trackingArea = NSTrackingArea.init(rect: button.bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
            button.addTrackingArea(trackingArea)
        }
        
        // AB: actually, we want to preserve the last seen image in case something changes out from under us
        //NotificationCenter.default.addObserver(forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: nil)
        //{ notification in
        //    self.refreshMenu()
        //}
        
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: nil)
        { [weak self] n in
            self?.refreshMenu()
            self?.enableMonitor(UserDefaults.standard.bool(forKey: Preferences.DefaultsKeys.conversionEnabled.rawValue))
        }
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
        self.menu.item(at: MenuItem.imageName.rawValue)?.title = truncatedString
        self.menu.item(at: MenuItem.imageName.rawValue)?.toolTip = "\((data.folder as NSString).appendingPathComponent(data.name))"
        
        self.menu.item(at: MenuItem.open.rawValue)?.isEnabled = true
        self.menu.item(at: MenuItem.archive.rawValue)?.isEnabled = true
        self.menu.item(at: MenuItem.delete.rawValue)?.isEnabled = true
        
        self.menu.item(at: MenuItem.open.rawValue)?.isEnabled = true
        self.menu.item(at: MenuItem.openReal.rawValue)?.isEnabled = true
        self.menu.item(at: MenuItem.favorite.rawValue)?.isEnabled = true
        self.menu.item(at: MenuItem.archive.rawValue)?.isEnabled = AppDelegate.archiveAllowed()
        self.menu.item(at: MenuItem.archiveKeep.rawValue)?.isEnabled = AppDelegate.archiveAllowed()
        self.menu.item(at: MenuItem.delete.rawValue)?.isEnabled = true
        
        disablingExceptions: do
        {
            if !currentFileExistsInCorrectDirectory()
            {
                self.menu.item(at: MenuItem.open.rawValue)?.isEnabled = false
                self.menu.item(at: MenuItem.openReal.rawValue)?.isEnabled = false
                self.menu.item(at: MenuItem.favorite.rawValue)?.isEnabled = false
                self.menu.item(at: MenuItem.archive.rawValue)?.isEnabled = false
                self.menu.item(at: MenuItem.archiveKeep.rawValue)?.isEnabled = false
                self.menu.item(at: MenuItem.delete.rawValue)?.isEnabled = false
            }
            
            if !originalFileExists()
            {
                self.menu.item(at: MenuItem.open.rawValue)?.isEnabled = false
                self.menu.item(at: MenuItem.favorite.rawValue)?.isEnabled = false
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
    
    func enableMonitor(_ enabled: Bool)
    {
        func disableMonitoring()
        {
            if self.monitor != nil
            {
                self.monitor?.stopMonitoring()
                self.monitor = nil
                
                print("Backgroundifier monitoring disabled")
            }
        }
        
        if !AppDelegate.conversionAllowed()
        {
            disableMonitoring()
            return
        }
        
        guard let monitoredUrl = AppDelegate.urlForKey(.sourcePath) else
        {
            disableMonitoring()
            return
        }
        
        if enabled
        {
            if self.monitor == nil
            {
                let monitor = FileChangeMonitor.init(inDirectory: monitoredUrl)
                monitor.delegate = self
                
                self.monitor = monitor
                self.monitor?.startMonitoring()
                
                print("Backgroundifier monitoring enabled")
            }
        }
        else
        {
            disableMonitoring()
        }
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
        let aUrl = currentUrl
        
        guard let url = aUrl else { return false }
        guard let outputUrl = AppDelegate.urlForKey(.outputPath) else { return false }
        
        // AB: only track files which are in our assigned output directory
        if url.deletingLastPathComponent() != outputUrl { return false }
        
        if !FileManager.default.fileExists(atPath: url.path) { return false }
        if url.hasDirectoryPath { return false }
        
        return true
    }
    
    func originalFileExists() -> Bool
    {
        let aUrl = originalUrl
        
        guard let url = aUrl else { return false }
        
        if !FileManager.default.fileExists(atPath: url.path) { return false }
        if url.hasDirectoryPath { return false }
        
        return true
    }
    
    func bgifyExists() -> Bool
    {
        guard let url = AppDelegate.urlForKey(.backgroundifierPath) else { return false }
        
        if !FileManager.default.fileExists(atPath: url.path) { return false }
        if !FileManager.default.isExecutableFile(atPath: url.path) { return false }
        
        return true
    }
    
    func generateArchivePath() -> Bool
    {
        guard let url = AppDelegate.urlForKey(.archivePath) else { return false }
        
        if !url.hasDirectoryPath { return false }
        
        if !FileManager.default.fileExists(atPath: url.path)
        {
            print("WARNING: archive directory does not exist, creating at \(url)")
            
            do
            {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
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
    @objc func mouseEntered(_ event: NSEvent)
    {
        self.desktopHasBeenToggled = false
    }
    @objc func mouseExited(_ event: NSEvent)
    {
        if self.desktopHasBeenToggled
        {
            toggleDesktop()
            self.desktopHasBeenToggled = false
        }
    }
    
    @objc func statusBarClicked(sender: NSStatusBarButton)
    {
        let event = NSApp.currentEvent!
        
        if event.type == NSEvent.EventType.rightMouseDown
        {
            //if event.mouseDo.contains(.option)
            //{
            //    refreshImage()
            //}
            //else
            //{
            //    toggleDesktop()
            //}
            
            //self.perform(#selector(refreshImage), with: nil, afterDelay: NSEvent.doubleClickInterval)
            //
            //if event.clickCount >= 2
            //{
            //    NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(refreshImage), object: nil)
            //
            //    toggleDesktop()
            //}

            if !self.desktopHasBeenToggled
            {
                self.desktopHasBeenToggled = true
                toggleDesktop()
            }
            else
            {
                refreshImage()
            }
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
        if let url = originalUrl
        {
            show(url)
        }
    }
    
    @objc func clickedOpenDisplayed(_ item: NSMenuItem)
    {
        if let url = currentUrl
        {
            show(url)
        }
    }
    
    @objc func clickedFavorite(_ item: NSMenuItem)
    {
        if !originalFileExists()
        {
            return
        }
        
        guard let url = originalUrl else
        {
            return
        }
        
        do
        {
            let resourceValues = try url.resourceValues(forKeys: [.tagNamesKey])
            
            var tags: [String]
            if let tagNames = resourceValues.tagNames
            {
                tags = tagNames
            }
            else
            {
                tags = [String]()
            }

            tags += ["Backgroundifier Favorite"]
            
            try (url as NSURL).setResourceValue(tags, forKey: .tagNamesKey)
        }
        catch
        {
            print("ERROR: \(error)")
        }
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
    
    @objc func clickedDock(_ item: NSMenuItem)
    {
        redock()
    }
    
    @objc func clickedDesktop(_ item: NSMenuItem)
    {
        toggleDesktopIcons()
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
        if !AppDelegate.archiveAllowed()
        {
            return false
        }
        
        if !originalFileExists() || !currentFileExistsInCorrectDirectory()
        {
            return false
        }
        
        if !generateArchivePath()
        {
            return false
        }
        
        guard let archivePath = AppDelegate.urlForKey(.archivePath) else
        {
            return false
        }
        
        guard let originalPath = self.originalUrl else
        {
            return false
        }
        
        var destinationURL = archivePath.appendingPathComponent(data.name)
        
        for i in 0..<1000
        {
            if FileManager.default.fileExists(atPath: destinationURL.path)
            {
                let name = (data.name as NSString).deletingPathExtension
                let ext = (data.name as NSString).pathExtension
                let newName = ("\(name) (\(i + 1))" as NSString).appendingPathExtension(ext)!
                
                destinationURL = archivePath.appendingPathComponent(newName)
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
            try FileManager.default.copyItem(at: originalPath, to: destinationURL)
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
        
        if originalFileExists() { urls.append(self.originalUrl!) }
        if currentFileExistsInCorrectDirectory() { urls.append(self.currentUrl!) }
        
        refreshImage()
        
        NSWorkspace.shared.recycle(urls, completionHandler: nil)
    }
    
    func backgroundify(_ file: URL) -> Bool
    {
        guard let bgifyUrl = AppDelegate.urlForKey(.backgroundifierPath) else
        {
            return false
        }
        
        guard let outputUrl = AppDelegate.urlForKey(.outputPath) else
        {
            return false
        }
        
        if !bgifyExists()
        {
            print("ERROR: Backgroundifier executable not found at \(bgifyUrl.path)")
            return false
        }

        if file.hasDirectoryPath || !FileManager.default.fileExists(atPath: file.path)
        {
            print("ERROR: image file missing")
            return false
        }
        
        let out = outputUrl.appendingPathComponent(file.lastPathComponent).deletingPathExtension().appendingPathExtension("jpg")
        
        // TODO: figure out how to expand sandbox to include output folder
        let task = Process()
        task.launchPath = bgifyUrl.path
        task.arguments = ["-i", file.path, "-o", out.path, "-w", "2560", "-h", "1600"]
        task.launch()
        task.waitUntilExit()
        
        print("Exited: \(task.terminationStatus)")
        
        return task.terminationStatus == 0
    }
    
    @objc func refreshImage()
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
    
    func toggleDesktop()
    {
        let missionControlURL = URL.init(fileURLWithPath: "/").appendingPathComponent("Applications").appendingPathComponent("Mission Control.app").appendingPathComponent("Contents").appendingPathComponent("MacOS").appendingPathComponent("Mission Control")
        
        if FileManager.default.isExecutableFile(atPath: missionControlURL.path)
        {
            let task = Process()
            task.launchPath = missionControlURL.path
            task.arguments = ["1"]
            task.launch()
        }
    }
    
    func redock()
    {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["killall", "Dock"]
        task.launch()
    }
    
    //var images: [String:Int] = [:]
    //func wallpaperTest()
    //{
    //        for _ in 0..<600
    //        {
    //            refreshImage()
    //            usleep(1000000 / 3)
    //            let img = wallpaper(forSpace: currentSpace(), display: currentDisplay())
    //            images[img.name] = (images[img.name] ?? 0) + 1
    //            //print("\(img.name)")
    //        }
    //
    //        print("Total images: \(images.keys.count)")
    //        print("---")
    //        let alphaImages = images.keys.sorted()
    //        for img in alphaImages
    //        {
    //            print(img)
    //        }
    //        print("---")
    //}
    
    func toggleDesktopIcons()
    {
        guard let defaults = UserDefaults.init(suiteName: "com.apple.finder") else
        {
            print("ERROR: could not load Finder defaults")
            return
        }
        
        let createDesktop = defaults.bool(forKey: "CreateDesktop")
        print("Create desktop: \(createDesktop)")
        defaults.set(!createDesktop, forKey: "CreateDesktop")
        
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["killall", "Finder"]
        task.launch()
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

/////////////////////
// MARK: - Defaults -
/////////////////////

extension AppDelegate
{
    static func archiveAllowed() -> Bool
    {
        if let url = UserDefaults.standard.url(forKey: Preferences.DefaultsKeys.archivePath.rawValue)
        {
            if let url2 = urlForKey(.outputPath), url == url2
            {
                return false
            }
            if let url2 = urlForKey(.sourcePath), url == url2
            {
                return false
            }
            
            return true
        }
        
        return false
    }
    
    static func conversionAllowed() -> Bool
    {
        if
            let sourceUrl = urlForKey(.sourcePath),
            let outputUrl = urlForKey(.outputPath),
            let _ = urlForKey(.backgroundifierPath),
            sourceUrl != outputUrl
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    static func urlForKey(_ key: Preferences.DefaultsKeys, rawValue: Bool = false) -> URL?
    {
        if rawValue
        {
            return UserDefaults.standard.url(forKey: key.rawValue)
        }
        
        switch key
        {
        case .sourcePath:
            if let url = UserDefaults.standard.url(forKey: Preferences.DefaultsKeys.sourcePath.rawValue)
            {
                if url.hasDirectoryPath && FileManager.default.fileExists(atPath: url.path)
                {
                    return url
                }
            }
        case .outputPath:
            if let url = UserDefaults.standard.url(forKey: Preferences.DefaultsKeys.outputPath.rawValue)
            {
                if url.hasDirectoryPath && FileManager.default.fileExists(atPath: url.path)
                {
                    return url
                }
            }
        case .archivePath:
            if let url = UserDefaults.standard.url(forKey: Preferences.DefaultsKeys.archivePath.rawValue)
            {
                if url.hasDirectoryPath && FileManager.default.fileExists(atPath: url.path)
                {
                    return url
                }
            }
        case .backgroundifierPath:
            if var url = UserDefaults.standard.url(forKey: Preferences.DefaultsKeys.backgroundifierPath.rawValue)
            {
                if url.hasDirectoryPath
                {
                    url = url.appendingPathComponent("Contents").appendingPathComponent("MacOS").appendingPathComponent("Backgroundifier")
                }
                
                if FileManager.default.fileExists(atPath: url.path) && FileManager.default.isExecutableFile(atPath: url.path)
                {
                    return url
                }
            }
        default:
            return nil
        }
        
        return nil
    }
}
