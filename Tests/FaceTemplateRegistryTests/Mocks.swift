//
//  Mocks.swift
//  
//
//  Created by Jakub Dolejs on 29/07/2025.
//

import Foundation
import UIKit
import FaceTemplateRegistry
import VerIDCommonTypes

struct Mocks {
    static var image: Image = {
        let size = CGSize(width: 128, height: 128)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return Image(cgImage: image.cgImage!)!
    }()
    
    static func face(_ template: Float) -> Face {
        return Face(bounds: CGRect(x: CGFloat(template), y: 10000, width: 10000, height: 10000), angle: EulerAngle(), quality: 10, landmarks: [], leftEye: .zero, rightEye: .zero)
    }
    
    static func generateUsers<V: FaceTemplateVersion>(count: Int, templatesPerUserCount: Int, startingUserId: Int=0) -> [TaggedFaceTemplate<V, Float>] {
        return (startingUserId..<(startingUserId+count)).map { i in
            let identifier = "User \(i)"
            return (0..<templatesPerUserCount).map { j in
                let data = Float(i) + Float(j) / 10000
                return TaggedFaceTemplate(
                    faceTemplate: FaceTemplate<V, Float>(data: data),
                    identifier: identifier
                )
            }
        }.flatMap { $0 }
    }
    
    static func createRegistry<V: FaceTemplateVersion>(for version: V.Type, userCount: Int, templatesPerUserCount: Int, startingUserId: Int=0) -> FaceTemplateRegistry<V, Float, MockFaceRecognition<V>> {
        let templates: [TaggedFaceTemplate<V, Float>] = generateUsers(count: userCount, templatesPerUserCount: templatesPerUserCount, startingUserId: startingUserId)
        let recognition = MockFaceRecognition<V>()
        return FaceTemplateRegistry(faceRecognition: recognition, faceTemplates: templates)
    }
}
