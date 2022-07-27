///*
//CompareFaceTextures.swift
//Created by Lily Jiang on 7/13/22
//
//This file holds the functions called to compare face images at the end of the app session. This includes cutting up the UV images to target analysis on a specific area, analyzing pixel colors and having a tolerance for lighting changes, etc.
//*/
//
//import UIKit
//
//class CompareFaceTextures {
//    /// returns the pixels that match
//    /// https://stackoverflow.com/questions/35066466/swift-compare-colors-at-cgpoint
//    func findMatchingPixels(aImage: UIImage, _ bImage: UIImage) -> [(CGPoint, UIColor)] {
//        guard aImage.size == bImage.size else { fatalError("images must be the same size") }
//
//        var matchingColors = [(CGPoint, UIColor)]()
//        for y in 0..<Int(aImage.size.height) {
//            for x in 0..<Int(aImage.size.width) {
//                let aColor = aImage.getPixelColor(CGPoint(x: x, y: y))
//                guard bImage.getPixelColor(CGPoint(x: x, y: y)) == aColor else { continue }
//
//                matchingColors.append((CGPoint(x: x, y: y), aColor))
//            }
//        }
//        return matchingColors
//    }
//}
//
//
//extension UIImage {
//    // https://stackoverflow.com/questions/35066466/swift-compare-colors-at-cgpoint
//    func getPixelColor(pos: CGPoint) -> UIColor {
//        let pixelData = CGDataProviderCopyData(CGImageGetDataProvider(self.CGImage))
//        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
//
//        let pixelInfo: Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4
//
//        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
//        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
//        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
//        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
//
//        return UIColor(red: r, green: g, blue: b, alpha: a)
//    }
//
//    // https://www.hackingwithswift.com/example-code/media/how-to-read-the-average-color-of-a-uiimage-using-ciareaaverage
//    // might be useful for determining lighting differences? to
//    var averageColor: UIColor? {
//            guard let inputImage = CIImage(image: self) else { return nil }
//            let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)
//
//            guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
//            guard let outputImage = filter.outputImage else { return nil }
//
//            var bitmap = [UInt8](repeating: 0, count: 4)
//            let context = CIContext(options: [.workingColorSpace: kCFNull])
//            context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
//
//            return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
//        }
//
//}
//
//
//// usage:
////let matchingPixels = findMatchingPixels(UIImage(named: "imageA.png")!, UIImage(named: "imageB.png")!)
////if let colorForOrigin = matchingPixels[0][0] {
////   print("the images have the same color, it is: \(colorForOrigin)")
////} else {
////   print("the images do not have the same color at (0,0)")
////}
