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

    var mixAndMatchPromos: [MixAndMatchPromo] = []

    var unsupportedPromoSections: [PromoSectionRecord] = []
    
    var isEmpty: Bool {
        mixAndMatchPromos.isEmpty
    }
    
    /// Gather all promotions from the mobileDownload for this customer that are active on the given date
    public init(_ customer: CustomerRecord, _ date: Date) {

        for promoCode in mobileDownload.promoCodes.getAll() {
            if promoCode.isCustomerSelected(customer) {
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

            if !promoSection.isActiveOnDate(date) {
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
    
    
    /// Convenience method useful during testing
    /// Find the best discount for each sale - the discount is converted to the same currency as the unitPrice. If any discounts are in a different currency than the price and the mobileDownload
    /// has no exchange rates, then those discounts are ignored
    /// - Parameter lines: Each of the sales - these should identify an item (or alt-pack), a non-negative quantity and a non-null price. The best discount (if any) for each line is computed.
    public func computeDiscounts(_ lines: SaleLine ...) {
        computeDiscounts(lines)
    }
    
    /// Find the best discount for each sale - the discount is converted to the same currency as the unitPrice. If any discounts are in a different currency than the price and the mobileDownload
    /// has no exchange rates, then those discounts are ignored
    /// - Parameter lines: Each of the sales - these should identify an item (or alt-pack), a non-negative quantity and a non-null price. The best discount (if any) for each line is computed.
    public func computeDiscounts(_ lines: [SaleLine]) {
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
                if let promoItem = promo.getDiscount(line.itemNid),
                   let amountoff = Self.getAmountOff(promoItem: promoItem, unitPrice: line.unitPrice) {
                    let discount = DiscountWithReason(promoItem: promoItem, amountOff: amountoff)
                    line.addDiscount(discount: discount)
                }
            }
        }

        for line in lines {
            line.setBestDiscount()
        }
    }

    static func getAmountOff(promoItem: PromoItem, unitPrice: Money?) -> Money? {
        guard let unitPrice = unitPrice else { return nil }
        
        if unitPrice.isZero {
            return nil
        }
        
        let promoSection = mobileDownload.promoSections[promoItem.promoSectionNid]
        let promoCode = mobileDownload.promoCodes[promoSection.promoCodeNid]
        
        let amountOff = promoItem.getUnitDisc(promoCurrency: promoCode.currency, unitPrice: unitPrice, nbrPriceDecimals: 2)
        return amountOff
    }
}
