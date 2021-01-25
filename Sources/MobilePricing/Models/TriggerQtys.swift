//
//  TriggerQtys.swift
//  MobileBench
//
//  Created by Michael Rutherford on 7/21/20.
//

import Foundation
import MobileDownload

/// This contains the quantities of each item on an order (positive numbers only - i.e. sales but not returns, credits or pickups). This is matched to the TriggerRequirements to
/// see if a promotion or price-sheet column applies to this order ("is triggered for this order")
public final class TriggerQtys {
    public var quantitiesByItem: [Int: Int] = [:] // itemNid --> Qty on order
    
    public var itemNids: [Int] = []
    public var altPackFamilyNids: Set<Int> = []
    
    public init() {
        
    }
}

extension TriggerQtys {
    
    func getNonContractTriggerQtys(itemNidsCoveredByContractPromos: Set<Int>) -> TriggerQtys {
        let nonContractTriggerQtys = TriggerQtys()
        
        for x in quantitiesByItem {
            if !itemNidsCoveredByContractPromos.contains(x.key) {
                nonContractTriggerQtys.addItemAndQty(itemNid: x.key, qty: x.value)
            }
        }
        
        return nonContractTriggerQtys
    }

    /// Add a *sale* to the trigger quantities (negative quantities representing credits or product pickups are ignored)
    func addItemAndQty(itemNid: Int, qty: Int) {
        if qty <= 0 {
            return
        }
        
        if let priorQty = quantitiesByItem[itemNid] {
            quantitiesByItem[itemNid] = priorQty + qty
        } else {
            quantitiesByItem[itemNid] = qty
            
            itemNids.append(itemNid)
            altPackFamilyNids.insert(mobileDownload.items[itemNid].altPackFamilyNid)
        }
    }
    
    /// A minimum requirement may be entered as a number of cases, and the order contains bottles; or, it may be in bottles and the order contains cases (or a mix of bottles and cases)
    /// Frank Liqour required this for liquor sales. This is not the same as adding two different items together - just adding the alt-packs and representing the total in
    /// terms of one of those alt-packs
    func getRollupQty(itemNid resultItemNid: Int) -> Double {
        let resultItem = mobileDownload.items[resultItemNid]
        let primaryPack = mobileDownload.items[resultItem.altPackFamilyNid]
        
        var total = Double(quantitiesByItem[primaryPack.recNid] ?? 0)
        
        for altPackNid in primaryPack.altPackNids {
            if let qty = quantitiesByItem[altPackNid] {
                let thisAltPack = mobileDownload.items[altPackNid]
                total += Double(qty) * thisAltPack.numberOfPrimaryPacks
            }
        }
        
        let resultTotal = total / resultItem.numberOfPrimaryPacks
        
        return resultTotal
    }
    
    func getWeight(itemNid: Int) -> Double {
        if let qty = quantitiesByItem[itemNid] {
            let weight = mobileDownload.items[itemNid].itemWeight
            return Double(qty) * weight
        } else {
            return 0
        }
    }
    
    func getQty(itemNid: Int) -> Int {
        quantitiesByItem[itemNid] ?? 0
    }
}

extension TriggerQtys: ExpressibleByDictionaryLiteral {
    
    /// This allows initialization like this: [beer.recNid:10, wine.recNid:5]
    public convenience init(dictionaryLiteral elements: (Int, Int)...) {
        self.init()
        for (itemNid, count) in elements {
            self.addItemAndQty(itemNid: itemNid, qty: count)
        }
    }
}
