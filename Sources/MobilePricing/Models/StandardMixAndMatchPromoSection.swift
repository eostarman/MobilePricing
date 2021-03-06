//
//  MixAndMatchPromo.swift
//  MobileBench
//
//  Created by Michael Rutherford on 7/21/20.
//

import Foundation
import MobileDownload
import MoneyAndExchangeRates

public class StandardMixAndMatchPromoSection {
    let promoSectionRecord: PromoSectionRecord
    
    public let currency: Currency
    public let note: String?
    let triggerRequirements: TriggerRequirements
    public let discountsByItemNid: [Int: PromoItem]
    
    // is this promotion triggered by the quantities on this order
    func isTriggered(triggerQtys: TriggerQtys) -> Bool {
        return triggerRequirements.isTriggered(triggerQtys)
    }

    // does this promotion have a discount for the item
    func getDiscount(_ itemNid: Int) -> PromoItem? {
        discountsByItemNid[itemNid]
    }

    public init(_ promoCode: PromoCodeRecord, _ promoSection: PromoSectionRecord, promoDate: Date) {
        self.promoSectionRecord = promoSection
        
        currency = promoCode.currency
        note = promoSection.getNote()
        triggerRequirements = promoSection.getMixAndMatchTriggerRequirements(promoDate: promoDate)
                
        let promoItemsProvidingDiscounts = promoSection.getPromoItems(promoDate: promoDate).filter { $0.hasDiscount }

        discountsByItemNid = Dictionary(uniqueKeysWithValues: promoItemsProvidingDiscounts.map { ($0.itemNid, $0) })
    }
}

extension StandardMixAndMatchPromoSection : PromoSection {
    func isTriggerItemOrRelatedAltPack(itemNid: Int) -> Bool {
        triggerRequirements.isTriggerItemOrRelatedAltPack(itemNid: itemNid)
    }
    
    func hasDiscount(itemNid: Int) -> Bool {
        discountsByItemNid[itemNid] != nil
    }
    
    func getTriggerGroup(itemNid: Int) -> Int? {
        triggerRequirements.getTriggerGroup(itemNid: itemNid)
    }
}
