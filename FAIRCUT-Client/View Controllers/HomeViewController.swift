//
//  HomeViewController.swift
//  FAIRCUT-Client
//
//  Created by Takuma Kawamura on 2019/07/19.
//  Copyright © 2019 NITMakers. All rights reserved.
//

import Cocoa
//import AVFoundation

class HomeViewController: NSViewController, NSWindowDelegate {
    
    @IBOutlet weak var startButton: NSButtonCell!
    let speechSynth = NSSpeechSynthesizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        speechSynth.rate = 150
        speechSynth.volume = 0.7
        
        startButton.keyEquivalent = String(utf16CodeUnits: [unichar(NSCarriageReturnCharacter)], count: 1)
    }
    
    override func viewDidAppear() {
        self.view.window?.delegate = self
    }
    
    override func viewWillAppear() {
        speechSynth.startSpeaking("Hello, user. I'm glad to see you.")
    }
    
    override func viewWillDisappear() {
        speechSynth.stopSpeaking()
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApplication.shared.terminate(self)
        return true
    }
    
}
