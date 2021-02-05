//  Created by Michael Rutherford on 1/25/21.

import Foundation
import MoneyAndExchangeRates
import MobileDownload

struct NonBuyXGetYCalculator {
    
    /// Get discounts generated for the current order
    static func computeNonBuyXGetYDiscountsOnThisOrder(
        transactionCurrency: Currency,
        promoDate: Date,
        dcPromoSection: DCPromoSection,
        orderLinesByItemNid: [Int: [FreebieAccumulator]],
        nbrPriceDecimals: Int,
        itemNidsCoveredByContractPromos: Set<Int>,
        earlierTierDiscountsByOrderLine: [Int: [PromoDiscount]]) -> [PromoDiscount] {
        
        let promoCurrency = mobileDownload.promoCodes[dcPromoSection.promoSectionRecord.promoCodeNid].currency
        
        let triggerQtys = TriggerQtys()
        var itemNids: [Int] = []
        
        for (itemNid, lines) in orderLinesByItemNid {
            itemNids.append(itemNid)
            for line in lines {
                triggerQtys.addItemAndQty(itemNid: itemNid, qty: line.originalQty)
            }
        }
        
        let promoService = PromoService(promoSections: [dcPromoSection.promoSectionRecord], promoDate: promoDate)
        
        let earnedDiscounts = promoService.getEarnedDiscountPromoItems(triggerQtys: triggerQtys, itemNids: itemNids)
        
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
            let itemNid = promoItem.itemNid
            
            // I have an earned discount, but the item isn't even on the order
            
            guard let orderLinesForThisItem = orderLinesByItemNid[itemNid] else {
                continue
            }
            
            // if this is not a contract promo, then don't apply it to items that are covered by a contract promo.
            if !dcPromoSection.isContractPromo && !dcPromoSection.isAdditionalFee && itemNidsCoveredByContractPromos.contains(itemNid) {
                continue
            }
            
            // compute cents-off discounts (eg) on lines that were not totally used as BuyXGetY promos (as free goods or trigger items). But, keep lines that came in as zero-quantity lines (just to return the case-1 discount)
            for orderLine in orderLinesForThisItem.filter({x in x.qtyAvailableForStandardPromos > 0 || x.qtyAvailableToDiscount == 0 })
            {
                let earlierTierDiscounts = earlierTierDiscountsByOrderLine[orderLine.seq] ?? []
                let earlierDiscounts = earlierTierDiscounts.map { $0.unitDisc }.reduce(MoneyWithoutCurrency.zero, +)
                
                var unitPriceToUse = orderLine.frontlinePrice - earlierDiscounts
                
                if dcPromoSection.promoPlan == .OffInvoiceAccrual && dcPromoSection.promoSectionRecord.isPercentOff {
                    unitPriceToUse = (orderLine.dcOrderLine.unitPrice ?? .zero) - orderLine.dcOrderLine.unitDiscount
                }
                
                let unitPrice = unitPriceToUse.withCurrency(transactionCurrency)
                let unitSplitCaseCharge = orderLine.dcOrderLine.unitSplitCaseCharge.withCurrency(transactionCurrency)
                
                guard var unitDiscount = promoItem.getUnitDisc(promoCurrency: promoCurrency, unitPrice: unitPrice, nbrPriceDecimals: nbrPriceDecimals, unitSplitCaseCharge: unitSplitCaseCharge) else {
                    continue
                }
                
                if promoItem.promoRateType == .amountOff && qtyOnOrderInTotal > 0 {
                    let rawProrated = unitDiscount.decimalValue / Decimal(qtyOnOrderInTotal)
                    let proratedDiscount = Money(rawProrated, transactionCurrency, numberOfDecimals: nbrPriceDecimals)
                    unitDiscount = proratedDiscount
                }
                
                if (dcPromoSection.isAdditionalFee) {
                    unitDiscount = -unitDiscount
                }
                
                let unitDiscountWithoutCurrency = unitDiscount.withoutCurrency()
                
                let promoDiscount = PromoDiscount(dcOrderLine: orderLine.dcOrderLine, qtyDiscounted: orderLine.qtyAvailableForStandardPromos, unitDisc: unitDiscountWithoutCurrency, rebateAmount: promoItem.unitRebate)
                
                allDiscounts.append(promoDiscount)
            }
        }
        
        return allDiscounts
    }
}
