//
//  DataModel.swift
//  ClearPath
//
//  Created by Sathyashri.Muruganandam on 2024-11-02.
//

import AVFoundation
import SwiftUI

@Observable final class DataModel {
    let camera = Camera()
    var viewfinderImage: Image?
    var cgImage: CGImage?
    
    init() {
        Task {
            await handleCameraPreviews()
        }
    }
    
    func handleCameraPreviews() async {
        let imageStream = camera.previewStream

        for await image in imageStream {
            Task { @MainActor in
                viewfinderImage = image.image
                let context = CIContext(options: nil)
                if let cgImage = context.createCGImage(image, from: image.extent) {
                    self.cgImage = cgImage
                }
            }
        }
    }
}

fileprivate extension CIImage {
    var image: Image? {
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(self, from: self.extent) else { return nil }
        return Image(decorative: cgImage, scale: 1, orientation: .up)
    }
}

fileprivate extension Image.Orientation {
    init(_ cgImageOrientation: CGImagePropertyOrientation) {
        switch cgImageOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        }
    }
}
