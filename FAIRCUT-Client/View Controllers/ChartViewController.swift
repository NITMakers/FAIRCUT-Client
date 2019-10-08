//
//  ChartViewController.swift
//  FAIRCUT-Client
//
//  Created by Takuma Kawamura on 2019/07/25.
//  Copyright © 2019 NITMakers. All rights reserved.
//

import Cocoa
import Charts

class ChartViewController: NSViewController, NSWindowDelegate {
    
    @IBOutlet weak var pieChartView: PieChartView!
    @IBOutlet weak var faceScrollView1: NSScrollView!
    @IBOutlet weak var faceScrollView2: NSScrollView!
    @IBOutlet weak var faceStackView1: NSStackView!
    @IBOutlet weak var faceStackView2: NSStackView!
    @IBOutlet weak var finishButton: NSButton!
    
    @IBOutlet weak var parentView: NSSplitView!
    
    let fromAppDelegate: AppDelegate = NSApplication.shared.delegate as! AppDelegate
    
    let speechSynth = NSSpeechSynthesizer()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        speechSynth.rate = 150
        speechSynth.volume = 0.7
        
        setupPieChartView()
        faceScrollView1.hasHorizontalScroller = true
        faceScrollView1.hasVerticalScroller = true
        faceScrollView1.autohidesScrollers = true
        faceScrollView2.hasHorizontalScroller = true
        faceScrollView2.hasVerticalScroller = true
        faceScrollView2.autohidesScrollers = true
        
        setupfaceStackView()
        
        finishButton.keyEquivalent = String(utf16CodeUnits: [unichar(NSCarriageReturnCharacter)], count: 1)
    }
    
    override func viewWillAppear() {
        let bmiLevelArray = fromAppDelegate.bmiLevelIntArray ?? []
        let maxLevel = bmiLevelArray.max()
        let minLevel = bmiLevelArray.min()
        var maxLevelIndexArray: [Int] = []
        var minLevelIndexArray: [Int] = []
        for (index, value) in bmiLevelArray.enumerated() {
            if value == maxLevel {
                maxLevelIndexArray.append(index)
            } else if value == minLevel {
                minLevelIndexArray.append(index)
            }
        }
        if minLevelIndexArray.count == 0 || maxLevelIndexArray.count == 0 {
            speechSynth.startSpeaking("This is the my distribution result. According to my prediction, you have almost the same value of BMI.")
        } else {
            var thinnestString: String = ""
            if maxLevelIndexArray.count == 1 {
                thinnestString.append("recipient number \(String(maxLevelIndexArray[0] + 1)) is the most thinnest.")
            } else {
                thinnestString.append("recipient number \(String(maxLevelIndexArray[0] + 1))")
                maxLevelIndexArray.removeFirst()
                let lastMaxLevelIndex: Int! = maxLevelIndexArray.last
                maxLevelIndexArray.removeLast()
                for index in maxLevelIndexArray {
                    thinnestString.append(", number \(String(index + 1))")
                }
                thinnestString.append(" and number \(String(lastMaxLevelIndex + 1)) are the most thinnest.")
            }
            var fattestString: String = ""
            if minLevelIndexArray.count == 1 {
                fattestString.append("recipient number \(String(minLevelIndexArray[0] + 1)) is the most fattest.")
            } else {
                fattestString.append("recipient number \(String(minLevelIndexArray[0] + 1))")
                minLevelIndexArray.removeFirst()
                let lastMinLevelIndex: Int! = minLevelIndexArray.last
                minLevelIndexArray.removeLast()
                for index in minLevelIndexArray {
                    fattestString.append(", number \(String(index + 1))")
                }
                fattestString.append(" and number \(String(lastMinLevelIndex + 1)) are the most fattest.")
            }
            
            speechSynth.startSpeaking("This is the my distribution result. According to my prediction, " + fattestString + " On the other hand, " + thinnestString)
        }
        
        pieChartView.isHidden = true
    }
    
    override func viewDidAppear() {
        self.view.window?.delegate = self
        
        pieChartView.isHidden = false
        pieChartView.animate(xAxisDuration: 0.0, yAxisDuration: 2.0)
    }
    
    override func viewWillDisappear() {
        speechSynth.stopSpeaking()
    }
    
    override func viewDidDisappear() {
        fromAppDelegate.socket?.disconnect()
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApplication.shared.terminate(self)
        return true
    }
    
    private func setupPieChartView() {
        pieChartView.highlightPerTapEnabled = false  // グラフがタップされたときのハイライト
        pieChartView.chartDescription?.enabled = true  // グラフの説明
        pieChartView.drawEntryLabelsEnabled = true  // グラフ上のデータラベル
        pieChartView.legend.enabled = false  // グラフの注釈
        pieChartView.rotationEnabled = false
        pieChartView.usePercentValuesEnabled = true
        pieChartView.drawSlicesUnderHoleEnabled = false
        pieChartView.holeRadiusPercent = 0.45
        pieChartView.transparentCircleRadiusPercent = 0.43
        pieChartView.minOffset = 10
        let textStyle: NSMutableParagraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        textStyle.lineBreakMode = .byTruncatingTail
        textStyle.alignment = .center
        let centerText: NSMutableAttributedString = NSMutableAttributedString(string: "The Baumkuchen\nDistribution by AI")
        let textFontAttributes = [
            NSAttributedString.Key.font: NSFont(name: "Avenir Next", size: 30.0),
            //NSAttributedString.Key.foregroundColor: NSColor.black,
            NSAttributedString.Key.foregroundColor: NSColor(red: CGFloat(33/255), green: CGFloat(33/255), blue: CGFloat(33/255), alpha: 1.0),
            NSAttributedString.Key.paragraphStyle: textStyle
        ]
        centerText.setAttributes(textFontAttributes as [NSAttributedString.Key : Any], range: NSRange(location: 0, length: centerText.string.count))
        pieChartView.centerAttributedText = centerText
        
        let bmiLevelArray = fromAppDelegate.bmiLevelIntArray ?? []
        
        // グラフに表示する適当なデータセットを定義
        var entriesForDataSet = [PieChartDataEntry]()
        let baumCal: Int = Int(UserDefaults.standard.integer(forKey: "TotalCalories"))
        for (index, value) in bmiLevelArray.enumerated() {
            entriesForDataSet.append(PieChartDataEntry(value: Double(value), label: "#" + String(index + 1) + "\n" + String(value * baumCal / 100) + "kcal"))
        }
        
        let dataSet = PieChartDataSet(entries: entriesForDataSet, label: "BMIData")
        let chartColorTemplateString = UserDefaults.standard.string(forKey: "ChartColorTemplate")
        switch chartColorTemplateString {
        case "colorful":
            dataSet.colors = ChartColorTemplates.colorful()
        case "liberty":
            dataSet.colors = ChartColorTemplates.liberty()
        case "joyful":
            dataSet.colors = ChartColorTemplates.joyful()
        case "vordiplom":
            dataSet.colors = ChartColorTemplates.vordiplom()
        case "pastel":
            dataSet.colors = ChartColorTemplates.pastel()
        case "material":
            dataSet.colors = ChartColorTemplates.material()
        default:
            dataSet.colors = ChartColorTemplates.colorful()
        }
        dataSet.drawValuesEnabled = true  // グラフ上のデータ値を表示
        dataSet.yValuePosition = .outsideSlice
        dataSet.valueLinePart1Length = 0.35
        dataSet.valueLinePart2Length = 0.7
        //dataSet.valueTextColor = .black
        dataSet.valueTextColor = NSColor(red: CGFloat(33/255), green: CGFloat(33/255), blue: CGFloat(33/255), alpha: 1.0)
        dataSet.entryLabelFont = NSFont(name: "Avenir Next", size: 26.0)
        dataSet.entryLabelColor = .white
        dataSet.valueFont = NSFont(name: "Avenir Next", size: 24.0)!
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        formatter.multiplier = 1.0
        formatter.percentSymbol = "%"
        dataSet.valueFormatter = DefaultValueFormatter(formatter: formatter)
        
        pieChartView.data = PieChartData(dataSet: dataSet)
    }
    
    private func setupfaceStackView() {
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
            if faces.count % 2 == 0 {
                if n < Int(faces.count / 2) {
                    faceStackView1.addArrangedSubview(faceImageView)
                } else {
                    faceStackView2.insertArrangedSubview(faceImageView, at: 0)
                }
            } else {
                if n <= Int(faces.count / 2) {
                    faceStackView1.addArrangedSubview(faceImageView)
                } else {
                    faceStackView2.insertArrangedSubview(faceImageView, at: 0)
                }
            }

        }
        
        let scrollContentView1 = CenteringClipView(frame: faceStackView1.frame)
        scrollContentView1.documentView = faceStackView1
        scrollContentView1.drawsBackground = false
        faceScrollView1.contentView = scrollContentView1
        
        if faces.count > 0 {
            let scrollContentView2 = CenteringClipView(frame: faceStackView2.frame)
            scrollContentView2.documentView = faceStackView2
            scrollContentView2.drawsBackground = false
            faceScrollView2.contentView = scrollContentView2
        }
    }
    
    
}

extension ChartViewController {
    
    @IBAction func onPrintButtonPressed(_ sender: Any) {
        //let printOpts: [NSPrintInfo.AttributeKey: Any] = [NSPrintInfo.AttributeKey.headerAndFooter: true]
        
        let printInfo = NSPrintInfo()
        printInfo.orientation = .landscape
        printInfo.isHorizontallyCentered = true
        printInfo.isVerticallyCentered = true
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .automatic
        
        let date: NSDate = NSDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-HHmm"
        
        let op = NSPrintOperation(view: self.parentView, printInfo: printInfo)
        op.jobTitle = "FAIRCUT-" + dateFormatter.string(from: date as Date)
        op.canSpawnSeparateThread = true
        op.run()
        
    }
}
