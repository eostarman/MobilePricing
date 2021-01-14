//
//  NonMixAndMatchPromo.swift
//  MobilePricing
//
//  Created by Michael Rutherford on 1/14/21.
//


import Foundation
import MobileDownload
import MoneyAndExchangeRates

public class NonMixAndMatchPromo {
    private let promoSection: PromoSectionRecord
    public let currency: Currency
    public let note: String?
    public let discountsByItemNid: [Int: PromoItem]
    
    // is this promotion triggered by the quantities on this order
    func isTriggered(itemNid: Int, qtys: TriggerQtys) -> Bool {
        if discountsByItemNid[itemNid] == nil {
            return false
        }
        
        guard let triggerRequirements = promoSection.getNonMixAndMatchTriggerRequirements(itemNid: itemNid) else {
            return true
        }
        return triggerRequirements.isTriggered(qtys)
    }

    // does this promotion have a discount for the item
    func getDiscount(_ itemNid: Int) -> PromoItem? {
        discountsByItemNid[itemNid]
    }

    public init(_ promoCode: PromoCodeRecord, _ promoSection: PromoSectionRecord) {
        self.promoSection = promoSection
        
        currency = promoCode.currency
        note = promoSection.getNote()
                
        let promoItemsProvidingDiscounts = promoSection.getPromoItems().filter { $0.hasDiscount }

        discountsByItemNid = Dictionary(uniqueKeysWithValues: promoItemsProvidingDiscounts.map { ($0.itemNid, $0) })
    }
}

