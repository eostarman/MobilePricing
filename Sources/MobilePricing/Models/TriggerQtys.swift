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

    func addItemAndQty(itemNid: Int, qty: Int) {
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
    func getCasesOrWeight(itemNid: Int, isCaseMinimum: Bool) -> Double {
        let itemTriggerQty = getQty(itemNid: itemNid)
        if itemTriggerQty == 0 {
            return 0
        }

        if isCaseMinimum {
            return itemTriggerQty
        } else {
            let weight = itemTriggerQty * mobileDownload.items[itemNid].itemWeight
            return weight
        }
    }

    func getQty(itemNid: Int) -> Double {
        quantitiesByItem[itemNid] ?? 0
    }
}

extension TriggerQtys: ExpressibleByDictionaryLiteral {
    public convenience init(dictionaryLiteral elements: (Int, Int)...) {
        self.init()
        for (itemNid, count) in elements {
            self.addItemAndQty(itemNid: itemNid, qty: count)
        }
    }
}
