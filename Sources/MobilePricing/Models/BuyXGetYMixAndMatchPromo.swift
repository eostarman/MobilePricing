//
//  File.swift
//  
//
//  Created by Michael Rutherford on 1/10/21.
//

import Foundation
import MobileDownload

struct BuyXGetYMixAndMatchPromo {
    let triggerItemNids: Set<Int>
    let freeItemNids: Set<Int>
    let freeItemsThatAreTriggers: Set<Int>
    let freeItemsThatAreNotTriggers: Set<Int>
    let qtyX: Int
    let qtyY: Int
    
    init(triggerItemNids: Set<Int>, freeItemNids: Set<Int>, qtyX: Int, qtyY: Int) {
        self.triggerItemNids = triggerItemNids
        self.freeItemNids = freeItemNids
        self.freeItemsThatAreTriggers = freeItemNids.filter { triggerItemNids.contains($0) }
        self.freeItemsThatAreNotTriggers = freeItemNids.filter { !triggerItemNids.contains($0) }
        self.qtyX = qtyX
        self.qtyY = qtyY
    }
}


extension PromoSectionRecord {
    func getBuyXGetYMixAndMatchPromo() -> BuyXGetYMixAndMatchPromo? {
        guard isBuyXGetY && isMixAndMatch && qtyX > 0 && qtyY > 0 else {
            return nil
        }
        
        let triggerItemNids = getTriggerItemNids()
        let freeItemNids = getFreeItemNids()
        
        
        let promo = BuyXGetYMixAndMatchPromo(triggerItemNids: triggerItemNids, freeItemNids: freeItemNids, qtyX: qtyX, qtyY: qtyY)
        
        return promo
    }
    
    func getFreeItemNids() -> Set<Int> {
        var freeItems: Set<Int> = []
        
        for item in getPromoItems() {
            if item.is100PercentOff {
                freeItems.insert(item.itemNid)
            }
        }
        
        return freeItems
    }
}
