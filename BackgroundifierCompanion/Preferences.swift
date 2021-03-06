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
        case firstLaunch
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
    
    var sourceOriginalText: String!
    var outputOriginalText: String!
    var archiveOriginalText: String!
    var bgifyOriginalText: String!
    
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
                var aboutText1 = "%@ is copyright © 2018 Alexei Baboulevitch. For use in concert with Backgroundifier, which you can read all about at "
                let aboutText2 = ". Enjoy! 😊"
                let aboutTextName = "\(Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String) \(Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String)"
                let aboutTextUrl = "http://backgroundifier.archagon.net"
                let displayAboutTextUrl = "http://\u{2060}backgroundifier.archagon.net" //disable wrapping
                aboutText1 = String.init(format: aboutText1, aboutTextName)
                
                let font = NSFont.systemFont(ofSize: 12)
                
                let aboutAttributedTextUrl = NSMutableAttributedString.init(string: displayAboutTextUrl)
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
            
            textSetup: do
            {
                self.sourceOriginalText = self.sourceText.stringValue
                self.outputOriginalText = self.outputText.stringValue
                self.archiveOriginalText = self.archiveText.stringValue
                self.bgifyOriginalText = self.bgifyText.stringValue
                
                setLabelText(self.sourceOriginalText, forField: self.sourceText)
                setLabelText(self.outputOriginalText, forField: self.outputText)
                setLabelText(self.archiveOriginalText, forField: self.archiveText)
                setLabelText(self.bgifyOriginalText, forField: self.bgifyText)
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
        
        if let _ = AppDelegate.urlForKey(.sourcePath)
        {
            sourceUrl = AppDelegate.urlForKey(.sourcePath, rawValue: true)
        }
        if let _ = AppDelegate.urlForKey(.outputPath)
        {
            outputUrl = AppDelegate.urlForKey(.outputPath, rawValue: true)
        }
        if let _ = AppDelegate.urlForKey(.archivePath)
        {
            archiveUrl = AppDelegate.urlForKey(.archivePath, rawValue: true)
        }
        if let _ = AppDelegate.urlForKey(.backgroundifierPath)
        {
            bgifyUrl = AppDelegate.urlForKey(.backgroundifierPath, rawValue: true)
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
        
        if AppDelegate.conversionAllowed()
        {
            enableConversion.isEnabled = true
            enableConversionText.alphaValue = 1
        }
        else
        {
            enableConversion.isEnabled = false
            enableConversionText.alphaValue = 0.75
        }
        
        enableConversion.state = (UserDefaults.standard.bool(forKey: DefaultsKeys.conversionEnabled.rawValue) ? .on : .off)
        
        if sourceUrl != nil && sourceUrl == outputUrl
        {
            setLabelText(self.sourceOriginalText, forField: self.sourceText, withError: "Error: source directory must be different from output directory.")
            setLabelText(self.outputOriginalText, forField: self.outputText, withError: "Error: source directory must be different from output directory.")
        }
        else
        {
            setLabelText(self.sourceOriginalText, forField: self.sourceText)
            setLabelText(self.outputOriginalText, forField: self.outputText)
        }
        
        if archiveUrl != nil && (archiveUrl == sourceUrl || archiveUrl == outputUrl)
        {
            setLabelText(self.archiveOriginalText, forField: self.archiveText, withError: "Error: archive directory must be different from source or output directories.")
        }
        else
        {
            setLabelText(self.archiveOriginalText, forField: self.archiveText)
        }
        
        refitWindow: do
        {
            guard let window = self.window, let contentView = window.contentView else
            {
                break refitWindow
            }

            window.setContentSize(contentView.fittingSize)
        }
    }
    
    func setLabelText(_ text: String, forField field: NSTextField, withError error: String? = nil)
    {
        let baseAttributes: [NSAttributedStringKey:Any] = [:]
        var textAttributes = baseAttributes
        textAttributes[NSAttributedStringKey.font] = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: NSControl.ControlSize.small))
        textAttributes[NSAttributedStringKey.foregroundColor] = NSColor.labelColor
        var errorAttributes = baseAttributes
        errorAttributes[NSAttributedStringKey.foregroundColor] = NSColor.systemRed
        errorAttributes[NSAttributedStringKey.font] = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: NSControl.ControlSize.small), weight: NSFont.Weight.bold)
        
        let attributedText = NSMutableAttributedString.init(string: text, attributes: textAttributes)
        
        if let error = error
        {
            let errorString = NSMutableAttributedString.init(string: " \(error)", attributes: errorAttributes)
            attributedText.append(errorString)
        }
        
        field.attributedStringValue = attributedText
    }
}

// actions
extension Preferences
{
    @IBAction func convertAction(_ button: NSButton)
    {
        let oldValue = UserDefaults.standard.bool(forKey: DefaultsKeys.conversionEnabled.rawValue)
        UserDefaults.standard.set(!oldValue, forKey: DefaultsKeys.conversionEnabled.rawValue)
        UserDefaults.standard.synchronize()
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
        
        UserDefaults.standard.synchronize()
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
