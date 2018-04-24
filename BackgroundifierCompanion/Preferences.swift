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
//    @IBOutlet var sourcePath: NSPathControl!
//    @IBOutlet var outputPath: NSPathControl!
//    @IBOutlet var archivePath: NSPathControl!
//    @IBOutlet var bgifyPath: NSPathControl!
//    @IBOutlet var sourceClear: NSButton!
//    @IBOutlet var outputClear: NSButton!
//    @IBOutlet var archiveClear: NSButton!
//    @IBOutlet var bgifyClear: NSButton!
    
    override func windowDidLoad()
    {
        super.windowDidLoad()
        
        if let sourcePath = self.window?.contentView?.viewWithTag(1) as? NSPathControl
        {
        }
        
        if let outputPath = self.window?.contentView?.viewWithTag(2) as? NSPathControl
        {
        }
        
        if let archivePath = self.window?.contentView?.viewWithTag(3) as? NSPathControl
        {
        }
        
        if let bgifyPath = self.window?.contentView?.viewWithTag(4) as? NSPathControl
        {
            bgifyPath.allowedTypes = [ kUTTypeApplicationBundle as String ]
        }
    }
}

// actions
extension Preferences
{
    @IBAction func clearAction(_ button: NSButton)
    {
        let pathTag = button.tag - 10
        
        if let pathControl = self.window?.contentView?.viewWithTag(pathTag) as? NSPathControl
        {
            pathControl.url = nil
        }
    }
    
    @IBAction func pathAction(_ control: NSPathControl)
    {
        print("Path: \(control.url?.path ?? "")")
    }
}

extension Preferences: NSPathControlDelegate
{
    public func pathControl(_ pathControl: NSPathControl, shouldDrag pathItem: NSPathControlItem, with pasteboard: NSPasteboard) -> Bool
    {
        return true
    }
    
    public func pathControl(_ pathControl: NSPathControl, shouldDrag pathComponentCell: NSPathComponentCell, with pasteboard: NSPasteboard) -> Bool
    {
        return true
    }
    
//    public func pathControl(_ pathControl: NSPathControl, willDisplay openPanel: NSOpenPanel)
//    {
//    }
}
