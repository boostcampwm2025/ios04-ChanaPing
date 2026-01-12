//
//  GroupMessageUseCase.swift
//  Meomun
//
//  Created by MinwooJe on 1/12/26.
//

final class GroupMessageUseCase {

    /// 전체 메시지 그룹핑
    ///
    /// 그룹핑 로직:
    /// 1. 좌표 기준으로 먼저 그룹핑
    /// 2. 각 좌표 그룹 내에서 placeTag 유무로 분리:
    ///    - placeTag가 있는 메시지들 → `.places(Location)`
    ///    - placeTag가 없는 메시지들 → `.location(Location)`
    func groupAll(messages: [Message]) -> [BubbleGroupKey: [Message]] {
        // 1단계: 좌표 기준으로 그룹핑
        var locationGroups: [Location: [Message]] = [:]

        for message in messages {
            locationGroups[message.location, default: []].append(message)
        }

        // 2단계: 각 좌표 그룹 내에서 placeTag 유무로 분리
        var result: [BubbleGroupKey: [Message]] = [:]

        for (location, groupMessages) in locationGroups {
            let withPlaceTag = groupMessages.filter { $0.placeTag != nil }
            let withoutPlaceTag = groupMessages.filter { $0.placeTag == nil }

            if !withPlaceTag.isEmpty {
                result[.places(location)] = withPlaceTag
            }
            if !withoutPlaceTag.isEmpty {
                result[.location(location)] = withoutPlaceTag
            }
        }

        return result
    }
}
