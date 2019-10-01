//
//  SlideSegue.swift
//  FAIRCUT-Client
//
//  Created by Takuma Kawamura on 2019/07/19.
//  Copyright © 2019 NITMakers. All rights reserved.
//

import Cocoa

class ForwardSlideSegue: NSStoryboardSegue {
    override func perform() {
        // NSViewControllerの親子関係を設定
        guard
            let s = self.sourceController as? NSViewController,
            let d = self.destinationController as? NSViewController,
            let p = s.parent
            else {
                print("downcasting or unwrapping error")
                return
        }
        
        if (!p.children.contains(d)) {
            p.addChild(d)
        }
        
        NSSound(named: "Submarine")?.play()
        
        s.view.superview?.wantsLayer = true // (追加)
        p.transition(from: s, to: d, options: .slideForward, completionHandler: {
            s.removeFromParent() // 戻る可能性があるなら不要かも
            s.view.removeFromSuperview()
        })
    }
}

class BackwardSlideSegue: NSStoryboardSegue {
    override func perform() {
        // NSViewControllerの親子関係を設定
        guard
            let s = self.sourceController as? NSViewController,
            let d = self.destinationController as? NSViewController,
            let p = s.parent
            else {
                print("downcasting or unwrapping error")
                return
        }
        
        if (!p.children.contains(d)) {
            p.addChild(d)
        }

        NSSound(named: "Submarine")?.play()
        
        s.view.superview?.wantsLayer = true // (追加)
        p.transition(from: s, to: d, options: .slideBackward, completionHandler: {
            s.removeFromParent() // 戻る可能性があるなら不要かも
            s.view.removeFromSuperview()
        })
    }
}

