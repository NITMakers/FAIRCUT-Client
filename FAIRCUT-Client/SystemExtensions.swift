//
//  SystemExtensions.swift
//  FAIRCUT-Client
//
//  Created by Takuma Kawamura on 2019/07/18.
//  Copyright © 2019 NITMakers. All rights reserved.
//

import Cocoa
import AVFoundation


// For face tracking
class DrawRectangle: NSView{
    override func draw(_ dirtyRect: NSRect) {
        let context = NSGraphicsContext.current?.cgContext
        context?.setStrokeColor(red: 177/255.0, green: 0/255.0, blue: 6/255.0, alpha: 1.0)
        context?.setLineWidth(5.0)
        context?.addRect(dirtyRect)
        context?.strokePath()
    }
}

// For store faces
extension NSImage {
    var ciImage: CIImage? {
        guard let data = tiffRepresentation else { return nil }
        return CIImage(data: data)
    }
    var faces: [NSImage] {
        guard let ciImage = ciImage else { return [] }
        return (CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])?
            .features(in: ciImage) as? [CIFaceFeature])?
            .map {
                // additional begin
                var faceRect = $0.bounds
                let expansionSize: CGFloat = 100.0
                faceRect.origin.x = faceRect.origin.x - expansionSize
                faceRect.origin.y = faceRect.origin.y - expansionSize
                faceRect.size.width = faceRect.size.width + expansionSize * 2
                faceRect.size.height = faceRect.size.height + expansionSize * 3
                // additional end
                let ciimage = ciImage.cropped(to: faceRect)  // Swift 3 use cropping(to:)
                let imageRep = NSCIImageRep(ciImage: ciimage)
                let nsImage = NSImage(size: imageRep.size)
                nsImage.addRepresentation(imageRep)
                return nsImage
            }  ?? []
    }
}

// For save as png
extension NSImage {
    func save(as fileName: String, fileType: NSBitmapImageRep.FileType = .jpeg, at directory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)) -> Bool {
        guard let tiffRepresentation = tiffRepresentation, directory.isDirectory, !fileName.isEmpty else { return false }
        do {
            try NSBitmapImageRep(data: tiffRepresentation)?
                .representation(using: fileType, properties: [:])?
                .write(to: directory.appendingPathComponent(fileName).appendingPathExtension(fileType.pathExtension))
            return true
        } catch {
            print(error)
            return false
        }
    }
    
    func trim(rect: CGRect) -> NSImage {
        let result = NSImage(size: rect.size)
        result.lockFocus()
        
        let destRect = CGRect(origin: .zero, size: result.size)
        self.draw(in: destRect, from: rect, operation: .copy, fraction: 1.0)
        
        result.unlockFocus()
        return result
    }
}
extension URL {
    var isDirectory: Bool {
        return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}
extension NSBitmapImageRep.FileType {
    var pathExtension: String {
        switch self {
        case .bmp:
            return "bmp"
        case .gif:
            return "gif"
        case .jpeg:
            return "jpg"
        case .jpeg2000:
            return "jp2"
        case .png:
            return "png"
        case .tiff:
            return "tif"
        @unknown default:
            fatalError()
        }
    }
}


// For edit nsimages
extension NSImage {
    
    /// The height of the image.
    var height: CGFloat {
        return size.height
    }
    
    /// The width of the image.
    var width: CGFloat {
        return size.width
    }
    
    // MARK: Resizing
    /// Resize the image to the given size.
    ///
    /// - Parameter size: The size to resize the image to.
    /// - Returns: The resized image.
    func resize(withSize targetSize: NSSize) -> NSImage? {
        let frame = NSRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
        guard let representation = self.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }
        let image = NSImage(size: targetSize, flipped: false, drawingHandler: { (_) -> Bool in
            return representation.draw(in: frame)
        })
        
        return image
    }
    
    /// Copy the image and resize it to the supplied size, while maintaining it's
    /// original aspect ratio.
    ///
    /// - Parameter size: The target size of the image.
    /// - Returns: The resized image.
    func resizeMaintainingAspectRatio(withSize targetSize: NSSize) -> NSImage? {
        let newSize: NSSize
        let widthRatio  = targetSize.width / self.width
        let heightRatio = targetSize.height / self.height
        
        if widthRatio > heightRatio {
            newSize = NSSize(width: floor(self.width * widthRatio),
                             height: floor(self.height * widthRatio))
        } else {
            newSize = NSSize(width: floor(self.width * heightRatio),
                             height: floor(self.height * heightRatio))
        }
        return self.resize(withSize: newSize)
    }
    
    // MARK: Cropping
    /// Resize the image, to nearly fit the supplied cropping size
    /// and return a cropped copy the image.
    ///
    /// - Parameter size: The size of the new image.
    /// - Returns: The cropped image.
    func crop(toSize targetSize: NSSize) -> NSImage? {
        guard let resizedImage = self.resizeMaintainingAspectRatio(withSize: targetSize) else {
            return nil
        }
        let x     = floor((resizedImage.width - targetSize.width) / 2)
        let y     = floor((resizedImage.height - targetSize.height) / 2)
        let frame = NSRect(x: x, y: y, width: targetSize.width, height: targetSize.height)
        
        guard let representation = resizedImage.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }
        
        let image = NSImage(size: targetSize,
                            flipped: false,
                            drawingHandler: { (destinationRect: NSRect) -> Bool in
                                return representation.draw(in: destinationRect)
        })
        
        return image
    }
    
}

// For get NSClipView center
class CenteringClipView: NSClipView {
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        guard let documentView = documentView else { return super.constrainBoundsRect(proposedBounds) }
        
        var newClipBoundsRect = super.constrainBoundsRect(proposedBounds)
        
        // Get the `contentInsets` scaled to the future bounds size.
        let insets = convertedContentInsetsToProposedBoundsSize(newClipBoundsRect.size)
        
        // Get the insets in terms of the view geometry edges, accounting for flippedness.
        let minYInset = isFlipped ? insets.top : insets.bottom
        let maxYInset = isFlipped ? insets.bottom : insets.top
        let minXInset = insets.left
        let maxXInset = insets.right
        
        /*
         Get and outset the `documentView`'s frame by the scaled contentInsets.
         The outset frame is used to align and constrain the `newClipBoundsRect`.
         */
        let documentFrame = documentView.frame
        let outsetDocumentFrame = NSRect(x: documentFrame.minX - minXInset,
                                         y: documentFrame.minY - minYInset,
                                         width: (documentFrame.width + (minXInset + maxXInset)),
                                         height: documentFrame.height + (minYInset + maxYInset))
        
        if newClipBoundsRect.width > outsetDocumentFrame.width {
            /*
             If the clip bounds width is larger than the document, center the
             bounds around the document.
             */
            newClipBoundsRect.origin.x = outsetDocumentFrame.minX - (newClipBoundsRect.width - outsetDocumentFrame.width) / 2.0
        }
        else if newClipBoundsRect.width < outsetDocumentFrame.width {
            /*
             Otherwise, the document is wider than the clip rect. Make sure that
             the clip rect stays within the document frame.
             */
            if newClipBoundsRect.maxX > outsetDocumentFrame.maxX {
                // The clip rect is outside the maxX edge of the document, bring it in.
                newClipBoundsRect.origin.x = outsetDocumentFrame.maxX - newClipBoundsRect.width
            }
            else if newClipBoundsRect.minX < outsetDocumentFrame.minX {
                // The clip rect is outside the minX edge of the document, bring it in.
                newClipBoundsRect.origin.x = outsetDocumentFrame.minX
            }
        }
        
        if newClipBoundsRect.height > outsetDocumentFrame.height {
            /*
             If the clip bounds height is larger than the document, center the
             bounds around the document.
             */
            newClipBoundsRect.origin.y = outsetDocumentFrame.minY - (newClipBoundsRect.height - outsetDocumentFrame.height) / 2.0
        }
        else if newClipBoundsRect.height < outsetDocumentFrame.height {
            /*
             Otherwise, the document is taller than the clip rect. Make sure
             that the clip rect stays within the document frame.
             */
            if newClipBoundsRect.maxY > outsetDocumentFrame.maxY {
                // The clip rect is outside the maxY edge of the document, bring it in.
                newClipBoundsRect.origin.y = outsetDocumentFrame.maxY - newClipBoundsRect.height
            }
            else if newClipBoundsRect.minY < outsetDocumentFrame.minY {
                // The clip rect is outside the minY edge of the document, bring it in.
                newClipBoundsRect.origin.y = outsetDocumentFrame.minY
            }
        }
 
        return backingAlignedRect(newClipBoundsRect, options: .alignAllEdgesNearest)
    }
    
    /**
     The `contentInsets` scaled to the scale factor of a new potential bounds
     rect. Used by `constrainBoundsRect(NSRect)`.
     */
    fileprivate func convertedContentInsetsToProposedBoundsSize(_ proposedBoundsSize: NSSize) -> NSEdgeInsets {
        // Base the scale factor on the width scale factor to the new proposedBounds.
        let fromBoundsToProposedBoundsFactor = bounds.width > 0 ? (proposedBoundsSize.width / bounds.width) : 1.0
        
        // Scale the set `contentInsets` by the width scale factor.
        var newContentInsets = contentInsets
        newContentInsets.top *= fromBoundsToProposedBoundsFactor
        newContentInsets.left *= fromBoundsToProposedBoundsFactor
        newContentInsets.bottom *= fromBoundsToProposedBoundsFactor
        newContentInsets.right *= fromBoundsToProposedBoundsFactor
        
        return newContentInsets
    }
}


// For check if string is a IP address
extension String {
    func isIPv4() -> Bool {
        var sin = sockaddr_in()
        return self.withCString({ cstring in inet_pton(AF_INET, cstring, &sin.sin_addr) }) == 1
    }
    
    func isIPv6() -> Bool {
        var sin6 = sockaddr_in6()
        return self.withCString({ cstring in inet_pton(AF_INET6, cstring, &sin6.sin6_addr) }) == 1
    }
    
    func isIpAddress() -> Bool { return self.isIPv6() || self.isIPv4() }
}

