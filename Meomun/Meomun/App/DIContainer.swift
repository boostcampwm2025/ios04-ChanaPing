//
//  DIContainer.swift
//  Meomun
//
//  Created by hoon on 2/3/26.
//

final class DIContainer {
    private static var shared = DIContainer()

    private init() { }

    private var dependencies: [String: Any] = [:]

    static func register<T>(_ dependency: T) {
        shared.register(dependency)
    }

    static func resolve<T>() -> T? {
        shared.resolve()
    }

    private func register<T>(_ dependency: T) {
        let key = String(describing: T.self)
        dependencies[key] = dependency as Any
    }

    private func resolve<T>() -> T? {
        let key = String(describing: T.self)
        let dependency = dependencies[key] as? T

        guard let dependency else {
            AppLog.error("\(key) Dependency가 없음", category: .DIContainer)
            #if DEBUG
            assertionFailure("\(key) Dependency가 없음")
            #endif
            return nil
        }

        return dependency
    }
}

extension DIContainer {
    static func registerDependencies() {
        let networkMonitor = NetworkMonitor()
        let appSettingsOpner = AppSettingsOpener()
        let locationProvider = LocationProvider()

        // MARK: - Data

        let messageStorage = MessageSwiftDataStorage.shared
        let messageRepositoryImpl = MessageRepositoryImpl(storage: messageStorage)

        // MARK: - Domain

        let getNearbyMessagesUseCaseImpl = GetNearbyMessagesUseCaseImpl(messageRepository: messageRepositoryImpl)
        let fetchRecentMessagesUseCaseImpl = FetchRecentMessagesUseCaseImpl(repository: messageRepositoryImpl)
        let deleteMessagesUseCaseImpl = DeleteMessagesUseCaseImpl(messageRepository: messageRepositoryImpl)
        let resetMessageUseCaseImpl = ResetMessagesUseCaseImpl(messageRepository: messageRepositoryImpl)

        // MARK: - Presentation

        let rootStore = RootStore(locationProvider: locationProvider, appSettingsOpener: appSettingsOpner)
        let mainTabStore = MainTabStore()
        let mapStore = MapStore(getNearbyMessagesUseCase: getNearbyMessagesUseCaseImpl, networkMonitor: networkMonitor)
        let timeLineListStore = TimelineListStore(fetchRecentMessagesUseCase: fetchRecentMessagesUseCaseImpl, deleteMessagesUseCase: deleteMessagesUseCaseImpl)
        let settingStore = SettingStore(appSettingsOpener: appSettingsOpner, resetMessagesUseCase: resetMessageUseCaseImpl)

        // MARK: - register

        DIContainer.shared.register(locationProvider)
        DIContainer.shared.register(rootStore)
        DIContainer.shared.register(mainTabStore)
        DIContainer.shared.register(mapStore)
        DIContainer.shared.register(timeLineListStore)
        DIContainer.shared.register(settingStore)
    }
}
