//  Created by Michael Rutherford on 1/23/21.

import Foundation
import MobileDownload
import MoneyAndExchangeRates

class DCPromoSection {
    let promoSectionRecord: PromoSectionRecord
    let transactionCurrency: Currency
    var promoPlan: ePromoPlan {
        promoSectionRecord.promoPlan
    }
    
    var isContractPromo: Bool { promoSectionRecord.isContractPromo }
    var isAdditionalFee: Bool { promoSectionRecord.promoPlan == .AdditionalFee }
    var isTax: Bool { isAdditionalFee && promoSectionRecord.additionalFeePromo_IsTax }
    
    let promoTierSequence: Int?
    let isTieredPromo: Bool?
    
    let hasExplicitTriggerItems: Bool
    
    let promoItemsByItemNid: [Int: PromoItem]
    
    // only for a mix-and-match promotion
    let triggerRequirements: TriggerRequirements?
    
    /// if an item is a target, then it will get a discount when this promoSection is actually triggered (doesn't look at other alt-packs for this item)
    func isTarget(itemNid: Int) -> Bool {
        promoItemsByItemNid[itemNid]?.hasDiscount ?? false
    }
    
    func isTarget(forAnyItemNid itemNids: [Int]) -> Bool {
        for itemNid in itemNids {
            if isTarget(itemNid: itemNid) {
                return true
            }
        }
        return false
    }
    
    /// If an item can trigger this promo section (doesn't look at alt-packs)
    func isTrigger(itemNid: Int) -> Bool {
        guard let promoItem = promoItemsByItemNid[itemNid] else {
            return false
        }
        
        if hasExplicitTriggerItems {
            return promoItem.isExplicitTriggerItem
        } else {
            return true
        }
    }
    
    init(promoSectionRecord: PromoSectionRecord, transactionCurrency: Currency)
    {
        self.promoSectionRecord = promoSectionRecord
        self.transactionCurrency = transactionCurrency
        
        let promoItems = promoSectionRecord.getPromoItems()
        hasExplicitTriggerItems = promoItems.contains { $0.isExplicitTriggerItem }
        
        let promoCode = mobileDownload.promoCodes[promoSectionRecord.promoCodeNid]
        
        self.isTieredPromo = promoCode.isTieredPromo
        self.promoTierSequence = promoCode.promoTierSeq
        
        promoItemsByItemNid = Dictionary(uniqueKeysWithValues: promoSectionRecord.getPromoItems().map{ ($0.itemNid, $0) })
        
        if promoSectionRecord.isMixAndMatch {
            triggerRequirements = promoSectionRecord.getMixAndMatchTriggerRequirements()
        } else {
            triggerRequirements = nil
        }
    }
}

extension DCPromoSection : PromoSection {
    func isTriggerItemOrRelatedAltPack(itemNid: Int) -> Bool {
        if let triggerRequirements = triggerRequirements {
            return triggerRequirements.isTriggerItemOrRelatedAltPack(itemNid: itemNid)
        } else {
            return isTrigger(itemNid: itemNid)
        }
    }
    
    func hasDiscount(itemNid: Int) -> Bool {
        isTarget(itemNid: itemNid)
    }
    
    func getTriggerGroup(itemNid: Int) -> Int? {
        if let triggerRequirements = triggerRequirements {
            return triggerRequirements.getTriggerGroup(itemNid: itemNid)
        } else {
            return nil
        }
    }
}
