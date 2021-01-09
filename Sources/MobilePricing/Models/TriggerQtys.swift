//
//  TriggerQtys.swift
//  MobileBench
//
//  Created by Michael Rutherford on 7/21/20.
//

import Foundation
import MobileDownload

public final class TriggerQtys {
    public var quantitiesByItem: [Int: Double] = [:]
    public var itemNids: [Int] = []

    public init() {

    }
    
    /// Add a *sale* to the trigger quantities (negative quantities representing credits or product pickups are ignored)
    func addItemAndQty(_ item: ItemRecord, qty: Int) {
        if qty <= 0 {
            return
        }
        
        let itemNid = item.recNid

        if let priorQty = quantitiesByItem[itemNid] {
            quantitiesByItem[itemNid] = priorQty + Double(qty)
        } else {
            quantitiesByItem[itemNid] = Double(qty)
            itemNids.append(itemNid)
        }
    }

    /// Return the quantity for the itemNid. If the weight is needed, then the item's weight is retrieved from mobileDownload
    /// - Parameters:
    ///   - isCaseMinimum: true to get cases (actually the qty for the item); false to get the total weight instead
    func getCasesOrWeight(_ item: ItemRecord, isCaseMinimum: Bool) -> Double {
        let itemTriggerQty = getQty(item)
        if itemTriggerQty == 0 {
            return 0
        }

        if isCaseMinimum {
            return itemTriggerQty
        } else {
            let weight = itemTriggerQty * item.itemWeight
            return weight
        }
    }

    func getQty(_ item: ItemRecord) -> Double {
        quantitiesByItem[item.recNid] ?? 0
    }
}

extension TriggerQtys: ExpressibleByDictionaryLiteral {
    public convenience init(dictionaryLiteral elements: (Int, Int)...) {
        self.init()
        for (itemNid, count) in elements {
            self.addItemAndQty(mobileDownload.items[itemNid], qty: count)
        }
    }
}
