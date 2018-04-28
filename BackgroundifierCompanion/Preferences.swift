//
//  Preferences.swift
//  BackgroundifierCompanion
//
//  Created by Alexei Baboulevitch on 2018-4-23.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import AppKit

class Preferences: NSWindowController
{
    enum DefaultsKeys: String
    {
        case conversionEnabled
        case sourcePath
        case outputPath
        case archivePath
        case backgroundifierPath
    }
    
    @IBOutlet var enableConversion: NSButton!
    @IBOutlet var sourcePath: NSPathControl!
    @IBOutlet var outputPath: NSPathControl!
    @IBOutlet var archivePath: NSPathControl!
    @IBOutlet var bgifyPath: NSPathControl!
    @IBOutlet var sourceClear: NSButton!
    @IBOutlet var outputClear: NSButton!
    @IBOutlet var archiveClear: NSButton!
    @IBOutlet var bgifyClear: NSButton!
    @IBOutlet var sourceShow: NSButton!
    @IBOutlet var outputShow: NSButton!
    @IBOutlet var archiveShow: NSButton!
    @IBOutlet var bgifyShow: NSButton!
    @IBOutlet var enableConversionText: NSTextField!
    @IBOutlet var sourceText: NSTextField!
    @IBOutlet var outputText: NSTextField!
    @IBOutlet var archiveText: NSTextField!
    @IBOutlet var bgifyText: NSTextField!
    @IBOutlet var aboutText: NSTextField!
    
    override func windowDidLoad()
    {
        super.windowDidLoad()
        
        initialControlSetup: do
        {
            sourcePath.allowedTypes = [ kUTTypeFolder as String ]
            outputPath.allowedTypes = [ kUTTypeFolder as String ]
            archivePath.allowedTypes = [ kUTTypeFolder as String ]
            bgifyPath.allowedTypes = [ kUTTypeApplicationBundle as String, kUTTypeExecutable as String ]
            
            aboutTextStyling: do
            {
                var aboutText1 = "%@ is made by Alexei Baboulevitch, for use in concert with Backgroundifier processed images. You can read more about it at "
                let aboutText2 = ". Enjoy! 😊"
                let aboutTextName = "BackgroundifierCompanion 0.1"
                let aboutTextUrl = "http://backgroundifier.archagon.net"
                aboutText1 = String.init(format: aboutText1, aboutTextName)
                
                let font = NSFont.systemFont(ofSize: 12)
                
                let aboutAttributedTextUrl = NSMutableAttributedString.init(string: aboutTextUrl)
                let aboutAttributedTextUrlRange = NSMakeRange(0, aboutAttributedTextUrl.length)
                aboutAttributedTextUrl.beginEditing()
                aboutAttributedTextUrl.addAttributes([NSAttributedStringKey.link:URL.init(string: aboutTextUrl)!], range: aboutAttributedTextUrlRange)
                aboutAttributedTextUrl.addAttributes([NSAttributedStringKey.foregroundColor:NSColor.blue], range: aboutAttributedTextUrlRange)
                aboutAttributedTextUrl.addAttributes([NSAttributedStringKey.underlineStyle:NSUnderlineStyle.styleSingle.rawValue], range: aboutAttributedTextUrlRange)
                aboutAttributedTextUrl.addAttributes([NSAttributedStringKey.font:font], range: aboutAttributedTextUrlRange)
                aboutAttributedTextUrl.endEditing()
                
                let aboutAttributedString = NSMutableAttributedString()
                aboutAttributedString.append(NSAttributedString.init(string: aboutText1, attributes: [NSAttributedStringKey.font:font]))
                aboutAttributedString.append(aboutAttributedTextUrl)
                aboutAttributedString.append(NSAttributedString.init(string: aboutText2, attributes: [NSAttributedStringKey.font:font]))
                
                aboutText.isSelectable = true
                aboutText.allowsEditingTextAttributes = true
                aboutText.attributedStringValue = aboutAttributedString
            }
        }
        
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: nil)
        { [weak self] _ in
            self?.refreshControls()
        }
        
        refreshControls()
    }
    
    func refreshControls()
    {
        var sourceUrl: URL? = nil
        var outputUrl: URL? = nil
        var archiveUrl: URL? = nil
        var bgifyUrl: URL? = nil
        
        if let _ = urlForKey(.sourcePath)
        {
            sourceUrl = urlForKey(.sourcePath, rawValue: true)
        }
        if let _ = urlForKey(.outputPath)
        {
            outputUrl = urlForKey(.outputPath, rawValue: true)
        }
        if let _ = urlForKey(.archivePath)
        {
            archiveUrl = urlForKey(.archivePath, rawValue: true)
        }
        if let _ = urlForKey(.backgroundifierPath)
        {
            bgifyUrl = urlForKey(.backgroundifierPath, rawValue: true)
        }
        
        sourceClear.isEnabled = sourceUrl != nil
        sourceShow.isEnabled = sourceUrl != nil
        outputClear.isEnabled = outputUrl != nil
        outputShow.isEnabled = outputUrl != nil
        archiveClear.isEnabled = archiveUrl != nil
        archiveShow.isEnabled = archiveUrl != nil
        bgifyClear.isEnabled = bgifyUrl != nil
        bgifyShow.isEnabled = bgifyUrl != nil
        
        sourcePath.url = sourceUrl
        outputPath.url = outputUrl
        archivePath.url = archiveUrl
        bgifyPath.url = bgifyUrl
        
        enableConversion.state = (UserDefaults.standard.bool(forKey: DefaultsKeys.conversionEnabled.rawValue) ? .on : .off)
        
        if sourceUrl == nil || outputUrl == nil
        {
            enableConversion.isEnabled = false
            enableConversionText.alphaValue = 0.75
        }
        else
        {
            enableConversion.isEnabled = true
            enableConversionText.alphaValue = 1
        }
    }
    
    func urlForKey(_ key: DefaultsKeys, rawValue: Bool = false) -> URL?
    {
        if rawValue
        {
            return UserDefaults.standard.url(forKey: key.rawValue)
        }
        
        switch key
        {
        case .sourcePath:
            if let url = UserDefaults.standard.url(forKey: DefaultsKeys.sourcePath.rawValue)
            {
                if url.hasDirectoryPath && FileManager.default.fileExists(atPath: url.path)
                {
                    return url
                }
            }
        case .outputPath:
            if let url = UserDefaults.standard.url(forKey: DefaultsKeys.outputPath.rawValue)
            {
                if url.hasDirectoryPath && FileManager.default.fileExists(atPath: url.path)
                {
                    return url
                }
            }
        case .archivePath:
            if let url = UserDefaults.standard.url(forKey: DefaultsKeys.archivePath.rawValue)
            {
                if url.hasDirectoryPath && FileManager.default.fileExists(atPath: url.path)
                {
                    return url
                }
            }
        case .backgroundifierPath:
            if var url = UserDefaults.standard.url(forKey: DefaultsKeys.backgroundifierPath.rawValue)
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

// actions
extension Preferences
{
    @IBAction func convertAction(_ button: NSButton)
    {
    }
    
    @IBAction func clearAction(_ button: NSButton)
    {
        if button == self.sourceClear
        {
            UserDefaults.standard.set(nil, forKey: DefaultsKeys.sourcePath.rawValue)
        }
        else if button == self.outputClear
        {
            UserDefaults.standard.set(nil, forKey: DefaultsKeys.outputPath.rawValue)
        }
        else if button == self.archiveClear
        {
            UserDefaults.standard.set(nil, forKey: DefaultsKeys.archivePath.rawValue)
        }
        else if button == self.bgifyClear
        {
            UserDefaults.standard.set(nil, forKey: DefaultsKeys.backgroundifierPath.rawValue)
        }
    }
    
    @IBAction func openAction(_ button: NSButton)
    {
        if button == self.sourceShow
        {
            if let url = self.sourcePath.url
            {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        }
        else if button == self.outputShow
        {
            if let url = self.outputPath.url
            {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        }
        else if button == self.archiveShow
        {
            if let url = self.archivePath.url
            {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        }
        else if button == self.bgifyShow
        {
            if let url = self.bgifyPath.url
            {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        }
    }
    
    @IBAction func pathAction(_ control: NSPathControl)
    {
        if control == self.sourcePath
        {
            UserDefaults.standard.set(control.url, forKey: DefaultsKeys.sourcePath.rawValue)
        }
        else if control == self.outputPath
        {
            UserDefaults.standard.set(control.url, forKey: DefaultsKeys.outputPath.rawValue)
        }
        else if control == self.archivePath
        {
            UserDefaults.standard.set(control.url, forKey: DefaultsKeys.archivePath.rawValue)
        }
        else if control == self.bgifyPath
        {
            UserDefaults.standard.set(control.url, forKey: DefaultsKeys.backgroundifierPath.rawValue)
        }
        
        UserDefaults.standard.synchronize()
    }
}

extension Preferences: NSPathControlDelegate
{
    // TODO: ensure that paths are not the same
    func pathControl(_ pathControl: NSPathControl, willDisplay openPanel: NSOpenPanel)
    {
        if pathControl == self.sourcePath
        {
            //openPanel.message = self.sourceText.stringValue
            let dir = NSSearchPathForDirectoriesInDomains(.picturesDirectory, .userDomainMask, true).first
            openPanel.directoryURL = dir != nil ? URL.init(fileURLWithPath: dir!) : nil
        }
        else if pathControl == self.outputPath
        {
            //openPanel.message = self.outputText.stringValue
            let dir = NSSearchPathForDirectoriesInDomains(.picturesDirectory, .userDomainMask, true).first
            openPanel.directoryURL = dir != nil ? URL.init(fileURLWithPath: dir!) : nil
        }
        else if pathControl == self.archivePath
        {
            //openPanel.message = self.archiveText.stringValue
            let dir = NSSearchPathForDirectoriesInDomains(.picturesDirectory, .userDomainMask, true).first
            openPanel.directoryURL = dir != nil ? URL.init(fileURLWithPath: dir!) : nil
        }
        else if pathControl == self.bgifyPath
        {
            //openPanel.message = self.bgifyText.stringValue
            let dir = "/Applications"
            openPanel.directoryURL = URL.init(fileURLWithPath: dir)
        }
    }
    
    func pathControl(_ pathControl: NSPathControl, shouldDrag pathItem: NSPathControlItem, with pasteboard: NSPasteboard) -> Bool
    {
        return true
    }
    
    func pathControl(_ pathControl: NSPathControl, shouldDrag pathComponentCell: NSPathComponentCell, with pasteboard: NSPasteboard) -> Bool
    {
        return true
    }
    
//    public func pathControl(_ pathControl: NSPathControl, willDisplay openPanel: NSOpenPanel)
//    {
//    }
}

extension Preferences: NSTextFieldDelegate
{
}
