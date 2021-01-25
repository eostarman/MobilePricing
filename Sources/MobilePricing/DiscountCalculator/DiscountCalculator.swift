//  Created by Michael Rutherford on 1/23/21.

import Foundation
import MobileDownload
import MoneyAndExchangeRates

/// <summary>
/// Class to compute promotions (discounts and rebates) for an order
/// </summary>
class DiscountCalculator
{
    let cusNid: Int
    let promoDate: Date
    let deliveryDate: Date
    let triggerQtys: TriggerQtys
    let numberOfDecimalsInLineItemPrices: Int
    let activePromoSections: [DCPromoSection]
    let activePromoPlans: [ePromoPlanForMobileInvoice]
    let useQtyOrderedForPricingAndPromos: Bool
    let mayUseQtyOrderedForBuyXGetY: Bool
    let itemNidsCoveredByContractPromos: Set<Int>
    
    var discountPromoSectionsForItem: [Int: [DCPromoSection]] = [:]
    var triggerPromoSectionsForItem: [Int: [DCPromoSection]] = [:]
    
    var unusedFreebies: [UnusedFreebie] = []
    
    init(transactionCurrency: Currency, cusNid: Int, promoDate: Date, deliveryDate: Date, promoSections: [PromoSection], triggerQtys: TriggerQtys) {
        self.cusNid = cusNid
        self.promoDate = promoDate
        self.deliveryDate = deliveryDate
        self.triggerQtys = triggerQtys
        
        numberOfDecimalsInLineItemPrices = mobileDownload.handheld.nbrPriceDecimals
        
        useQtyOrderedForPricingAndPromos = mobileDownload.handheld.useQtyOrderedForPricingAndPromos
        mayUseQtyOrderedForBuyXGetY = !mobileDownload.handheld.doNotUseQtyOrderedForBuyXGetY
        
        // round up all promotions that are available to the CusNid on the given PromoDate
        activePromoSections = promoSections.map { DCPromoSection(promoSection: $0, transactionCurrency: transactionCurrency) }
            .filter({ $0.promoPlan != .Unsupported })
        
        //We want to do default promos last so we know whether or not to adjust the front line price, based on the CMA promos (ie $20 price item with $15 CMA gets $5 disc max)
        activePromoPlans = activePromoSections.map({ $0.promoPlan }).unique().sorted()
        
        let contractPromoSections = promoSections.filter { $0.promoSectionRecord.isContractPromo }
        itemNidsCoveredByContractPromos = Set(contractPromoSections.flatMap({ $0.promoSectionRecord.getTargetItemNids()}))

        let nonContractTriggerQtys = triggerQtys.getNonContractTriggerQtys(itemNidsCoveredByContractPromos: itemNidsCoveredByContractPromos);
        let contractTriggerQtys = triggerQtys;
        
        for x in activePromoSections {
            x.resetTriggerQtys(x.isContractPromo ? contractTriggerQtys : nonContractTriggerQtys)            
        }
        
    }
    
}
