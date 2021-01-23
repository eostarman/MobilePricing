//
//  File.swift
//  
//
//  Created by Michael Rutherford on 1/10/21.
//

import Foundation
import MobileDownload

struct BuyXGetYMixAndMatchPromoSection {
    let promoSectionRecord: PromoSectionRecord
    let triggerRequirements: TriggerRequirements
    let freeItemNids: Set<Int>
    let freeItemsThatAreTriggers: Set<Int>
    let freeItemsThatAreNotTriggers: Set<Int>
    let qtyX: Int
    let qtyY: Int
    
    init(_ promoSectionRecord: PromoSectionRecord, _ triggerRequirements: TriggerRequirements, freeItemNids: Set<Int>, qtyX: Int, qtyY: Int) {
        self.promoSectionRecord = promoSectionRecord
        
        self.triggerRequirements = triggerRequirements
        self.freeItemNids = freeItemNids
        
        self.freeItemsThatAreTriggers = freeItemNids.filter { triggerRequirements.contains(itemNid: $0) }
        self.freeItemsThatAreNotTriggers = freeItemNids.filter { !triggerRequirements.contains(itemNid: $0) }
        
        self.qtyX = qtyX
        self.qtyY = qtyY
    }
}

extension BuyXGetYMixAndMatchPromoSection : PromoSection {

    func isTriggerItemOrRelatedAltPack(itemNid: Int) -> Bool {
        triggerRequirements.isTriggerItemOrRelatedAltPack(itemNid: itemNid)
    }
    
    func hasDiscount(itemNid: Int) -> Bool {
        freeItemNids.contains(itemNid)
    }
    
    func getTriggerGroup(itemNid: Int) -> Int? {
        triggerRequirements.getTriggerGroup(itemNid: itemNid)
    }
}

extension PromoSectionRecord {
    func getBuyXGetYMixAndMatchPromo() -> BuyXGetYMixAndMatchPromoSection? {
        guard isBuyXGetY && isMixAndMatch && qtyX > 0 && qtyY > 0 else {
            return nil
        }
        
        let triggerRequirements = getMixAndMatchTriggerRequirements()
        let freeItemNids = getFreeItemNids()
        
        let promo = BuyXGetYMixAndMatchPromoSection(self, triggerRequirements, freeItemNids: freeItemNids, qtyX: qtyX, qtyY: qtyY)
        
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
