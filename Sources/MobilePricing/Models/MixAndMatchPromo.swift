//
//  MixAndMatchPromo.swift
//  MobileBench
//
//  Created by Michael Rutherford on 7/21/20.
//

import Foundation
import MobileDownload
import MoneyAndExchangeRates

public class MixAndMatchPromo {
    public let currency: Currency
    public let note: String?
    let triggerRequirements: TriggerRequirements?
    public let discountsByItemNid: [Int: PromoItem]
    
    // is this promotion triggered by the quantities on this order
    func isTriggered(qtys: TriggerQtys) -> Bool {
        guard let triggerRequirements = triggerRequirements else {
            return true
        }
        return triggerRequirements.isTriggered(qtys)
    }

    // does this promotion have a discount for the item
    func getDiscount(_ itemNid: Int) -> PromoItem? {
        discountsByItemNid[itemNid]
    }

    public init(_ promoCode: PromoCodeRecord, _ promoSection: PromoSectionRecord) {
        currency = promoCode.currency
        note = promoSection.getNote()
        triggerRequirements = promoSection.getTriggerRequirements()
                
        let promoItemsProvidingDiscounts = promoSection.getPromoItems().filter { $0.hasDiscount }

        discountsByItemNid = Dictionary(uniqueKeysWithValues: promoItemsProvidingDiscounts.map { ($0.itemNid, $0) })
    }
}
