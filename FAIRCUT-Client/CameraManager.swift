//
//  CameraManager.swift
//  FAIRCUT-Client
//
//  Created by Takuma Kawamura on 2019/07/15.
//  Copyright © 2019 NITMakers. All rights reserved.
//

import Cocoa
import AVFoundation


/// カメラ周りの処理担当するやつ
class CameraManager {
    //ターゲットのカメラがあれば設定（見つからなければデフォルト）
    private let targetDeviceName = "USB  Live  Camera"
    //    private let targetDeviceName = "FaceTime HDカメラ（ディスプレイ）"
    //    private let targetDeviceName = "FaceTime HD Camera"
    
    // AVFoundation
    private let session = AVCaptureSession()
    private var captureDevice : AVCaptureDevice!
    private var videoOutput = AVCaptureVideoDataOutput()
    
    /// セッション開始
    func startSession(delegate:AVCaptureVideoDataOutputSampleBufferDelegate){
        
        let devices = AVCaptureDevice.devices()
        if devices.count > 0 {
            captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
            // ターゲットが設定されていればそれを選択
            print("\n[接続カメラ一覧]")
            for d in devices {
                if d.localizedName == targetDeviceName {
                    captureDevice = d
                }
                print(d.localizedName)
            }
            print("\n[使用カメラ]\n\(captureDevice!.localizedName)\n\n")
            // セッションの設定と開始
            session.beginConfiguration()
            let videoInput = try? AVCaptureDeviceInput.init(device: captureDevice)
            session.sessionPreset = .low
            //session.sessionPreset = AVCaptureSession.Preset.photo
            session.addInput(videoInput!)
            session.addOutput(videoOutput)
            session.commitConfiguration()
            session.startRunning()
            // 画像バッファ取得のための設定
            let queue:DispatchQueue = DispatchQueue(label: "videoOutput", attributes: .concurrent)
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String : Int(kCVPixelFormatType_32BGRA)]
            videoOutput.setSampleBufferDelegate(delegate, queue: queue)
            videoOutput.alwaysDiscardsLateVideoFrames = true
        } else {
            print("カメラが接続されていません")
        }
    }
    
    func killSession() {
        if session.isRunning {
            session.stopRunning()
        }
        let videoInput = try? AVCaptureDeviceInput.init(device: captureDevice)
        session.removeInput(videoInput!)
        session.removeOutput(videoOutput)
    }
}

// Singleton
extension CameraManager {
    class var shared : CameraManager {
        struct Static { static let instance : CameraManager = CameraManager() }
        return Static.instance
    }
}
