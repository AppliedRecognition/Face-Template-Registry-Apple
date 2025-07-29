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
    
    func deleteByIdentifier(_ identifier: String) -> [FaceTemplate<V, D>] {
        let index = self.faceTemplates.partition { $0.identifier == identifier }
        let deleted = Array(self.faceTemplates[index...])
        self.faceTemplates.removeSubrange(index...)
        return deleted.map { $0.faceTemplate }
    }
    
    func delete(_ templates: [TaggedFaceTemplate<V, D>]) {
        let deleteSet = Set(templates)
        self.faceTemplates.removeAll { deleteSet.contains($0) }
    }
}
