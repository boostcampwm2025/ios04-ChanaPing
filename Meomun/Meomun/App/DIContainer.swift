//
//  DIContainer.swift
//  Meomun
//
//  Created by hoon on 2/3/26.
//

import SwiftData

final class DIContainer {
    private static var shared = DIContainer()

    private init() { }

    private var instances: [ObjectIdentifier: Any] = [:]
    private var factories: [ObjectIdentifier: () -> Any] = [:]

    static func register<T>(_ dependency: T) {
        shared.register(dependency, as: T.self)
    }

    static func registerFactory<T>(_ type: T.Type = T.self, factory: @escaping () -> T) {
        shared.registerFactory(type, factory: factory)
    }

    static func resolve<T>() -> T? {
        shared.resolve(T.self)
    }

    static func resolveOrDie<T>() -> T {
        shared.resolveOrDie(T.self)
    }

    private func register<T>(_ dependency: T, as type: T.Type) {
        let key = ObjectIdentifier(type)
        instances[key] = dependency as Any
    }

    private func registerFactory<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = ObjectIdentifier(type)
        factories[key] = factory
    }

    private func resolve<T>(_ type: T.Type) -> T? {
        let key = ObjectIdentifier(type)

        if let existing = instances[key] as? T {
            return existing
        }

        if let factory = factories[key] {
            let created = factory()
            instances[key] = created
            return created as? T
        }

        return nil
    }

    private func resolveOrDie<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        let dependency: T? = resolve(type)

        guard let dependency else {
            AppLog.error("\(key) Dependency가 없음", category: .DIContainer)
            #if DEBUG
            assertionFailure("\(key) Dependency가 없음")
            #endif
            preconditionFailure("\(key) Dependency가 없음")
        }

        return dependency
    }
}

extension DIContainer {
    @MainActor
    static func registerDependencies() {
        // MARK: - Infra / App

        let modelContainer = AppDataConfig.makeContainer()
        DIContainer.register(modelContainer)
        DIContainer.registerFactory(NetworkMonitoring.self) { NetworkMonitor() }
        DIContainer.registerFactory(AppSettingsOpening.self) { AppSettingsOpener() }
        DIContainer.registerFactory(LocationProvider.self) { LocationProvider() }
        DIContainer.registerFactory(NetworkClient.self) {
            NetworkClientImpl(decoder: JSONDecoders.iso8601)
        }
        DIContainer.registerFactory(SupabaseService.self) {
            let client: NetworkClient = DIContainer.resolveOrDie()
            return SupabaseServiceImpl(network: client)
        }

        // MARK: - Data

        DIContainer.registerFactory(MessageStorage.self) {
            let container: ModelContainer = DIContainer.resolveOrDie()
            return MessageSwiftDataStorage(container: container)
        }
        DIContainer.registerFactory(MessageRepository.self) {
            let storage: MessageStorage = DIContainer.resolveOrDie()
            return MessageRepositoryImpl(storage: storage)
        }
        DIContainer.registerFactory(PlaceRepository.self) {
            let remote: SupabaseService = DIContainer.resolveOrDie()
            return NaverPlaceSearchRepositoryImpl(remote: remote)
        }
        DIContainer.registerFactory(ReverseGeocodeRepository.self) {
            let remote: SupabaseService = DIContainer.resolveOrDie()
            return ReverseGeocodeRepositoryImpl(remote: remote)
        }

        // MARK: - Domain

        DIContainer.registerFactory(GetNearbyMessagesUseCase.self) {
            let repo: MessageRepository = DIContainer.resolveOrDie()
            return GetNearbyMessagesUseCaseImpl(messageRepository: repo)
        }
        DIContainer.registerFactory(CreateMessageUseCase.self) {
            let repo: MessageRepository = DIContainer.resolveOrDie()
            return CreateMessageUseCaseImpl(messageRepository: repo)
        }
        DIContainer.registerFactory(FetchPlaceMessagesUseCase.self) {
            let repo: MessageRepository = DIContainer.resolveOrDie()
            return FetchPlaceMessagesUseCaseImpl(messageRepository: repo)
        }
        DIContainer.registerFactory(FetchRecentMessagesUseCase.self) {
            let repo: MessageRepository = DIContainer.resolveOrDie()
            return FetchRecentMessagesUseCaseImpl(repository: repo)
        }
        DIContainer.registerFactory(DeleteMessagesUseCase.self) {
            let repo: MessageRepository = DIContainer.resolveOrDie()
            return DeleteMessagesUseCaseImpl(messageRepository: repo)
        }
        DIContainer.registerFactory(ResetMessagesUseCase.self) {
            let repo: MessageRepository = DIContainer.resolveOrDie()
            return ResetMessagesUseCaseImpl(messageRepository: repo)
        }
        DIContainer.registerFactory(ReverseGeocodeUseCase.self) {
            let repo: ReverseGeocodeRepository = DIContainer.resolveOrDie()
            return ReverseGeocodeUseCaseImpl(repository: repo)
        }
        DIContainer.registerFactory(SearchNearbyPlaceUseCase.self) {
            let repo: PlaceRepository = DIContainer.resolveOrDie()
            return SearchNearbyPlaceUseCaseImpl(placeRepository: repo)
        }

        // MARK: - Presentation

        DIContainer.registerFactory(RootStore.self) {
            let locationProvider: LocationProvider = DIContainer.resolveOrDie()
            let appSettingsOpener: AppSettingsOpening = DIContainer.resolveOrDie()
            return RootStore(locationProvider: locationProvider, appSettingsOpener: appSettingsOpener)
        }
        DIContainer.registerFactory(MainTabStore.self) { MainTabStore() }
        DIContainer.registerFactory(MapStore.self) {
            let useCase: GetNearbyMessagesUseCase = DIContainer.resolveOrDie()
            let networkMonitor: NetworkMonitoring = DIContainer.resolveOrDie()
            return MapStore(getNearbyMessagesUseCase: useCase, networkMonitor: networkMonitor)
        }
        DIContainer.registerFactory(TimelineListStore.self) {
            let fetchRecent: FetchRecentMessagesUseCase = DIContainer.resolveOrDie()
            let deleteMessages: DeleteMessagesUseCase = DIContainer.resolveOrDie()
            return TimelineListStore(fetchRecentMessagesUseCase: fetchRecent, deleteMessagesUseCase: deleteMessages)
        }
        DIContainer.registerFactory(SettingStore.self) {
            let appSettingsOpener: AppSettingsOpening = DIContainer.resolveOrDie()
            let resetMessages: ResetMessagesUseCase = DIContainer.resolveOrDie()
            return SettingStore(appSettingsOpener: appSettingsOpener, resetMessagesUseCase: resetMessages)
        }
        DIContainer.registerFactory(MessageMarkerManager.self) {
            let rotationAnimator = MessageRotationAnimator()
            let bubbleImageRenderer = BubbleImageRenderer()
            return MessageMarkerManager(
                rotationAnimator: rotationAnimator,
                bubbleImageRenderer: bubbleImageRenderer
            )
        }
    }
}
