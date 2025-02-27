import Combine
import ComposableArchitecture
import Foundation
import Helper
import SharedModels

// Interface
/// A Service to send a single notice and all persisted notices from the weg-li API
public struct WegliAPIService {
  public var getNotices: (Bool) -> Effect<[Notice], ApiError>
  public var postNotice: (NoticeInput) -> Effect<Result<Notice, ApiError>, Never>
  public var upload: (UploadImageRequest) async throws -> ImageUploadResponse

  public init(
    getNotices: @escaping (Bool) -> Effect<[Notice], ApiError>,
    postNotice: @escaping (NoticeInput) -> Effect<Result<Notice, ApiError>, Never>,
    upload: @escaping (UploadImageRequest) async throws -> ImageUploadResponse
  ) {
    self.getNotices = getNotices
    self.postNotice = postNotice
    self.upload = upload
  }
}

public extension WegliAPIService {
  static func live(apiClient: APIClient = .live) -> Self {
    Self(
      getNotices: { forceReload in
        let request = GetNoticesRequest(forceReload: forceReload)
        
        return apiClient.dispatch(request)
          .decode(
            type: GetNoticesRequest.ResponseDataType.self,
            decoder: JSONDecoder.noticeDecoder
          )
          .mapError { ApiError(error: $0) }
          .eraseToEffect()
      },
      postNotice: { input in
        let noticePutRequestBody = NoticePutRequestBody(notice: input)
        let body = try? JSONEncoder.noticeEncoder.encode(noticePutRequestBody)
        
        let request = SubmitNoticeRequest(body: body)
        
        return apiClient.dispatch(request)
          .decode(
            type: SubmitNoticeRequest.ResponseDataType.self,
            decoder: JSONDecoder.noticeDecoder
          )
          .mapError { ApiError(error: $0) }
          .catchToEffect()
          .eraseToEffect()
      },
      upload: { imageUploadRequest in
        let responseData = try await apiClient.dispatch(imageUploadRequest)
        return try JSONDecoder.noticeDecoder.decode(ImageUploadResponse.self, from: responseData)
      }
    )
  }
}

public extension WegliAPIService {
  static let noop = Self(
    getNotices: { _ in
      Just([Notice.mock])
        .setFailureType(to: ApiError.self)
        .eraseToEffect()
    },
    postNotice: { _ in
      Just(.mock)
        .setFailureType(to: ApiError.self)
        .catchToEffect()
        .eraseToEffect()
    },
    upload: { _ in
      ImageUploadResponse(
        id: 1,
        key: "",
        filename: "",
        contentType: "",
        byteSize: 0,
        checksum: "",
        createdAt: .init(timeIntervalSince1970: 0),
        signedId: "",
        directUpload: .init(
          url: "",
          headers: [:]
        )
      )
    }
  )
  
  static let failing = Self(
    getNotices: { _ in
      Fail(error: ApiError(error: NetworkRequestError.invalidRequest))
        .eraseToEffect()
    },
    postNotice: { _ in
      Fail(error: ApiError(error: NetworkRequestError.invalidRequest))
        .catchToEffect()
        .eraseToEffect()
    },
    upload: { _ in
      throw NetworkRequestError.badRequest
    }
  )
}
