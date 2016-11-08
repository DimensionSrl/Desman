//
//  Array+Desman.swift
//  Pods
//
//  Created by Matteo Gavagnin on 19/11/15.
//
//

extension Array where Element: Equatable {
    mutating func removeObject(_ object: Element) {
        if let index = self.index(of: object) {
            self.remove(at: index)
        }
    }
    
    func removeObjectsInArray(_ array: [Element]) -> [Element] {
        var arrayCopy = [Element](self)
        for object in array {
            arrayCopy.removeObject(object)
        }
        return arrayCopy
    }
    
    mutating func removeObjectsInArrayInPlace(_ array: [Element]) {
        for object in array {
            self.removeObject(object)
        }
    }
}
