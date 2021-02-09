//  Created by Michael Rutherford on 1/25/21.

import Foundation
import MoneyAndExchangeRates
import MobileDownload

struct NonBuyXGetYService {
    
    /// Get discounts generated for the current order
    static func computeNonBuyXGetYDiscountsOnThisOrder(
        transactionCurrency: Currency,
        promoDate: Date,
        dcPromoSection: DCPromoSection,
        orderLinesByItemNid: [Int: [FreebieAccumulator]],
        nbrPriceDecimals: Int,
        triggeredFlag: Bool) -> [PromoDiscount] {
        
        let promoCurrency = mobileDownload.promoCodes[dcPromoSection.promoSectionRecord.promoCodeNid].currency
        
        let triggerQtys = TriggerQtys()
        var itemNids: [Int] = []
        
        for (itemNid, lines) in orderLinesByItemNid {
            itemNids.append(itemNid)
            for line in lines {
                triggerQtys.addItemAndQty(itemNid: itemNid, qty: line.originalQty)
            }
        }
        
        let earnedDiscounts = Self.getPotentialPromoItems(promoSections: [dcPromoSection.promoSectionRecord], promoDate: promoDate, triggerQtys: triggerQtys, itemNids: itemNids, triggeredFlag: triggeredFlag)
        
        let targetItemNids = dcPromoSection.promoSectionRecord.getTargetItemNids(promoDate: promoDate)
        var orderLinesForItemNids: [FreebieAccumulator] = []
        for itemNid in targetItemNids {
            if let lines = orderLinesByItemNid[itemNid] {
                orderLinesForItemNids.append(contentsOf: lines)
            }
        }
        
        let availableOrderLines = orderLinesForItemNids.filter { $0.qtyAvailableForStandardPromos > 0 || $0.qtyAvailableToDiscount == 0 }
        
        //  there is a promotion where when we give (e.g.) $1.00 off, this amount is pro-rated over all targets. I'm not sure about this implementation
        let qtyOnOrderInTotal = dcPromoSection.promoSectionRecord.isProratedAmount ? availableOrderLines.map({$0.qtyAvailableForStandardPromos}).reduce(0, +) : 0
        
        var allDiscounts: [PromoDiscount] = []
        
        // Now for the triggered (earned) PromoItems, match the earnedDiscounts to the actual items on this order
        for promoItem in earnedDiscounts {
            let itemNid = promoItem.promoItem.itemNid
            
            // I have an earned discount, but the item isn't even on the order
            
            guard let orderLinesForThisItem = orderLinesByItemNid[itemNid] else {
                continue
            }
            
            // compute cents-off discounts (eg) on lines that were not totally used as BuyXGetY promos (as free goods or trigger items). But, keep lines that came in as zero-quantity lines (just to return the case-1 discount)
            for orderLine in orderLinesForThisItem.filter({x in x.qtyAvailableForStandardPromos > 0 || x.qtyAvailableToDiscount == 0 })
            {
                let unitPrice = orderLine.frontlinePrice
                
                var unitDiscount = promoItem.promoItem.getUnitDisc(promoCurrency: promoCurrency, transactionCurrency: transactionCurrency, frontlinePrice: unitPrice, nbrPriceDecimals: nbrPriceDecimals)
                
                // for example, a $3.00 discount for the purchase of (6) casees of beer can be prorated to a per-case discount of $0.50
                if promoItem.promoItem.promoRateType == .amountOff && qtyOnOrderInTotal > 0 {
                    let rawProrated = unitDiscount.decimalValue / Decimal(qtyOnOrderInTotal)
                    let proratedDiscount = MoneyWithoutCurrency(amount: rawProrated, numberOfDecimals: nbrPriceDecimals)
                    unitDiscount = proratedDiscount
                }
                
                if unitDiscount.isPositive {
                    let promoDiscount = PromoDiscount(dcOrderLine: orderLine.dcOrderLine, potentialPromoItem: promoItem, qtyDiscounted: orderLine.qtyAvailableForStandardPromos, unitDisc: unitDiscount, rebateAmount: promoItem.promoItem.unitRebate)
                    
                    allDiscounts.append(promoDiscount)
                }
            }
        }
        
        return allDiscounts
    }
    
    
    /// Get the "earned" discounts (the triggered discounts) as a colletion of PromoItem entries
    private static func getPotentialPromoItems(promoSections: [PromoSectionRecord], promoDate: Date, triggerQtys: TriggerQtys, itemNids: [Int], triggeredFlag: Bool) -> [PotentialPromoItem] {
        
        var potentials: [PotentialPromoItem] = []
        
        let mixAndMatchPromoSections = promoSections.filter { !$0.isBuyXGetY && $0.isMixAndMatch }
        
        for promoSection in mixAndMatchPromoSections {
            let triggerRequirements = promoSection.getMixAndMatchTriggerRequirements(promoDate: promoDate)
            let isTriggered = triggerRequirements.isTriggered(triggerQtys)
            if isTriggered != triggeredFlag {
                continue
            }
            
            for itemNid in itemNids {
                guard let promoItem = promoSection.getPromoItem(promoDate: promoDate, itemNid: itemNid) else {
                    continue
                }
                
                let potential = PotentialPromoItem(promoSection: promoSection, triggerRequirements: triggerRequirements, triggerQtys: triggerQtys, promoItem: promoItem)
                potentials.append(potential)
            }
        }
        
        let nonMixAndMatchPromoSections = promoSections.filter { !$0.isBuyXGetY && !$0.isMixAndMatch }
        
        for promoSection in nonMixAndMatchPromoSections {
            
            for itemNid in itemNids {
                guard let promoItem = promoSection.getPromoItem(promoDate: promoDate, itemNid: itemNid) else {
                    continue
                }
                
                let triggerRequirements = promoSection.getNonMixAndMatchTriggerRequirements(itemNid: itemNid)
                
                let isTriggered = triggerRequirements.isTriggered(triggerQtys)
                if isTriggered != triggeredFlag {
                    continue
                }
                
                let potential = PotentialPromoItem(promoSection: promoSection, triggerRequirements: triggerRequirements, triggerQtys: triggerQtys, promoItem: promoItem)
                potentials.append(potential)
            }
        }
        return potentials
    }
    
    /// Get the "earned" discounts (the triggered discounts) as a colletion of PromoItem entries
    private static func getEarnedDiscountPromoItems(promoSections: [PromoSectionRecord], promoDate: Date, triggerQtys: TriggerQtys, itemNids: [Int], triggeredFlag: Bool) -> [PromoItem] {

        let zzz = getPotentialPromoItems(promoSections: promoSections, promoDate: promoDate, triggerQtys: triggerQtys, itemNids: itemNids, triggeredFlag: triggeredFlag)
        let mmm = zzz.map { $0.promoItem }
        return mmm
    
    }
}
