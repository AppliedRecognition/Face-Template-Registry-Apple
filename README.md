# Face template registry

The face template registry manages registration, authentication and identification of faces captured by the [Face capture](https://github.com/AppliedRecognition/Face-Capture-Apple) library.

The registry doesn't persist its data across app restarts. It keeps face templates in memory. It's up to the consumer to supply the registry with face templates at initialization.

## Handling different face recognition systems

If you application contains face templates produced by different face recognition systems the face template registry will facilitate migration between the systems and ensure consistency of your face template resources.

The library has two face template registry classes:

1. [FaceTemplateRegistry](./Sources/FaceTemplateRegistry/FaceTemplateRegistry.swift) – handles face templates for a single face recognition system.
2. [FaceTemplateMultiRegistry](./Sources/FaceTemplateRegistry/FaceTemplateMultiRegistry.swift) – coordinates between multiple registries that use different face recognition systems.

## Usage

### Creating an registry instance

#### Single face recognition system

```swift
// Face recognition instance
let faceRecognition: FaceRecognitionArcFace
    
// Tagged face templates to populate the registry
let faceTemplates: [TaggedFaceTemplate<V24, [Float]>]

// Create registry instance
let registry = FaceTemplateRegistry(
    faceRecognition: faceRecognition, 
    faceTemplates: faceTemplates
)
```

#### Multiple face recognition systems

```swift
// First face recognition instance
let faceRecognition1: FaceRecognitionArcFace
    
// Tagged face templates to populate the first registry
let faceTemplates1: [TaggedFaceTemplate<V24, [Float]>>]

// Create first registry instance
let registry1 = FaceTemplateRegistry(
    faceRecognition: faceRecognition1, 
    faceTemplates: faceTemplates1
)

// Second face recognition instance
let faceRecognition2: FaceRecognition3D
    
// Tagged face templates to populate the second registry
let faceTemplates2: [TaggedFaceTemplate<FaceTemplateVersion3D1, [Float]>]

// Create second registry instance
let registry2 = FaceTemplateRegistry(
    faceRecognition: faceRecognition2, 
    faceTemplates: faceTemplates2
)

// Create multi registry
let multiRegistry = try await FaceTemplateMultiRegistry(
    registries: registry1.eraseToAnyFaceTemplateRegistry(),
    registry2.eraseToAnyFaceTemplateRegistry()
)
```

### Face template registration

Extract a face template from the given face and image and register it under a given identifier.

In case there is a similar face already registered under a different identifier the function will throw [`FaceTemplateRegistryError.similarFaceAlreadyRegisteredAs(String, any FaceTemplateProtocol)`](./Sources/FaceTemplateRegistry/Errors.swift). The second parameter of the error is the extracted face template and the third is the score against which the template compared to the user. It's then up to you to decide whether you wish to add the face template to your data set.

```swift
Task {
    // Face recognition instance
    let faceRecognition: FaceRecognitionArcFace
    
    // Tagged face templates to populate the registry
    let faceTemplates: [TaggedFaceTemplate<V24, [Float]>]
    
    // Face to register
    let face: Face
    
    // Image in which the face was detected
    let image: Image
    
    // Identifier with which to tag the face template
    let identifier: String = "User 1"
    
    // Create a registry instance
    let registry = FaceTemplateRegistry(
        faceRecognition: faceRecognition,
        faceTemplates: faceTemplates
    )
    
    do {
        let registeredFaceTemplate = try await registry
            .registerFace(face, image: image, identifier: identifier)
    } catch {
        // Registration failed
    }
}
```

### Face authentication

Extract a face template from the given face and image and compare it to face templates registered under the given identifier.

```swift
Task {
    do {
        let authenticationResult = try await registry
            .authenticateFace(face, image: image, identifier: identifier)
        if authenticationResult.authenticated {
            // The face has been authenticated as 
            // the user represented by the identifier
        }
    } catch {
        // Authentication failed
    }
}
```

### Face identification

Extract a face template the given face and image and compare it agains all registered faces, returning a list of results similar to the face template.

```swift
Task {
    do {
        let identificationResults = try await registry.identifyFace(face, image: image)
        if let identifiedUser = identificationResults.first?.taggedFaceTemplate.identifier {
            // Face identified as identifiedUser
        }
    } catch {
        // Identification failed
    }
}
```

### Monitoring face template additions

When using [FaceTemplateMultiRegistry](./Sources/FaceTemplateRegistry/FaceTemplateMultiRegistry.swift) it's possible that face templates will be automatically enrolled at authentication or identification.
You can get a list of the auto-enrolled face templates from the authentication and identification results.

```swift
// Your multi registry instance
let multiRegistry: FaceTemplateMultiRegistry

// Authentication
let authenticationResult = try await multiRegistry
    .authenticateFace(face, image: image, identifier: identifier)
if authenticationResult.authenticated && !authenticationResult.autoEnrolledFaceTemplates.isEmpty {
    let count = authenticationResult.autoEnrolledFaceTemplates.count
    print("$count face template(s) have been automatically enrolled as $identifier")
}

// Identification
let identificationResults = try await multiRegistry.identifyFace(face, image: image)
if let identification = identificationResults.first, !identification.autoEnrolledFaceTemplates.isEmpty {
    val count = identification.autoEnrolledFaceTemplates.count
    val identifier = identification.taggedFaceTemplate.identifier
    print("$count face template(s) have been automatically enrolled as $identifier")
}
```

#### Using delegate

You can also optionally register a delegate to receive updates when faces are added either by registration or by auto enrolment. This allows you to propagate the updates to your face template source.

```swift
class MyClass: FaceTemplateMultiRegistryDelegate {
    
    let multiRegistry: FaceTemplateMultiRegistry
    
    init(multiRegistry: FaceTemplateMultiRegistry) {
        self.multiRegistry = multiRegistry
        self.multiRegistry.delegate = self
    }
    
    // MARK: FaceTemplateMultiRegistryDelegate
    
    func onFaceTemplatesAdded(_ faceTemplates: [AnyTaggedFaceTemplate]) {
        // faceTemplates are the templates that have been added either 
        // during registration, identification or authentication
    }
}
```
