//
//  MockFaceTemplate.swift
//
//
//  Created by Jakub Dolejs on 29/07/2025.
//

import Foundation
import VerIDCommonTypes

struct V1: FaceTemplateVersion {
    static var id: Int = 1
}

struct V2: FaceTemplateVersion {
    static var id: Int = 2
}

extension Float: FaceTemplateData {}
