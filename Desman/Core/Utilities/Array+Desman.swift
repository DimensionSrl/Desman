//
//  Array+Desman.swift
//  Pods
//
//  Created by Matteo Gavagnin on 19/11/15.
//
//

extension Array where Element: Equatable {
    mutating func removeObject(object: Element) {
        if let index = self.indexOf(object) {
            self.removeAtIndex(index)
        }
    }
    
    func removeObjectsInArray(array: [Element]) -> [Element] {
        var arrayCopy = [Element](self)
        for object in array {
            arrayCopy.removeObject(object)
        }
        return arrayCopy
    }
    
    mutating func removeObjectsInArrayInPlace(array: [Element]) {
        for object in array {
            self.removeObject(object)
        }
    }
}