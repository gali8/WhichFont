//
//  Image.swift
//  WhichFont
//
//  Created by Daniele on 27/07/17.
//  Copyright © 2017 nexor. All rights reserved.
//

import UIKit
import AVFoundation

extension CALayer {
    func asImage(rect: CGRect) -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: rect)
        return renderer.image { rendererContext in
            self.render(in: rendererContext.cgContext)
        }
    }
}

extension CIImage {
    func toImage() -> UIImage
    {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(self, from: self.extent)!
        return cgImage.toImage()
    }
}

extension CGImage {
    func toImage(orientation: UIImageOrientation? = nil) -> UIImage
    {
        let image = UIImage(cgImage: self, scale: UIScreen.main.scale, orientation: .right)
        return image
    }
}
