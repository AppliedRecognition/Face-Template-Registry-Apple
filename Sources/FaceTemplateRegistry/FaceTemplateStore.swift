//
//  FaceTemplateStore.swift
//
//
//  Created by Jakub Dolejs on 28/07/2025.
//

import Foundation
import VerIDCommonTypes

actor FaceTemplateStore<V: FaceTemplateVersion, D: FaceTemplateData> {
    
    private var faceTemplates: [TaggedFaceTemplate<V, D>]
    
    init(initialTemplates: [TaggedFaceTemplate<V, D>]) {
        self.faceTemplates = initialTemplates
    }
    
    var all: [TaggedFaceTemplate<V, D>] {
        return self.faceTemplates
    }
    
    var identifiers: Set<String> {
        return Set(self.faceTemplates.map { $0.identifier })
    }
    
    func append(_ template: TaggedFaceTemplate<V, D>) {
        self.faceTemplates.append(template)
    }
    
    func getByIdentifier(_ identifier: String) -> [FaceTemplate<V, D>] {
        return self.faceTemplates
            .filter { $0.identifier == identifier }
            .map { $0.faceTemplate }
    }
}
