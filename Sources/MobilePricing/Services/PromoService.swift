//
//  PromoService.swift
//  MobileBench
//
//  Created by Michael Rutherford on 7/20/20.
//

import Foundation
import MobileDownload
import MoneyAndExchangeRates

// this will parse, process and apply promotions for a customer on a given date
public struct PromoService {

    var promoCodesForThisCustomer: [Int: PromoCodeRecord] = [:]

    public var mixAndMatchPromos: [MixAndMatchPromo] = []

    var unsupportedPromoSections: [PromoSectionRecord] = []

    public init(sellTo: CustomerRecord, pricingDate: Date) {
        let pricingParent = mobileDownload.customers[sellTo.pricingParentNid ?? sellTo.recNid]

        for promoCode in mobileDownload.promoCodes.getAll() {
            if promoCode.isCustomerSelected(pricingParent) {
                promoCodesForThisCustomer[promoCode.recNid] = promoCode
            }
        }

        if promoCodesForThisCustomer.isEmpty {
            return
        }

        for promoSection in mobileDownload.promoSections.getAll() {
            guard let promoCode = promoCodesForThisCustomer[promoSection.promoCodeNid] else {
                continue
            }

            if !promoSection.isActiveOnDate(pricingDate) {
                continue
            }

            if promoSection.isMixAndMatch, promoSection.promoPlan == .Default {
                let mixAndMatchPromo = MixAndMatchPromo(promoCode, promoSection)
                mixAndMatchPromos.append(mixAndMatchPromo)
            } else {
                unsupportedPromoSections.append(promoSection)
            }
        }
    }

    public func computeDiscounts(lines: [SaleLine]) {
        let qtys = TriggerQtys()
        for line in lines {
            line.clearDiscounts()
            let item = mobileDownload.items[line.itemNid]
            qtys.addItemAndQty(item, qty: line.qtyOrdered)
        }

        for promo in mixAndMatchPromos {
            let isTriggered = promo.isTriggered(qtys: qtys)

            if !isTriggered {
                continue
            }

            for line in lines {
                if let promoItem = promo.getDiscount(line.itemNid), let amountoff = getAmountOff(promoItem: promoItem, price: line.price) {
                    let discount = Discount(promoItem: promoItem, amountOff: amountoff)
                    line.addDiscount(discount: discount)
                }
            }
        }

        for line in lines {
            line.setBestDiscount()
        }
    }

    public func getAmountOff(promoItem: PromoItem, price: Money?) -> Money? {
        guard let price = price else { return nil }
        let promoSection = mobileDownload.promoSections[promoItem.promoSectionNid]
        let promoCode = mobileDownload.promoCodes[promoSection.promoCodeNid]
        let amountOff = promoItem.getUnitDisc(promoCode: promoCode, unitPrice: price, nbrPriceDecimals: 2)
        return amountOff
    }
}
