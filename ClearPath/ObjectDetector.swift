//
//  ObjectDetector.swift
//  ClearPath
//
//  Created by Sathyashri.Muruganandam on 2024-11-02.
//

import Vision
import SwiftUI
import AVFoundation
import Combine

class ObjectDetector {
    private let detectionSubject = PassthroughSubject<[CGRect], Never>()
    
    public var detectionPublisher: AnyPublisher<[CGRect], Never> {
        detectionSubject
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    let carModel: CarModel = {
        do {
            let configuration = MLModelConfiguration()
            return try CarModel(configuration: configuration)
        } catch {
            print(error)
            fatalError("Couldn't create HRModel")
        }
    }()
    
    func detect(in image: CGImage) {
        var rects: [CGRect] = []
        do {
            let output = try carModel.prediction(input: .init(imageWith: image, iouThreshold: 0.5, confidenceThreshold: 0.4))
            for array in output.coordinatesShapedArray {
                for i in stride(from: 0, to: array.shape[0], by: 4) {
                    let originX = CGFloat(array[scalarAt: i])
                    let originY = CGFloat(array[scalarAt: i + 1])
                    let width = CGFloat(array[scalarAt: i + 2])
                    let height = CGFloat(array[scalarAt: i + 3])
                    
                    let rect = CGRect(x: originX, y: originY, width: width, height: height)
                    rects.append(rect)
                }
            }
        } catch {
            print(error)
        }
        
        let faceDetectionRequest = VNDetectHumanRectanglesRequest { (request, error) in
            if let error = error {
                print("People detection error: \(error)")
                return
            }
            
            guard let observations = request.results as? [VNHumanObservation] else {
                print("No people detected")
                return
            }
            observations.forEach { observation in
                rects.append(observation.boundingBox)
            }
        }
        let requestHandler = VNImageRequestHandler(cgImage: image, options: [:])
        
        do {
            try requestHandler.perform([faceDetectionRequest])
            detectionSubject.send(rects)
        } catch {
            print("Failed to perform request: \(error)")
        }
    }
}
