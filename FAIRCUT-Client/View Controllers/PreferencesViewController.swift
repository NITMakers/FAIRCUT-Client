//
//  PreferencesViewController.swift
//  FAIRCUT-Client
//
//  Created by Takuma Kawamura on 2019/07/27.
//  Copyright © 2019 NITMakers. All rights reserved.
//

import Cocoa
import CoreGraphics

class PreferencesViewController: NSViewController {
    
    @IBOutlet weak var jetsonIPText: NSTextField!
    
    @IBOutlet weak var chartColorTemplatePopUp: NSPopUpButton!
    
    @IBOutlet weak var divisionField: NSTextFieldCell!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        jetsonIPText.delegate = self
    }
    
    override func viewWillAppear() {
        jetsonIPText.stringValue = String(UserDefaults.standard.object(forKey: "JetsonIPAddress") as! String)
        divisionField.intValue = Int32(UserDefaults.standard.integer(forKey: "MUJIDivision"))
    }
    
    override func viewWillDisappear() {
        UserDefaults.standard.set(jetsonIPText.stringValue, forKey: "JetsonIPAddress")
        let colorTemplateString = chartColorTemplatePopUp.titleOfSelectedItem?.lowercased()
        UserDefaults.standard.set(colorTemplateString, forKey: "ChartColorTemplate")
        UserDefaults.standard.set(Int(divisionField.intValue), forKey: "MUJIDivision")
    }
    
}

extension PreferencesViewController: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        if !jetsonIPText.stringValue.isIPv4() {
            jetsonIPText.stringValue = String(UserDefaults.standard.object(forKey: "JetsonIPAddress") as! String)
        }
    }
}