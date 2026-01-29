//
//  TextArranger.swift
//  Meomun
//
//  Created by Hayeon Park on 1/29/26.
//

struct TextArranger {
    static func arrangeText(_ text: String) -> String {
        let words = text.split(separator: " ").map(String.init)

        if text.count >= 10 && words.count >= 2 {
            let target = text.count / 2
            var bestIndex = 1
            var bestDiff = Int.max
            var prefixCount = 0

            for index in 1..<words.count {
                // index 개 단어를 첫 줄에 넣었을 때 길이
                prefixCount = words[0..<index].joined(separator: " ").count
                let diff = abs(prefixCount - target)

                if diff < bestDiff {
                    bestDiff = diff
                    bestIndex = index
                }
            }

            let first = words[0..<bestIndex].joined(separator: " ")
            let second = words[bestIndex...].joined(separator: " ")

            return "\(first)\n\(second)"
        }

        return text
    }
}
