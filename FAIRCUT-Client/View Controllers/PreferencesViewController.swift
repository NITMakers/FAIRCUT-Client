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
    
    @IBOutlet weak var totalCalorieField: NSTextFieldCell!
    
    @IBOutlet weak var paperSizePopUp: NSPopUpButton!
    
    @IBOutlet weak var couponSwitch: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        jetsonIPText.delegate = self
    }
    
    override func viewWillAppear() {
        jetsonIPText.stringValue = String(UserDefaults.standard.object(forKey: "JetsonIPAddress") as! String)
        let titleLowerCased = String(UserDefaults.standard.string(forKey: "ChartColorTemplate")!)
        chartColorTemplatePopUp.selectItem(withTitle: (titleLowerCased.first?.uppercased())! + titleLowerCased.dropFirst())
        totalCalorieField.intValue = Int32(UserDefaults.standard.integer(forKey: "TotalCalories"))
        paperSizePopUp.selectItem(withTitle: String(UserDefaults.standard.string(forKey: "PaperSize")!))
        if Bool(UserDefaults.standard.bool(forKey: "CouponSwitch")) == true {
            couponSwitch.state = .on
        } else {
            couponSwitch.state = .off
        }
    }
    
    override func viewWillDisappear() {
        UserDefaults.standard.set(jetsonIPText.stringValue, forKey: "JetsonIPAddress")
        let colorTemplateString = chartColorTemplatePopUp.titleOfSelectedItem?.lowercased()
        UserDefaults.standard.set(colorTemplateString, forKey: "ChartColorTemplate")
        UserDefaults.standard.set(Int(totalCalorieField.intValue), forKey: "TotalCalories")
        UserDefaults.standard.set(String(paperSizePopUp.titleOfSelectedItem ?? "A5"), forKey: "PaperSize")
        if couponSwitch.state == .on {
            UserDefaults.standard.set(Bool(true), forKey: "CouponSwitch")
        } else {
            UserDefaults.standard.set(Bool(false), forKey: "CouponSwitch")
        }
    }
    
}

extension PreferencesViewController: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        if !jetsonIPText.stringValue.isIPv4() {
            jetsonIPText.stringValue = String(UserDefaults.standard.object(forKey: "JetsonIPAddress") as! String)
        }
    }
}
