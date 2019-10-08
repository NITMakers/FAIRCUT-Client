//
//  CaptureViewController.swift
//  FAIRCUT-Client
//
//  Created by Takuma Kawamura on 2019/07/15.
//  Copyright © 2019 NITMakers. All rights reserved.
//

import Cocoa
import AVFoundation
import Foundation
import Starscream

class CaptureViewController: NSViewController, NSWindowDelegate {
    
    @IBOutlet weak var CaptureView: NSImageView!
    @IBOutlet weak var messageLabel: NSTextField!
    @IBOutlet weak var jetsonProgress: NSProgressIndicator!
    @IBOutlet weak var backButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!
    
    
    let fromAppDelegate: AppDelegate = NSApplication.shared.delegate as! AppDelegate
    
    let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options:[CIDetectorAccuracy: CIDetectorAccuracyLow] )
    
    let speechSynth = NSSpeechSynthesizer()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        speechSynth.rate = 150
        speechSynth.volume = 0.7
        
        fromAppDelegate.socket = WebSocket(url: URL(string: "ws://" + String(UserDefaults.standard.object(forKey: "JetsonIPAddress") as! String) + ":8080/")!)
        //fromAppDelegate.socket?.delegate = self
        fromAppDelegate.socket?.connect()
        
        nextButton.keyEquivalent = String(utf16CodeUnits: [unichar(NSCarriageReturnCharacter)], count: 1)
        backButton.keyEquivalent = String(utf16CodeUnits: [unichar(NSBackspaceCharacter)], count: 1)
    }
    
    override func viewDidAppear() {
        self.view.window?.delegate = self
    }
    
    override func viewWillAppear() {
        CameraManager.shared.startSession(delegate: self)
        
        if fromAppDelegate.socket?.isConnected ?? false {
            messageLabel.isHidden = true
            speechSynth.startSpeaking("Please capture your face for predicting.")
        }else{
            messageLabel.isHidden = false
            messageLabel.stringValue = "Failed to establish a connection."
            speechSynth.startSpeaking("Failed to establish a connection. Please try again.")
        }
    }
    
    override func viewWillDisappear() {
        CameraManager.shared.killSession()
        speechSynth.stopSpeaking()
    }
    
    override func viewDidDisappear() {
        //fromAppDelegate.socket.disconnect()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApplication.shared.terminate(self)
        return true
    }
    
    @IBAction func onPrevButton(_ sender: Any) {
        
    }
    
    @IBAction func onNextButton(_ sender: Any) {
        NSSound(named: "Tink")?.play()
        
        print("Next")
        /*messageLabel.isHidden = false
        messageLabel.stringValue = "Jetson Nano is predicting BMI..."
        jetsonProgress.isHidden = false
        jetsonProgress.startAnimation(nil)*/
        
        guard let faces = self.CaptureView.image?.faces else { return }
        fromAppDelegate.faceImageArray = faces
        
        performSegue(withIdentifier: "SegueCapture2Confirm", sender: nil)
        
        /*
        fromAppDelegate.socket?.write(string: "BeginTransmissionForFaces_" + String(faces.count))
        
        for ( n, face ) in faces.enumerated() {
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
        */
    }
}

/// カメラ映像を取得して処理
extension CaptureViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    /// カメラ映像取得時
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        DispatchQueue.main.sync(execute: {
            connection.videoOrientation = .portrait
            let pixelBuffer:CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
            //CIImage
            let ciimage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.upMirrored)
            let w = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
            let h = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
            let rect:CGRect = CGRect.init(x: 0, y: 0, width: w, height: h)
            let context = CIContext.init()
            //CGImage
            let cgimage = context.createCGImage(ciimage, from: rect)
            //UIImage
            let nsimage = NSImage(cgImage: cgimage!, size: NSSize(width: w, height: h))
            
            // Draw main view to GUI
            self.CaptureView.image = nsimage
            
            // Delete subviews of previous capturing
            if self.CaptureView.subviews.count > 0 {
                let subviews = self.CaptureView.subviews
                for subview in subviews {
                    subview.removeFromSuperview()
                }
            }

            // CIdetector detects faces
            let features = detector!.features(in: ciimage)
            for feature in features {
                // Get face rectangle frame data (CoreGraphics)
                var faceRect = feature.bounds
                
                // 変換(画像 -> View)
                let widthPer = (CaptureView.bounds.width/w)
                let heightPer = (CaptureView.bounds.height/h)
                // AppkitはLLO(左下原点)
                //倍率変換
                faceRect.origin.x = faceRect.origin.x * widthPer
                faceRect.origin.y = faceRect.origin.y * heightPer
                faceRect.size.width = faceRect.size.width * widthPer
                faceRect.size.height = faceRect.size.height * heightPer
                
                let subRectView = DrawRectangle(frame: NSRectFromCGRect(faceRect))
                self.CaptureView.addSubview(subRectView)
            }
        })
    }
    
}


extension CaptureViewController: WebSocketDelegate {
    
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
        print("received message: \(text)")
    }
    
    /*
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
        performSegue(withIdentifier: "SegueCapture2Chart", sender: nil)
    }
 */
    
}


