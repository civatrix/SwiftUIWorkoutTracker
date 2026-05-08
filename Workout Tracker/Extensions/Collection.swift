//
//  Collection.swift
//  Workout Tracker
//
//  Created by Daniel Johns on 2026-05-08.
//

extension Collection where Iterator.Element: Collection {
    func interleaved() -> [Iterator.Element.Element] {
        let indicies = map { $0.indices }
        var lastIndicies: [Self.Element.Index?] = indicies.map(\.startIndex)
        var result: [Iterator.Element.Element] = []
        var lastCount = -1
        
        while result.count != lastCount {
            lastCount = result.count
            for (index, collection) in zip(lastIndicies, self) {
                if let index, collection.indices.contains(index) {
                    result.append(collection[index])
                }
            }
            lastIndicies = zip(lastIndicies, indicies).map { (lastIndex, i) in
                guard let lastIndex else { return nil }
                let nextIndex = i.index(after: lastIndex)
                guard nextIndex != i.endIndex else { return nil }
                
                return nextIndex
            }
        }
        
        return result
    }
}
