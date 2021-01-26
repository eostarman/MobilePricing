//
//  NonMixAndMatchPromo.swift
//  MobilePricing
//
//  Created by Michael Rutherford on 1/14/21.
//


import Foundation
import MobileDownload
import MoneyAndExchangeRates

public class StandardPerItemPromoSection {
    let promoSectionRecord: PromoSectionRecord
    public let currency: Currency
    public let note: String?
    public let discountsByItemNid: [Int: PromoItem]
    
    // is this promotion triggered by the quantities on this order
    func isTriggered(itemNid: Int, triggerQtys: TriggerQtys) -> Bool {
        if discountsByItemNid[itemNid] == nil {
            return false
        }
        
        guard let triggerRequirements = promoSectionRecord.getNonMixAndMatchTriggerRequirements(itemNid: itemNid) else {
            return true
        }
        return triggerRequirements.isTriggered(triggerQtys)
    }

    // does this promotion have a discount for the item
    func getDiscount(_ itemNid: Int) -> PromoItem? {
        discountsByItemNid[itemNid]
    }

    public init(_ promoCode: PromoCodeRecord, _ promoSection: PromoSectionRecord) {
        self.promoSectionRecord = promoSection
        
        currency = promoCode.currency
        note = promoSection.getNote()
                
        let promoItemsProvidingDiscounts = promoSection.getPromoItems().filter { $0.hasDiscount }

        discountsByItemNid = Dictionary(uniqueKeysWithValues: promoItemsProvidingDiscounts.map { ($0.itemNid, $0) })
    }
}

extension StandardPerItemPromoSection : PromoSection {
    func isTriggerItemOrRelatedAltPack(itemNid: Int) -> Bool {
        discountsByItemNid[itemNid] != nil
    }
    
    func hasDiscount(itemNid: Int) -> Bool {
        discountsByItemNid[itemNid] != nil
    }
    
    func getTriggerGroup(itemNid: Int) -> Int? {
        nil
    }
}

