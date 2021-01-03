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
    public let promoItems: [PromoItem]

    public let caseMinimum: Int
    public let triggerGroupMinimums: [Int]

    public let discountsByItemNid: [Int: PromoItem]
    public let triggerGroupByItemNid: [Int: Int] // if the item's here, then it's a trigger item

    // is this promotion triggered by the quantities on this order
    func isTriggered(qtys: TriggerQtys) -> Bool {
        var totalsByTriggerGroup = [0, 0, 0, 0, 0, 0] // group (0) and groups 1-5 (Group A thru Group F)
        var totalForAllTriggerItems = 0

        for keyvalue in qtys.quantitiesByItem {
            let itemNid = keyvalue.key

            if let triggerGroup = triggerGroupByItemNid[itemNid] {
                let qty = keyvalue.value

                totalForAllTriggerItems += qty
                if triggerGroup >= 1, triggerGroup <= 5 {
                    totalsByTriggerGroup[triggerGroup] += qty
                }
            }
        }

        if totalForAllTriggerItems == 0 { // you didn't buy any of the trigger items
            return false
        }

        if totalForAllTriggerItems < caseMinimum { // you bought some, but not enough
            return false
        }

        for triggerGroup in 1 ... 5 { // you bought enough, but not from the targeted trigger groups (Group A thru group F) which have their own minimums
            if totalsByTriggerGroup[triggerGroup] < triggerGroupMinimums[triggerGroup] {
                return false
            }
        }

        return true
    }

    // does this promotion have a discount for the item
    func getDiscount(_ itemNid: Int) -> PromoItem? {
        discountsByItemNid[itemNid]
    }

    public init(promoCode: PromoCodeRecord, promoSection: PromoSectionRecord) {
        currency = promoCode.currency
        note = promoSection.getNote()
        promoItems = promoSection.getPromoItems()

        caseMinimum = promoSection.caseMinimum

        triggerGroupMinimums = [0,
                                promoSection.triggerGroup1Minimum,
                                promoSection.triggerGroup2Minimum,
                                promoSection.triggerGroup3Minimum,
                                promoSection.triggerGroup4Minimum,
                                promoSection.triggerGroup5Minimum]

        var hasExplicitTriggerItems = false

        var discountsByItemNid: [Int: PromoItem] = [:]
        var triggerGroupByItemNid: [Int: Int] = [:] // if the item's here, then it's a trigger item

        // This logic says that if you flag *any* items as explicit trigger items, then only those explicit trigger
        // items can be assigned to a group or may be considered toward the total case quantity before giving any of the discounts
        for promoItem in promoItems {
            if promoItem.isExplicitTriggerItem {
                if !hasExplicitTriggerItems {
                    hasExplicitTriggerItems = true
                    triggerGroupByItemNid = [:]
                }

                triggerGroupByItemNid[promoItem.itemNid] = promoItem.triggerGroup
            } else if !hasExplicitTriggerItems {
                triggerGroupByItemNid[promoItem.itemNid] = promoItem.triggerGroup
            }

            if promoItem.hasDiscount {
                discountsByItemNid[promoItem.itemNid] = promoItem
            }
        }

        self.discountsByItemNid = discountsByItemNid
        self.triggerGroupByItemNid = triggerGroupByItemNid
    }
}
