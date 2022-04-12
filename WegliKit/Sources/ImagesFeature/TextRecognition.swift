import ComposableArchitecture
import SwiftUI
import Vision
import SharedModels

public struct TextItem: Identifiable, Equatable {
  public var id: String = UUID().uuidString
  public var text: String = ""
  
  public init(id: String, text: String) {
    self.id = id
    self.text = text
  }
}

public struct TextRecognitionClient {
  public var recognizeText: (StorableImage) -> Effect<[TextItem], VisionError>
  
  public func recognizeText(
    in image: StorableImage,
    on queue: AnySchedulerOf<DispatchQueue>
  ) -> Effect<[TextItem], VisionError> {
    self.recognizeText(image)
      .subscribe(on: queue)
      .eraseToEffect()
  }
}

public extension TextRecognitionClient {
  static let live = Self(
    recognizeText: { image in
        .future { callback in
          guard let cgImage = image.asUIImage?.cgImage else {
            callback(.failure(.init(message: "Can not find cgImage for image")))
            return
          }
          
          // Create a new image-request handler.
          let requestHandler = VNImageRequestHandler(cgImage: cgImage)
          
          // Create a new request to recognize text.
          let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
              callback(.failure(.init(message: "Observations can not be casted to VNRecognizedTextObservation")))
              return
            }
            let textItems = observations
              .compactMap { $0.topCandidates(1).first?.string }
              .map { TextItem(id: image.id, text: $0) }
            callback(.success(textItems))
          }
          
          do {
            try requestHandler.perform([request])
          } catch {
            callback(.failure(.init(message: error.localizedDescription)))
          }
        }
    }
  )
}

public extension TextRecognitionClient {
  static let noop = Self(
    recognizeText: { _ in return .none }
  )
}

public struct VisionError: Equatable, Error {
  public init(message: String = "") {
    self.message = message
  }
  
  public var message = ""
}
