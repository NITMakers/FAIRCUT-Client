//
//  ChartViewController.swift
//  FAIRCUT-Client
//
//  Created by Takuma Kawamura on 2019/07/25.
//  Copyright © 2019 NITMakers. All rights reserved.
//

import Cocoa
import Charts

class ChartViewController: NSViewController {
    
    @IBOutlet weak var pieChartView: PieChartView!
    @IBOutlet weak var faceScrollView: NSScrollView!
    @IBOutlet weak var faceStackView: NSStackView!
    @IBOutlet weak var finishButton: NSButton!
    
    let fromAppDelegate: AppDelegate = NSApplication.shared.delegate as! AppDelegate
    
    let speechSynth = NSSpeechSynthesizer()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        speechSynth.rate = 150
        speechSynth.volume = 0.7
        
        setupPieChartView()
        faceScrollView.hasHorizontalScroller = true
        faceScrollView.hasVerticalScroller = true
        faceScrollView.autohidesScrollers = true
        
        setupFaceStackView()
        
        finishButton.keyEquivalent = String(utf16CodeUnits: [unichar(NSCarriageReturnCharacter)], count: 1)
    }
    
    override func viewWillAppear() {
        speechSynth.startSpeaking("This is the my distribution result.")
        pieChartView.isHidden = true
    }
    
    override func viewDidAppear() {
        pieChartView.isHidden = false
        pieChartView.animate(xAxisDuration: 0.0, yAxisDuration: 2.0)
    }
    
    override func viewWillDisappear() {
        speechSynth.stopSpeaking()
    }
    
    override func viewDidDisappear() {
    }
    
    private func setupPieChartView() {
        pieChartView.highlightPerTapEnabled = false  // グラフがタップされたときのハイライト
        pieChartView.chartDescription?.enabled = true  // グラフの説明
        pieChartView.drawEntryLabelsEnabled = true  // グラフ上のデータラベル
        pieChartView.legend.enabled = false  // グラフの注釈
        pieChartView.rotationEnabled = false
        pieChartView.usePercentValuesEnabled = true
        pieChartView.drawSlicesUnderHoleEnabled = false
        pieChartView.holeRadiusPercent = 0.4
        pieChartView.transparentCircleRadiusPercent = 0.43
        pieChartView.minOffset = 10
        let textStyle: NSMutableParagraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        textStyle.lineBreakMode = .byTruncatingTail
        textStyle.alignment = .center
        let centerText: NSMutableAttributedString = NSMutableAttributedString(string: "The Baumkuchen\nDistribution by AI")
        let textFontAttributes = [
            NSAttributedString.Key.font: NSFont(name: "Avenir Next", size: 32.0),
            NSAttributedString.Key.foregroundColor: NSColor.black,
            NSAttributedString.Key.paragraphStyle: textStyle
        ]
        centerText.setAttributes(textFontAttributes as [NSAttributedString.Key : Any], range: NSRange(location: 0, length: centerText.string.count))
        pieChartView.centerAttributedText = centerText
        
        let bmiLevelArray = fromAppDelegate.bmiLevelIntArray ?? []
        
        // グラフに表示する適当なデータセットを定義
        var entriesForDataSet = [PieChartDataEntry]()
        let baumCal: Int = 3251 / Int(UserDefaults.standard.integer(forKey: "MUJIDivision"))
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
        dataSet.valueLinePart1Length = 0.4
        dataSet.valueLinePart2Length = 0.8
        dataSet.valueTextColor = .black
        dataSet.entryLabelFont = NSFont(name: "Avenir Next", size: 26.0)
        dataSet.entryLabelColor = .white
        dataSet.valueFont = NSFont(name: "Avenir Next", size: 24.0)!
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 3
        formatter.multiplier = 1.0
        formatter.percentSymbol = "%"
        dataSet.valueFormatter = DefaultValueFormatter(formatter: formatter)
        
        pieChartView.data = PieChartData(dataSet: dataSet)
    }
    
    private func setupFaceStackView() {
        guard let faces = fromAppDelegate.faceImageArray else { return }
        
        for ( n, face ) in faces.enumerated() {
            let trimedFaceImage = face.resizeMaintainingAspectRatio(withSize: NSMakeSize(100, 150))
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
                NSAttributedString.Key.font: NSFont(name: "Avenir Next", size: 18.0),
                NSAttributedString.Key.foregroundColor: NSColor.white,
                NSAttributedString.Key.paragraphStyle: textStyle,
                NSAttributedString.Key.shadow: shadow
            ]
            identificationText.draw(in: destRect, withAttributes: textFontAttributes as [NSAttributedString.Key : Any])
            
            trimedFaceImage?.unlockFocus()
            
            let faceImageView = NSImageView(frame: NSMakeRect(0.0, 0.0, CGFloat(width!), CGFloat(height!)))
            faceImageView.image = trimedFaceImage
            
            faceStackView.addArrangedSubview(faceImageView)
        }
        
        let scrollContentView = CenteringClipView(frame: faceStackView.frame)
        scrollContentView.documentView = faceStackView
        scrollContentView.drawsBackground = false
        faceScrollView.contentView = scrollContentView
    }
    
}
