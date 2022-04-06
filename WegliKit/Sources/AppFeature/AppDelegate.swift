import ComposableArchitecture
import FileClient
import Foundation
import SharedModels
import ReportFeature

public struct AppDelegateState: Equatable {}

public enum AppDelegateAction: Equatable {
  case didFinishLaunching
}

public struct AppDelegateEnvironment {
  public var mainQueue: AnySchedulerOf<DispatchQueue>
  public var backgroundQueue: AnySchedulerOf<DispatchQueue>
  public var fileClient: FileClient

  public init(
    backgroundQueue: AnySchedulerOf<DispatchQueue>,
    mainQueue: AnySchedulerOf<DispatchQueue>,
    fileClient: FileClient
  ) {
    self.backgroundQueue = backgroundQueue
    self.mainQueue = mainQueue
    self.fileClient = fileClient
  }
}


let appDelegateReducer = Reducer<
  AppDelegateState, AppDelegateAction, AppDelegateEnvironment
> { state, action, environment in
  switch action {
  case .didFinishLaunching:
    return .none
  }
}