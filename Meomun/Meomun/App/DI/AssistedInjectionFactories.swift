//
//  AssistedInjectionFactories.swift
//  Meomun
//
//  Created by hoon on 2/4/26.
//

import Foundation

struct MessageComposerStoreFactory {
    let createMessage: CreateMessageUseCase
    let reverseGeocoding: ReverseGeocodeUseCase

    func make(
        currentLocation: Coordinate,
        currentPlace: Place?,
        onClose: @escaping (Bool) -> Void
    ) -> MessageComposerStore {
        MessageComposerStore(
            currentLocation: currentLocation,
            currentPlace: currentPlace,
            createMessage: createMessage,
            reverseGeocoding: reverseGeocoding,
            onClose: onClose
        )
    }
}

struct PlaceSearchStoreFactory {
    let searchPlaces: SearchNearbyPlaceUseCase

    func make(
        userLocation: Coordinate?,
        onSelect: @escaping (Place) -> Void,
        onDismiss: @escaping () -> Void
    ) -> PlaceSearchStore {
        PlaceSearchStore(
            searchPlaces: searchPlaces,
            userLocation: userLocation,
            onSelect: onSelect,
            onDismiss: onDismiss
        )
    }
}

struct SpaceStoreFactory {
    let fetchPlaceMessagesUseCase: FetchPlaceMessagesUseCase
    let deleteMessagesUseCase: DeleteMessagesUseCase

    func make(place: Place) -> SpaceStore {
        SpaceStore(
            fetchPlaceMessagesUseCase: fetchPlaceMessagesUseCase,
            deleteMessagesUseCase: deleteMessagesUseCase,
            place: place
        )
    }
}

struct MessageMarkerManagerFactory {
    @MainActor
    func make() -> MessageMarkerManager {
        MessageMarkerManager(
            rotationAnimator: .init(),
            bubbleImageRenderer: .init()
        )
    }
}

struct TimelineListStoreFactory {
    let fetchRecentMessagesUseCase: FetchRecentMessagesUseCase
    let deleteMessagesUseCase: DeleteMessagesUseCase

    func make(
        initialMessages: [Message] = [],
        onDeletedMessages: @escaping (Set<MessageID>) -> Void = { _ in }
    ) -> TimelineListStore {
        TimelineListStore(
            initialMessages: initialMessages,
            fetchRecentMessagesUseCase: fetchRecentMessagesUseCase,
            deleteMessagesUseCase: deleteMessagesUseCase,
            onDeletedMessages: onDeletedMessages
        )
    }
}
