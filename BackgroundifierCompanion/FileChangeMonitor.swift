//
//  FileChangeMonitor.swift
//  BackgroundifierCompanion
//
//  Created by Alexei Baboulevitch on 2018-4-23.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

protocol FileChangeMonitorDelegate: class
{
    func fileChangeMonitorDidObserveChange(_ directoryMonitor: FileChangeMonitor, additions: Set<URL>, deletions: Set<URL>)
}

class FileChangeMonitor: DirectoryMonitorDelegate
{
    weak var delegate: FileChangeMonitorDelegate?
    
    private let directoryMonitor: DirectoryMonitor
    private var oldFiles: Set<URL> = Set()
    
    init(inDirectory url: URL)
    {
        self.directoryMonitor = DirectoryMonitor.init(URL: url as NSURL)
        self.directoryMonitor.delegate = self
    }
    
    deinit
    {
        stopMonitoring()
    }
    
    func startMonitoring()
    {
        self.oldFiles = currentFiles()
        self.directoryMonitor.startMonitoring()
    }
    
    func stopMonitoring()
    {
        self.directoryMonitor.stopMonitoring()
        self.oldFiles = Set()
    }
    
    func currentFiles() -> Set<URL>
    {
        do
        {
            return Set(try FileManager.default.contentsOfDirectory(at: directoryMonitor.URL as URL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]))
        }
        catch
        {
            print("ERROR: \(error)")
            return Set()
        }
    }
    
    func directoryMonitorDidObserveChange(_ directoryMonitor: DirectoryMonitor)
    {
        let oldFiles = self.oldFiles
        let newFiles = currentFiles()
        
        let additions = newFiles.subtracting(oldFiles)
        let deletions = oldFiles.subtracting(newFiles)
        
        self.oldFiles = newFiles
        
        self.delegate?.fileChangeMonitorDidObserveChange(self, additions: additions, deletions: deletions)
    }
}
