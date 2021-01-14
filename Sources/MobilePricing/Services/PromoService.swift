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
    var nonMixAndMatchPromos: [NonMixAndMatchPromo] = []
    
    var unsupportedPromoSections: [PromoSectionRecord] = []
    
    var isEmpty: Bool {
        mixAndMatchPromos.isEmpty && nonMixAndMatchPromos.isEmpty
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
            
            if promoSection.promoPlan != .Default {
                unsupportedPromoSections.append(promoSection)
                continue
            }
            
            if promoSection.isMixAndMatch, promoSection.promoPlan == .Default {
                mixAndMatchPromos.append(MixAndMatchPromo(promoCode, promoSection))
            } else {
                nonMixAndMatchPromos.append(NonMixAndMatchPromo(promoCode, promoSection))
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
    
    private func getTriggerQtys(_ lines: [SaleLine]) -> TriggerQtys {
        let qtys = TriggerQtys()
        
        for line in lines {
            qtys.addItemAndQty(itemNid: line.itemNid, qty: line.qtyOrdered)
        }
        
        return qtys
    }
    
    /// Find the best discount for each sale - the discount is converted to the same currency as the unitPrice. If any discounts are in a different currency than the price and the mobileDownload
    /// has no exchange rates, then those discounts are ignored
    /// - Parameter lines: Each of the sales - these should identify an item (or alt-pack), a non-negative quantity and a non-null price. The best discount (if any) for each line is computed.
    public func computeDiscounts(_ lines: [SaleLine]) {
        let qtys = getTriggerQtys(lines)
        
        let triggeredMixAndMatchPromos = mixAndMatchPromos.filter { $0.isTriggered(qtys: qtys) }
        
        for line in lines {
            line.clearDiscounts()
            
            guard let unitPrice = line.unitPrice else {
                continue
            }
            
            var promoItems: [PromoItem] = []
            
            for promo in triggeredMixAndMatchPromos {
                if let promoItem = promo.getDiscount(line.itemNid) {
                    promoItems.append(promoItem)
                }
            }
            
            let triggeredNonMixAndMatchPromos = nonMixAndMatchPromos.filter { $0.isTriggered(itemNid: line.itemNid, qtys: qtys) }
            
            for promo in triggeredNonMixAndMatchPromos {
                if let promoItem = promo.getDiscount(line.itemNid) {
                    promoItems.append(promoItem)
                }
            }
            
            for promoItem in promoItems {
                let amountOff = promoItem.getAmountOff(unitPrice: unitPrice)
                if amountOff.isPositive {
                    line.addDiscount(discount: DiscountWithReason(promoItem: promoItem, amountOff: amountOff))
                }
            }
            
            line.setBestDiscount()
        }
    }
}
