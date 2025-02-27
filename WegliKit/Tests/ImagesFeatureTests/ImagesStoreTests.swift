// Created for weg-li in 2021.

import Combine
import ComposableArchitecture
import ComposableCoreLocation
import ImagesFeature
import L10n
import PhotoLibraryAccessClient
import SharedModels
import XCTest

class ImagesStoreTests: XCTestCase {
  let scheduler = DispatchQueue.immediate.eraseToAnyScheduler()
  
  func test_addPhoto_shouldUpdateState() {
    let creationDate: Date = .init(timeIntervalSince1970: 0)
    let coordinate: CoordinateRegion.Coordinate = .init(latitude: 23.32, longitude: 13.31)
    
    let pencilImage = PickerImageResult(
      id: "pencil",
      imageUrl: .init(string: ""),
      coordinate: coordinate,
      creationDate: creationDate
    )
    let trashImage = PickerImageResult(
      id: "trash",
      imageUrl: .init(string: ""),
      coordinate: coordinate,
      creationDate: creationDate
    )
    let heartImage = PickerImageResult(
      id: "heart",
      imageUrl: .init(string: ""),
      coordinate: coordinate,
      creationDate: creationDate
    )
    
    var textItems = [
      TextItem(id: pencilImage.id, text: "HH.TV 3000"),
      TextItem(id: trashImage.id, text: "Trash"),
      TextItem(id: heartImage.id, text: "B-MB 1985"),
      TextItem(id: trashImage.id, text: "Trash"),
      TextItem(id: heartImage.id, text: "B-MB 1985")
    ]
    
    let store = TestStore(
      initialState: ImagesViewState(
        showImagePicker: false,
        storedPhotos: [],
        coordinateFromImagePicker: .zero
      ),
      reducer: imagesReducer,
      environment: ImagesViewEnvironment(
        mainQueue: .immediate,
        backgroundQueue: .immediate,
        photoLibraryAccessClient: .noop,
        textRecognitionClient: .init(recognizeText: { _ in
          Just([textItems.removeFirst()])
            .ignoreFailure(setFailureType: VisionError.self)
            .eraseToEffect()
        })
      )
    )
    
    store.send(.setPhotos([pencilImage, trashImage, heartImage])) {
      $0.storedPhotos = [
        pencilImage,
        trashImage,
        heartImage
      ]
      $0.isRecognizingTexts = true
    }
    store.receive(.setImageCoordinate(coordinate.asCLLocationCoordinate2D)) {
      $0.pickerResultCoordinate = coordinate.asCLLocationCoordinate2D
    }
    store.receive(.setImageCreationDate(creationDate)) {
      $0.pickerResultDate = creationDate
    }
    store.receive(.textRecognitionCompleted(.success([TextItem(id: pencilImage.id, text: "HH.TV 3000")]))) {
      $0.isRecognizingTexts = false
      $0.licensePlates = [TextItem(id: pencilImage.id, text: "HH TV 3000")]
    }
    store.receive(.textRecognitionCompleted(.success([TextItem(id: trashImage.id, text: "Trash")])))
    store.receive(.textRecognitionCompleted(.success([TextItem(id: heartImage.id, text: "B-MB 1985")]))) {
      $0.licensePlates = [
        TextItem(id: pencilImage.id, text: "HH TV 3000"),
        TextItem(id: heartImage.id, text: "B MB 1985")
      ]
    }
    
    store.send(.image(id: pencilImage.id, action: .removePhoto)) {
      $0.licensePlates = [
        TextItem(id: heartImage.id, text: "B MB 1985")
      ]
      $0.storedPhotos = [
        trashImage,
        heartImage
      ]
    }
    store.receive(.setImageCoordinate(coordinate.asCLLocationCoordinate2D))
    store.receive(.setImageCreationDate(creationDate))
  }
  
  func test_removePhoto_shouldUpdateState() {
    let image1 = UIImage(systemName: "pencil")!
    let id1 = UUID().uuidString
    let storableImage1 = PickerImageResult(id: id1, uiImage: image1)
    
    let image2 = UIImage(systemName: "pencil")!
    let id2 = UUID().uuidString
    let storableImage2 = PickerImageResult(id: id2, uiImage: image2)
    
    let store = TestStore(
      initialState: ImagesViewState(
        showImagePicker: false,
        storedPhotos: [storableImage1, storableImage2],
        coordinateFromImagePicker: .zero
      ),
      reducer: imagesReducer,
      environment: ImagesViewEnvironment(
        mainQueue: .immediate,
        backgroundQueue: .immediate,
        photoLibraryAccessClient: .noop,
        textRecognitionClient: .noop
      )
    )
    
    store.send(.image(id: id1, action: .removePhoto)) {
      $0.storedPhotos = [storableImage2]
    }
  }
  
  func test_selectMultiplePhotos_shouldAddPhotosAndSetCoordinate() {
    let store = TestStore(
      initialState: ImagesViewState(
        showImagePicker: false,
        storedPhotos: [],
        coordinateFromImagePicker: .zero
      ),
      reducer: imagesReducer,
      environment: ImagesViewEnvironment(
        mainQueue: scheduler,
        backgroundQueue: .immediate,
        photoLibraryAccessClient: .noop,
        textRecognitionClient: .noop
      )
    )
      
    let creationDate: Date = .init(timeIntervalSince1970: 0)
    let coordinate: CoordinateRegion.Coordinate = .init(latitude: 23.32, longitude: 13.31)

    let pencilImage = PickerImageResult(
      id: "pencil",
      imageUrl: .init(string: ""),
      coordinate: coordinate,
      creationDate: creationDate
    )
    let trashImage = PickerImageResult(
      id: "trash",
      imageUrl: .init(string: ""),
      coordinate: .init(latitude: 36.32, longitude: 0.31),
      creationDate: creationDate
    )
    
    store.send(.setPhotos([pencilImage, trashImage])) {
      $0.isRecognizingTexts = true
      $0.storedPhotos = [pencilImage, trashImage]
    }
    store.receive(.setImageCoordinate(coordinate.asCLLocationCoordinate2D)) {
      $0.pickerResultCoordinate = coordinate.asCLLocationCoordinate2D
    }
    store.receive(.setImageCreationDate(creationDate)) {
      $0.pickerResultDate = creationDate
    }
  }
  
  func test_selectMultiplePhotos_withSmallCoordinateUpdateShouldOnlySetCoordinateOnce() {
    let store = TestStore(
      initialState: ImagesViewState(
        showImagePicker: false,
        storedPhotos: [],
        coordinateFromImagePicker: .zero
      ),
      reducer: imagesReducer,
      environment: ImagesViewEnvironment(
        mainQueue: scheduler,
        backgroundQueue: .immediate,
        photoLibraryAccessClient: .noop,
        textRecognitionClient: .noop
      )
    )
    
    let creationDate: Date = .init(timeIntervalSince1970: 0)
    let coordinate: CoordinateRegion.Coordinate = .init(latitude: 23.32, longitude: 13.31)
    
    let pencilImage = PickerImageResult(
      id: "pencil",
      imageUrl: .init(string: ""),
      coordinate: coordinate,
      creationDate: creationDate
    )
    let trashImage = PickerImageResult(
      id: "trash",
      imageUrl: .init(string: ""),
      coordinate: .init(latitude: 36.32, longitude: 0.31),
      creationDate: creationDate
    )
    
    store.send(.setPhotos([pencilImage, trashImage])) {
      $0.isRecognizingTexts = true
      $0.storedPhotos = [pencilImage, trashImage]
    }
    store.receive(.setImageCoordinate(coordinate.asCLLocationCoordinate2D)) {
      $0.pickerResultCoordinate = coordinate.asCLLocationCoordinate2D
    }
    store.receive(.setImageCreationDate(creationDate)) {
      $0.pickerResultDate = creationDate
    }
  }
  
  func test_addPhotosButtonTapped_shouldRequestAccess_andPresentPicker_whenAuthorised() {
    let subject = CurrentValueSubject<PhotoLibraryAuthorizationStatus, Never>(.authorized)
    let accessClient = PhotoLibraryAccessClient(
      requestAuthorization: {
        Effect(subject)
      },
      authorizationStatus: { .notDetermined }
    )
    
    let store = TestStore(
      initialState: ImagesViewState(
        showImagePicker: false,
        storedPhotos: [],
        coordinateFromImagePicker: .zero
      ),
      reducer: imagesReducer,
      environment: ImagesViewEnvironment(
        mainQueue: scheduler,
        backgroundQueue: .immediate,
        photoLibraryAccessClient: accessClient,
        textRecognitionClient: .noop
      )
    )
    
    store.send(.addPhotosButtonTapped)
    store.receive(.requestPhotoLibraryAccess)
    store.receive(.requestPhotoLibraryAccessResult(.authorized))
    store.receive(.setShowImagePicker(true)) {
      $0.showImagePicker = true
    }
    subject.send(completion: .finished)
  }
  
  func test_addPhotosButtonTapped_shouldRequestAccess_andPresentPicker_whenLimited() {
    let subject = CurrentValueSubject<PhotoLibraryAuthorizationStatus, Never>(.limited)
    let accessClient = PhotoLibraryAccessClient(
      requestAuthorization: {
        Effect(subject)
      },
      authorizationStatus: { .notDetermined }
    )
    
    let store = TestStore(
      initialState: ImagesViewState(
        showImagePicker: false,
        storedPhotos: [],
        coordinateFromImagePicker: .zero
      ),
      reducer: imagesReducer,
      environment: ImagesViewEnvironment(
        mainQueue: scheduler,
        backgroundQueue: .immediate,
        photoLibraryAccessClient: accessClient,
        textRecognitionClient: .noop
      )
    )
    
    store.send(.addPhotosButtonTapped)
    store.receive(.requestPhotoLibraryAccess)
    store.receive(.requestPhotoLibraryAccessResult(.limited))
    store.receive(.setShowImagePicker(true)) {
      $0.showImagePicker = true
    }
    subject.send(completion: .finished)
  }
  
  func test_addPhotosButtonTapped_shouldRequestAccess_andPresentAlert_whenAccessIsDenied() {
    let subject = CurrentValueSubject<PhotoLibraryAuthorizationStatus, Never>(.denied)
    let accessClient = PhotoLibraryAccessClient(
      requestAuthorization: {
        Effect(subject)
      },
      authorizationStatus: { .notDetermined }
    )
    
    let store = TestStore(
      initialState: ImagesViewState(
        showImagePicker: false,
        storedPhotos: [],
        coordinateFromImagePicker: .zero
      ),
      reducer: imagesReducer,
      environment: ImagesViewEnvironment(
        mainQueue: scheduler,
        backgroundQueue: .immediate,
        photoLibraryAccessClient: accessClient,
        textRecognitionClient: .noop
      )
    )
    
    store.send(.addPhotosButtonTapped)
    store.receive(.requestPhotoLibraryAccess)
    store.receive(.requestPhotoLibraryAccessResult(.denied)) {
      $0.alert = .init(title: TextState(L10n.Photos.Alert.accessDenied))
    }
    subject.send(completion: .finished)
  }
  
  func test_dismissAlert_shouldUpdateState() {
    let store = TestStore(
      initialState: ImagesViewState(
        alert: AlertState(title: TextState(L10n.Photos.Alert.accessDenied)),
        showImagePicker: false,
        storedPhotos: [],
        coordinateFromImagePicker: .zero
      ),
      reducer: imagesReducer,
      environment: ImagesViewEnvironment(
        mainQueue: scheduler,
        backgroundQueue: .immediate,
        photoLibraryAccessClient: .noop,
        textRecognitionClient: .noop
      )
    )
    
    store.send(.dismissAlert) {
      $0.alert = nil
    }
  }
  
  func test_addPhotosButtonTapped_() {
    let subject = CurrentValueSubject<PhotoLibraryAuthorizationStatus, Never>(.denied)
    let accessClient = PhotoLibraryAccessClient(
      requestAuthorization: {
        Effect(subject)
      },
      authorizationStatus: { .notDetermined }
    )
    
    let store = TestStore(
      initialState: ImagesViewState(
        showImagePicker: false,
        storedPhotos: [],
        coordinateFromImagePicker: .zero
      ),
      reducer: imagesReducer,
      environment: ImagesViewEnvironment(
        mainQueue: scheduler,
        backgroundQueue: .immediate,
        photoLibraryAccessClient: accessClient,
        textRecognitionClient: .noop
      )
    )
    
    store.send(.addPhotosButtonTapped)
    store.receive(.requestPhotoLibraryAccess)
    store.receive(.requestPhotoLibraryAccessResult(.denied)) {
      $0.alert = .init(title: TextState(L10n.Photos.Alert.accessDenied))
    }
    subject.send(completion: .finished)
  }
}
