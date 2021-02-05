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
    
    var mixAndMatchPromos: [StandardMixAndMatchPromoSection] = []
    var nonMixAndMatchPromos: [StandardPerItemPromoSection] = []

    var isEmpty: Bool {
        mixAndMatchPromos.isEmpty && nonMixAndMatchPromos.isEmpty
    }
    
    /// Initialize from a pre-filtered list of applicable promoSections (ignoring any buy-x-get-y promotions)
    public init(promoSections: [PromoSectionRecord], promoDate: Date) {
        for promoSection in promoSections {

            if promoSection.isBuyXGetY {
                continue
            }

            let promoCode = mobileDownload.promoCodes[promoSection.promoCodeNid]
            
            if promoSection.isMixAndMatch {
                mixAndMatchPromos.append(StandardMixAndMatchPromoSection(promoCode, promoSection, promoDate: promoDate))
            } else {
                nonMixAndMatchPromos.append(StandardPerItemPromoSection(promoCode, promoSection, promoDate: promoDate))
            }
        }
    }
    
    /// Gather all promotions (not buy-x-get-y) from the mobileDownload for this customer that are active on the given date
    public init(_ customer: CustomerRecord, _ promoDate: Date) {
        
        let promoCodesForThisCustomer = mobileDownload.promoCodes.getAll().filter({ $0.isCustomerSelected(customer) }).map { $0.recNid }

        let promoSections = mobileDownload.promoSections.getAll()
            .filter { promoSection in
                promoCodesForThisCustomer.contains(promoSection.promoCodeNid) && promoSection.isActiveOnDate(promoDate)
            }
        
        self.init(promoSections: promoSections, promoDate: promoDate)
    }
    
    /// Get the "earned" discounts (the triggered discounts) as a colletion of PromoItem entries
    func getEarnedDiscountPromoItems(triggerQtys: TriggerQtys, itemNids: [Int]) -> [PromoItem] {
        
        var promoItems: [PromoItem] = []
        
        let triggeredMixAndMatchPromos = mixAndMatchPromos.filter { $0.isTriggered(triggerQtys: triggerQtys) }
        
        for itemNid in itemNids {
          
            for promo in triggeredMixAndMatchPromos {
                if let promoItem = promo.getDiscount(itemNid) {
                    promoItems.append(promoItem)
                }
            }
     
            let triggeredNonMixAndMatchPromos = nonMixAndMatchPromos.filter { $0.isTriggered(itemNid: itemNid, triggerQtys: triggerQtys) }
            
            for promo in triggeredNonMixAndMatchPromos {
                if let promoItem = promo.getDiscount(itemNid) {
                    promoItems.append(promoItem)
                }
            }
        }
        
        return promoItems
    }
    
    /// Convenience method useful during testing
    /// Find the best discount for each sale - the discount is converted to the same currency as the unitPrice. If any discounts are in a different currency than the price and the mobileDownload
    /// has no exchange rates, then those discounts are ignored
    /// - Parameter lines: Each of the sales - these should identify an item (or alt-pack), a non-negative quantity and a non-null price. The best discount (if any) for each line is computed.
    public func computeDiscounts(_ lines: SaleLine ...) {
        computeDiscounts(lines)
    }
    
    private func getTriggerQtys(_ lines: [SaleLine]) -> TriggerQtys {
        let triggerQtys = TriggerQtys()
        
        for line in lines {
            triggerQtys.addItemAndQty(itemNid: line.itemNid, qty: line.qtyOrdered)
        }
        
        return triggerQtys
    }
    
    /// Find the best discount for each sale - the discount is converted to the same currency as the unitPrice. If any discounts are in a different currency than the price and the mobileDownload
    /// has no exchange rates, then those discounts are ignored
    /// - Parameter lines: Each of the sales - these should identify an item (or alt-pack), a non-negative quantity and a non-null price. The best discount (if any) for each line is computed.
    public func computeDiscounts(_ lines: [SaleLine]) {
        let triggerQtys = getTriggerQtys(lines)
        
        let itemNids = lines.map { $0.itemNid }.unique()
        
        let earnedDiscounts = getEarnedDiscountPromoItems(triggerQtys: triggerQtys, itemNids: itemNids)
        
        let discountsByItem = Dictionary(grouping: earnedDiscounts) { $0.itemNid }

        for line in lines {
            line.clearDiscounts()
            
            guard let unitPrice = line.unitPrice else {
                continue
            }
            
            if let promoItems = discountsByItem[line.itemNid] {
                for promoItem in promoItems {
                    let amountOff = promoItem.getAmountOff(unitPrice: unitPrice)
                    if amountOff.isPositive {
                        line.addDiscount(discount: DiscountWithReason(promoItem: promoItem, amountOff: amountOff))
                    }
                }
            }
            
            line.setBestDiscount()
        }
    }
}
