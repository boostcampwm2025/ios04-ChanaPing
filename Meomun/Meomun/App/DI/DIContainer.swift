//
//  DIContainer.swift
//  Meomun
//
//  Created by hoon on 2/3/26.
//

import Foundation
import SwiftData

enum MessageStorageKey: String {
    case swiftData
    case inMemory
}

final class DIContainer {
    private static var shared = DIContainer()

    private init() { }

    private let lock = NSRecursiveLock()
    private var instances: [ObjectIdentifier: Any] = [:]
    private var factories: [ObjectIdentifier: () -> Any] = [:]
    private var keyedInstances: [KeyedIdentifier: Any] = [:]
    private var keyedFactories: [KeyedIdentifier: () -> Any] = [:]

    private struct KeyedIdentifier: Hashable {
        let typeId: ObjectIdentifier
        let key: AnyHashable

        func hash(into hasher: inout Hasher) {
            hasher.combine(typeId)
            hasher.combine(key)
        }

        static func == (lhs: KeyedIdentifier, rhs: KeyedIdentifier) -> Bool {
            lhs.typeId == rhs.typeId && lhs.key == rhs.key
        }
    }

    static func register<T>(_ dependency: T) {
        shared.register(dependency, as: T.self)
    }

    static func register<T>(_ dependency: T, key: AnyHashable) {
        shared.register(dependency, as: T.self, key: key)
    }

    static func registerFactory<T>(_ type: T.Type = T.self, factory: @escaping () -> T) {
        shared.registerFactory(type, factory: factory)
    }

    static func registerFactory<T>(_ type: T.Type = T.self, key: AnyHashable, factory: @escaping () -> T) {
        shared.registerFactory(type, key: key, factory: factory)
    }

    static func resolve<T>() -> T? {
        shared.resolve(T.self)
    }

    static func resolve<T>(key: AnyHashable) -> T? {
        shared.resolve(T.self, key: key)
    }

    static func resolveOrDie<T>() -> T {
        shared.resolveOrDie(T.self)
    }

    static func resolveOrDie<T>(key: AnyHashable) -> T {
        shared.resolveOrDie(T.self, key: key)
    }

    private func register<T>(_ dependency: T, as type: T.Type) {
        lock.lock()
        defer { lock.unlock() }
        let key = ObjectIdentifier(type)
        instances[key] = dependency as Any
    }

    private func register<T>(_ dependency: T, as type: T.Type, key: AnyHashable) {
        lock.lock()
        defer { lock.unlock() }
        let id = KeyedIdentifier(typeId: ObjectIdentifier(type), key: key)
        keyedInstances[id] = dependency as Any
    }

    private func registerFactory<T>(_ type: T.Type, factory: @escaping () -> T) {
        lock.lock()
        defer { lock.unlock() }
        let key = ObjectIdentifier(type)
        factories[key] = factory
    }

    private func registerFactory<T>(_ type: T.Type, key: AnyHashable, factory: @escaping () -> T) {
        lock.lock()
        defer { lock.unlock() }
        let id = KeyedIdentifier(typeId: ObjectIdentifier(type), key: key)
        keyedFactories[id] = factory
    }

    private func resolve<T>(_ type: T.Type) -> T? {
        lock.lock()
        defer { lock.unlock() }
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

    private func resolve<T>(_ type: T.Type, key: AnyHashable) -> T? {
        lock.lock()
        defer { lock.unlock() }
        let id = KeyedIdentifier(typeId: ObjectIdentifier(type), key: key)

        if let existing = keyedInstances[id] as? T {
            return existing
        }

        if let factory = keyedFactories[id] {
            let created = factory()
            keyedInstances[id] = created
            return created as? T
        }

        return nil
    }

    private func resolveOrDie<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        let dependency: T? = resolve(type)

        guard let dependency else {
            AppLog.error("\(key) Dependency가 없음", category: .diContainer)
            #if DEBUG
            assertionFailure("\(key) Dependency가 없음")
            #endif
            preconditionFailure("\(key) Dependency가 없음")
        }

        return dependency
    }

    private func resolveOrDie<T>(_ type: T.Type, key: AnyHashable) -> T {
        let name = String(describing: type)
        let dependency: T? = resolve(type, key: key)

        guard let dependency else {
            AppLog.error("\(name) Dependency가 없음 (key: \(key))", category: .diContainer)
            #if DEBUG
            assertionFailure("\(name) Dependency가 없음 (key: \(key))")
            #endif
            preconditionFailure("\(name) Dependency가 없음 (key: \(key))")
        }

        return dependency
    }
}

extension DIContainer {
    static func registerDependencies() {
        registerInfra()
        registerData()
        registerDomain()
        registerPresentationFactories()
        registerPresentationStores()
    }

    @MainActor
    static func registerAsyncDependencies() {
        registerMarker()
    }
}

private extension DIContainer {
    static func registerInfra() {
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
    }

    static func registerData() {
        DIContainer.registerFactory(MessageStorage.self, key: MessageStorageKey.swiftData) {
            let container: ModelContainer = DIContainer.resolveOrDie()
            return MessageSwiftDataStorage(container: container)
        }
        DIContainer.registerFactory(MessageStorage.self, key: MessageStorageKey.inMemory) {
            MessageInMemoryStorage.shared
        }
        DIContainer.registerFactory(MessageRepository.self) {
            let storage: MessageStorage = DIContainer.resolveOrDie(key: MessageStorageKey.swiftData)
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
    }

    static func registerDomain() {
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
    }

    static func registerPresentationFactories() {
        DIContainer.registerFactory(MessageComposerStoreFactory.self) {
            let createMessage: CreateMessageUseCase = DIContainer.resolveOrDie()
            let reverseGeocoding: ReverseGeocodeUseCase = DIContainer.resolveOrDie()
            return MessageComposerStoreFactory(
                createMessage: createMessage,
                reverseGeocoding: reverseGeocoding
            )
        }
        DIContainer.registerFactory(PlaceSearchStoreFactory.self) {
            let searchPlaces: SearchNearbyPlaceUseCase = DIContainer.resolveOrDie()
            return PlaceSearchStoreFactory(searchPlaces: searchPlaces)
        }
        DIContainer.registerFactory(SpaceStoreFactory.self) {
            let fetchPlaceMessages: FetchPlaceMessagesUseCase = DIContainer.resolveOrDie()
            let deleteMessages: DeleteMessagesUseCase = DIContainer.resolveOrDie()
            return SpaceStoreFactory(
                fetchPlaceMessagesUseCase: fetchPlaceMessages,
                deleteMessagesUseCase: deleteMessages
            )
        }
        DIContainer.registerFactory(TimelineListStoreFactory.self) {
            let fetchRecent: FetchRecentMessagesUseCase = DIContainer.resolveOrDie()
            let deleteMessages: DeleteMessagesUseCase = DIContainer.resolveOrDie()
            return TimelineListStoreFactory(
                fetchRecentMessagesUseCase: fetchRecent,
                deleteMessagesUseCase: deleteMessages
            )
        }
    }

    @MainActor
    static func registerMarker() {
        DIContainer.registerFactory(LeafMarkerUpdater.self) {
            LeafMarkerUpdater()
        }
        DIContainer.registerFactory(ClusterMarkerUpdater.self) {
            ClusterMarkerUpdater()
        }
        DIContainer.registerFactory(MarkerFactoryProtocol.self) {
            NaverMarkerFactory()
        }
        DIContainer.registerFactory(ClustererFactoryProtocol.self) {
            let leafMarkerUpdater: LeafMarkerUpdater = DIContainer.resolveOrDie()
            let clusterMarkerUpdater: ClusterMarkerUpdater = DIContainer.resolveOrDie()
            return NaverClustererFactory(leaf: leafMarkerUpdater, cluster: clusterMarkerUpdater)
        }
        DIContainer.registerFactory(MessageRotationAnimating.self) {
            MessageRotationAnimator()
        }
        DIContainer.registerFactory(BubbleImageRendering.self) {
            BubbleImageRenderer()
        }
        DIContainer.registerFactory(MessageMarkerManager.self) {
            let markerFactory: MarkerFactoryProtocol = DIContainer.resolveOrDie()
            let clustererFactory: ClustererFactoryProtocol = DIContainer.resolveOrDie()
            let rotationAnimator: MessageRotationAnimating = DIContainer.resolveOrDie()
            let bubbleImageRenderer: BubbleImageRendering = DIContainer.resolveOrDie()
            return MessageMarkerManager(
                markerFactory: markerFactory,
                clustererFactory: clustererFactory,
                rotationAnimator: rotationAnimator,
                bubbleImageRenderer: bubbleImageRenderer
            )
        }
    }

    static func registerPresentationStores() {
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
        DIContainer.registerFactory(SettingStore.self) {
            let appSettingsOpener: AppSettingsOpening = DIContainer.resolveOrDie()
            let resetMessages: ResetMessagesUseCase = DIContainer.resolveOrDie()
            return SettingStore(appSettingsOpener: appSettingsOpener, resetMessagesUseCase: resetMessages)
        }
    }
}
