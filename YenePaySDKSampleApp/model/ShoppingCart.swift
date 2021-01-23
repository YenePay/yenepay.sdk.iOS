//
//  ShoppingCart.swift
//  YenePaySDKSampleApp
//
//  Created by Ahmed Mohammed Abdurahman on 1/21/21.
//

import Foundation


class ShoppingCart {
    private(set) var items: [(item: StoreItem, count: Int)] = []
    
    var totalPrice: Double {
        var sum = 0.0
        for item in items {
            sum += item.item.price * Double(item.count)
        }
        return sum
    }
    
    var tax1: Double { 0.0 }
    var tax2: Double { 0.0 }
    
     
    private func indexOfItem(withId id: String) -> Int? {
        items.firstIndex { $0.item.id == id }       // just do a linear search
    }
    
    
    private init() {}
    static let shared = ShoppingCart()
        
    
    func countOfItem(withId id: String) -> Int {
        if let index = indexOfItem(withId: id) {
            return items[index].count
        } else {
            return 0
        }
    }
    
    func countOf(item: StoreItem) -> Int {
        return countOfItem(withId: item.id)
    }
    
    
    func add(item: StoreItem) {
        if let index = indexOfItem(withId: item.id) {
            items[index].count += 1
        } else {
            items.append((item: item, count: 1))
        }
    }
    
    func remove(item: StoreItem, keepRowIfZero: Bool = false) {
        removeItem(withId: item.id, keepRowIfZero: keepRowIfZero)
    }
    
    func removeItem(withId id: String, keepRowIfZero: Bool = false) {
        if let index = indexOfItem(withId: id) {
            if !keepRowIfZero && (items[index].count <= 1) {
                items.remove(at: index)
                return
            }
            
            if items[index].count > 0 {
                items[index].count -= 1
            }
        }
    }
    
    func removeAllItems(withId id: String, keepRow: Bool = false) {
        if let index = indexOfItem(withId: id) {
            if keepRow {
                items[index].count = 0;
            } else {
                items.remove(at: index)
            }
        }
    }
    
    func removeAllZeroQuantityItems() {
        items.removeAll(where: { $0.count <= 0 })
    }
    
    func removeAllItems() {
        items.removeAll()
    }
}
