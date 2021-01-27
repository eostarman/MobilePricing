//  Created by Michael Rutherford on 1/23/21.

import Foundation
import MobileDownload
import MoneyAndExchangeRates

/// <summary>
/// Class to compute promotions (discounts and rebates) for an order
/// </summary>
class DiscountCalculator
{
    let transactionCurrency: Currency
    let cusNid: Int
    let promoDate: Date
    let deliveryDate: Date
    let triggerQtys: TriggerQtys
    let numberOfDecimalsInLineItemPrices: Int
    let activePromoSections: [DCPromoSection]
    let itemPromoSections: ItemPromoSections
    let activePromoPlans: [ePromoPlanForMobileInvoice]
    let useQtyOrderedForPricingAndPromos: Bool
    let mayUseQtyOrderedForBuyXGetY: Bool
    let itemNidsCoveredByContractPromos: Set<Int>
    
    var discountPromoSectionsForItem: [Int: [DCPromoSection]] = [:]
    var triggerPromoSectionsForItem: [Int: [DCPromoSection]] = [:]
    
    var unusedFreebies: [UnusedFreebie] = []
    
    
    init(transactionCurrency: Currency, cusNid: Int, promoDate: Date, deliveryDate: Date, promoSections: [PromoSection], triggerQtys: TriggerQtys) {
        self.transactionCurrency = transactionCurrency
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
        
        itemPromoSections = ItemPromoSections(activePromoSections: activePromoSections)
        
        //We want to do default promos last so we know whether or not to adjust the front line price, based on the CMA promos (ie $20 price item with $15 CMA gets $5 disc max)
        activePromoPlans = activePromoSections.map({ $0.promoPlan }).unique().sorted()
        
        let contractPromoSections = promoSections.filter { $0.promoSectionRecord.isContractPromo }
        itemNidsCoveredByContractPromos = Set(contractPromoSections.flatMap({ $0.promoSectionRecord.getTargetItemNids()}))
        
        let nonContractTriggerQtys = triggerQtys.getNonContractTriggerQtys(itemNidsCoveredByContractPromos: itemNidsCoveredByContractPromos)
        let contractTriggerQtys = triggerQtys
        
        for x in activePromoSections {
            x.resetTriggerQtys(x.isContractPromo ? contractTriggerQtys : nonContractTriggerQtys)            
        }
        
    }
    
    func getPromoTuplesThatProvideDiscountsOrFreeGoodsAndAccumulateUnusedFreebies(dcOrderLines: [IDCOrderLine], promoPlan: ePromoPlan, processingTaxes: Bool) -> [PromoTuple]
    {
        // Default will get both "normal" promotions (pick the best one, or the Buy-X-Get-Y variety) and also the stackable promos and additional fees
        if (promoPlan == ePromoPlan.Stackable || promoPlan == ePromoPlan.AdditionalFee) {
            fatalError("Logic error")
        }
        
        let orderLines = dcOrderLines.map {x in FreebieAccumulator(dcOrderLine: x, useQtyOrderedForPricingAndPromos: useQtyOrderedForPricingAndPromos, mayUseQtyOrderedForBuyXGetY: mayUseQtyOrderedForBuyXGetY) }
        
        let orderLinesByItemNid = Dictionary(grouping: orderLines) { $0.itemNid }
        
        let itemNidsToScanOnPromos = orderLines.map { $0.itemNid }.unique()
        
        func doKeep(promoSection: DCPromoSection) -> Bool {
            if !promoSection.promoSectionRecord.isAvailableOnWeekday(deliveryDate) {
                return false
            }
            
            if promoSection.isTax != processingTaxes {
                return false
            }
            
            if promoSection.promoSectionRecord.promoPlan == promoPlan {
                return true
            }
            
            if promoPlan == ePromoPlan.Default && (promoSection.promoSectionRecord.promoPlan == .Stackable || promoSection.promoSectionRecord.promoPlan == .AdditionalFee) {
                return true
            }
            
            return false
        }
        
        let allPromoSections = itemPromoSections.getAllPromoSectionsWithDiscountsForTheseItems(itemNids: itemNidsToScanOnPromos)
            .filter({x in doKeep(promoSection: x)})
        
        var resultingPromoTuples: [PromoTuple] = []
        
        // First ask each promoSection to compute the discounts for this order.
        // Do the BuyXGetY promos first so that we can prevent applying discounts to the "free goods bundles"
        // for BuyX, it's important to put the largest (X) first (so, Buy5get3 and Buy2Get1 will work)
        // for standard promos it doesn't matter ... I'll compute all the ones that are triggered, then pick the deepest discount for each item

        let (tuples, freebies) = BuyXGetYCalculator.getBuyXGetYPromos(allPromoSections: allPromoSections, orderLines: orderLines, itemNidsCoveredByContractPromos: itemNidsCoveredByContractPromos)
         
        unusedFreebies.append(contentsOf: freebies)
        resultingPromoTuples.append(contentsOf: tuples)
        
   
        // use the orderLine's Seq as the key
        var previousDiscounts: [Int: [PromoDiscount]] = [:]
        
        let nonBuyXGetYPromoSections = allPromoSections.filter { !$0.promoSectionRecord.isBuyXGetY }
        let promoSectionsByTier = Dictionary(grouping: nonBuyXGetYPromoSections) { $0.promoTierSequence ?? -1 }
        let promoTierSequences = nonBuyXGetYPromoSections.map({ $0.promoTierSequence ?? -1 }).unique().sorted()

        for promoTierSequence in promoTierSequences {
            let promoSectionsInThisTier = promoSectionsByTier[promoTierSequence]! // the sequences are the keys of this dictionary - but sorted
            
            var currentTierDiscounts: [Int: [PromoDiscount]] = [:]

            // now, scan all standard promos (cents-off, percent-off) and apply to the items not covered by the buy-x-get-y promos above
            for promoSection in promoSectionsInThisTier {
                
                guard let discountsOnThisOrder = NonBuyXGetYCalculator.computeNonBuyXGetYDiscountsOnThisOrder(transactionCurrency: transactionCurrency,
                                                                                                        dcPromoSection: promoSection,
                                                                                                        orderLinesByItemNid: orderLinesByItemNid,
                                                                                                        nbrPriceDecimals: numberOfDecimalsInLineItemPrices,
                                                                                                        itemNidsCoveredByContractPromos: itemNidsCoveredByContractPromos,
                                                                                                        earlierTierDiscountsByOrderLine: previousDiscounts)
                else {
                    continue
                }

                for promoDiscount in discountsOnThisOrder.discounts {
                    let promoTuple = PromoTuple(dcPromoSection: promoSection, promoDiscount: promoDiscount)
                    resultingPromoTuples.append(promoTuple)
                    
                    if var existing = currentTierDiscounts[promoDiscount.dcOrderLine.seq] {
                        existing.append(promoDiscount)
                    } else {
                        currentTierDiscounts[promoDiscount.dcOrderLine.seq] = [promoDiscount]
                    }
                }
            }
            
            for (orderLineSeq, promoDiscounts) in currentTierDiscounts {
                if var prior = previousDiscounts[orderLineSeq] {
                    prior.append(contentsOf: promoDiscounts)
                } else {
                    previousDiscounts[orderLineSeq] = promoDiscounts
                }
            }
        }
        
        
        return resultingPromoTuples
    }
}
