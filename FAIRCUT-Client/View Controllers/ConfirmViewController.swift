//
//  ConfirmViewController.swift
//  FAIRCUT-Client
//
//  Created by Takuma Kawamura on 2019/10/06.
//  Copyright © 2019 NITMakers. All rights reserved.
//

import Cocoa
import Starscream

class ConfirmViewController: NSViewController, NSWindowDelegate {
    @IBOutlet weak var faceScrollViewH: NSScrollView!
    @IBOutlet weak var faceStackViewH: NSStackView!
    
    @IBOutlet weak var goButton: NSButton!
    @IBOutlet weak var backButton: NSButton!
    @IBOutlet weak var jetsonProgress: NSProgressIndicator!
    @IBOutlet weak var messageLabel: NSTextField!
    
    let fromAppDelegate: AppDelegate = NSApplication.shared.delegate as! AppDelegate
    
    let speechSynth = NSSpeechSynthesizer()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        fromAppDelegate.socket?.delegate = self
        
        speechSynth.rate = 150
        speechSynth.volume = 0.7
        
        faceScrollViewH.hasHorizontalScroller = true
        faceScrollViewH.hasVerticalScroller = true
        faceScrollViewH.autohidesScrollers = true
        
        setupfaceStackViewH()
        
        backButton.keyEquivalent = String(utf16CodeUnits: [unichar(NSBackspaceCharacter)], count: 1)
        goButton.keyEquivalent = String(utf16CodeUnits: [unichar(NSCarriageReturnCharacter)], count: 1)
    }
    
    override func viewWillAppear() {
        messageLabel.isHidden = true
        speechSynth.startSpeaking("Please confirm the result of my face recognition.")
    }
    
    override func viewDidAppear() {
        self.view.window?.delegate = self
    }
    
    override func viewWillDisappear() {
        speechSynth.stopSpeaking()
    }
    
    override func viewDidDisappear() {
        
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApplication.shared.terminate(self)
        return true
    }
    
    @IBAction func onBackButton(_ sender: Any) {
        NSSound(named: "Tink")?.play()
        
        fromAppDelegate.socket?.disconnect()
    }
    
    
    @IBAction func onGoButton(_ sender: Any) {
        NSSound(named: "Tink")?.play()
        
        messageLabel.isHidden = false
        messageLabel.stringValue = "Jetson Nano is predicting BMI..."
        jetsonProgress.isHidden = false
        jetsonProgress.startAnimation(nil)
        
        let faces = fromAppDelegate.faceImageArray
        
        fromAppDelegate.socket?.write(string: "BeginTransmissionForFaces_" + String(faces!.count))
        
        for ( n, face ) in faces!.enumerated() {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            if face.save(as: "face_#"+String(n), fileType: .png, at: url) {
                print("file saved as face_#" + String(n) + ".png")
            }
            
            //fromAppDelegate.socket.write(string: "SendAFace")
            let faceDataURL = url.appendingPathComponent("face_#" + String(n) + ".png")
            let faceData = NSData(contentsOf: faceDataURL)
            let faceDataEncodedString = faceData?.base64EncodedString() ?? ""
            fromAppDelegate.socket?.write(string: faceDataEncodedString)
        }
        
        fromAppDelegate.socket?.write(string: "EndTransmissionForFaces")
    }
    
    private func setupfaceStackViewH() {
        guard let faces = fromAppDelegate.faceImageArray else { return }
        
        for ( n, face ) in faces.enumerated() {
            // make face image views
            let trimedFaceImage = face.resizeMaintainingAspectRatio(withSize: NSMakeSize(100, 120))
            let width = trimedFaceImage?.width
            let height = trimedFaceImage?.height
            
            trimedFaceImage?.lockFocus()
            
            let identificationText = NSString(string: "Recipient #" + String(n + 1))
            let destRect = CGRect(x: 0, y: height! - 50, width: width!, height: 50 )
            let textStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            textStyle.alignment = NSTextAlignment.center
            let shadow = NSShadow()
            shadow.shadowColor = .black
            shadow.shadowOffset = .zero
            shadow.shadowBlurRadius = 2.0
            
            let textFontAttributes = [
                NSAttributedString.Key.font: NSFont(name: "Avenir Next", size: 17.0),
                NSAttributedString.Key.foregroundColor: NSColor.white,
                NSAttributedString.Key.paragraphStyle: textStyle,
                NSAttributedString.Key.shadow: shadow
            ]
            identificationText.draw(in: destRect, withAttributes: textFontAttributes as [NSAttributedString.Key : Any])
            
            trimedFaceImage?.unlockFocus()
            
            let faceImageView = NSImageView(frame: NSMakeRect(0.0, 0.0, CGFloat(width!), CGFloat(height!)))
            faceImageView.image = trimedFaceImage
            
            // insert each face image view to stackview(parent)
            faceStackViewH.addArrangedSubview(faceImageView)
        }
        
        let scrollContentViewH = CenteringClipView(frame: faceStackViewH.frame)
        scrollContentViewH.documentView = faceStackViewH
        scrollContentViewH.drawsBackground = false
        faceScrollViewH.contentView = scrollContentViewH
    }
}

extension ConfirmViewController: WebSocketDelegate {
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("got some data")
    }
    
    func websocketDidConnect(socket: WebSocketClient) {
        print("websocket is connected")
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("websocket is disconnected: \(String(describing: error))")
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        jetsonProgress.stopAnimation(nil)
        
        if text.range(of: "BMI:") != nil {
            let substr = text[text.index(text.startIndex, offsetBy: 4) ..< text.index(text.endIndex, offsetBy: 0)]
            print(substr)
            
            let bmiLevelStringsArray = substr.components(separatedBy: ",")
            
            fromAppDelegate.bmiLevelIntArray = bmiLevelStringsArray.map({ (value: String) -> Int in
                return Int(value)!
            })
            
        }
        
        // Segue
        performSegue(withIdentifier: "SegueConfirm2Chart", sender: nil)
    }
    
}
