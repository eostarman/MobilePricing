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
    
    
    init(transactionCurrency: Currency, cusNid: Int, promoDate: Date, deliveryDate: Date, promoSections: [PromoSectionRecord], triggerQtys: TriggerQtys) {
        self.transactionCurrency = transactionCurrency
        self.cusNid = cusNid
        self.promoDate = promoDate
        self.deliveryDate = deliveryDate
        self.triggerQtys = triggerQtys
        
        numberOfDecimalsInLineItemPrices = mobileDownload.handheld.nbrPriceDecimals
        
        useQtyOrderedForPricingAndPromos = mobileDownload.handheld.useQtyOrderedForPricingAndPromos
        mayUseQtyOrderedForBuyXGetY = !mobileDownload.handheld.doNotUseQtyOrderedForBuyXGetY
        
        // round up all promotions that are available to the CusNid on the given PromoDate
        activePromoSections = promoSections.map { DCPromoSection(promoSectionRecord: $0, transactionCurrency: transactionCurrency) }
            .filter({ $0.promoPlan != .Unsupported })
        
        itemPromoSections = ItemPromoSections(activePromoSections: activePromoSections)
        
        //We want to do default promos last so we know whether or not to adjust the front line price, based on the CMA promos (ie $20 price item with $15 CMA gets $5 disc max)
        activePromoPlans = activePromoSections.map({ $0.promoPlan }).unique().sorted()
        
        let contractPromoSections = promoSections.filter { $0.isContractPromo }
        itemNidsCoveredByContractPromos = Set(contractPromoSections.flatMap({ $0.getTargetItemNids()}))
        
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
    
    static func getBestStandardPromoAndAllStackablePromosAndAdditionalFeesForEachOrderLine(standardPromoTuples: [PromoTuple]) -> [PromoTuple]
    {
        var results: [PromoTuple] = []
        
        let tuplesByOrderLine = Dictionary(grouping: standardPromoTuples) { $0.promoDiscount.dcOrderLine.seq }
        
        for (_, tuples) in tuplesByOrderLine {
            // we're looking at a single orderLine here - if there's only one tuple, then use it. Otherwise, categorize and process the list of tuples
            if tuples.count == 1 {
                results.append(contentsOf: tuples)
                continue
            }
            
            let sortedDiscounts: [PromoTuple] = tuples
                .sorted { x, y in
                    // largest discount first
                    if x.promoDiscount.unitDisc != y.promoDiscount.unitDisc {
                        return x.promoDiscount.unitDisc > y.promoDiscount.unitDisc
                    }
                    
                    // if there are two sections with the largest discount, then the most-recently-started section is first
                    if x.dcPromoSection.promoSectionRecord.startDate != y.dcPromoSection.promoSectionRecord.startDate {
                        return x.dcPromoSection.promoSectionRecord.startDate > y.dcPromoSection.promoSectionRecord.startDate
                    }
                    
                    return x.dcPromoSection.promoSectionRecord.recNid < y.dcPromoSection.promoSectionRecord.recNid
                }
            
            var nonStackedPromos: [PromoTuple] = []
            var offInvoiceAccruals: [PromoTuple] = []
            var stackedPromos: [PromoTuple] = []
            var additionalFees: [PromoTuple] = []
            var additionalTaxes: [PromoTuple] = []
            
            // put the discounts into these 5 buckets
            for discount in sortedDiscounts {
                let section = discount.dcPromoSection.promoSectionRecord
                switch section.promoPlan {
                case .Stackable:
                    stackedPromos.append(discount)
                case .AdditionalFee:
                    if section.additionalFeePromo_IsTax {
                        additionalTaxes.append(discount)
                    } else {
                        additionalFees.append(discount)
                    }
                case .OffInvoiceAccrual:
                    offInvoiceAccruals.append(discount)
                default:
                    nonStackedPromos.append(discount)
                }
            }
            
            if let bestNonStackedPromo = nonStackedPromos.first {
                results.append(bestNonStackedPromo)
            }
            results.append(contentsOf: offInvoiceAccruals)
            results.append(contentsOf: stackedPromos)
            results.append(contentsOf: additionalFees)
            results.append(contentsOf: additionalTaxes)
        }
        
        return results
    }
    
    
    func computeDiscountsForOnePromoPlan(dcOrderLines: [IDCOrderLine], freebiesNeedingNewOrderLines: [FreebieNeedingNewOrderLine], promoPlan: ePromoPlan) {
        let allPromoTuples = getPromoTuplesThatProvideDiscountsOrFreeGoodsAndAccumulateUnusedFreebies(dcOrderLines: dcOrderLines, promoPlan: promoPlan, processingTaxes: false)
        
        let allTaxPromoTuples: [PromoTuple]
        if (promoPlan == ePromoPlan.Default) {
            allTaxPromoTuples = getPromoTuplesThatProvideDiscountsOrFreeGoodsAndAccumulateUnusedFreebies(dcOrderLines: dcOrderLines, promoPlan: ePromoPlan.Default, processingTaxes: true)
        } else {
            allTaxPromoTuples = []
        }
        
        let allBuyXGetYPromosSorted = allPromoTuples
            .filter({ $0.dcPromoSection.promoSectionRecord.isBuyXGetY})
            .sorted { x, y in
                // largest discount first
                if x.dcPromoSection.promoSectionRecord.qtyX != y.dcPromoSection.promoSectionRecord.qtyX {
                    return x.dcPromoSection.promoSectionRecord.qtyX > y.dcPromoSection.promoSectionRecord.qtyX
                }
                
                return x.promoDiscount.dcOrderLine.seq < y.promoDiscount.dcOrderLine.seq
            }
        
        let buyXgetYPromos = Dictionary(grouping: allBuyXGetYPromosSorted) { $0.promoDiscount.dcOrderLine.seq }
        
        var standardPromoTuples = allPromoTuples.filter { !$0.dcPromoSection.promoSectionRecord.isBuyXGetY }
        standardPromoTuples.append(contentsOf: allTaxPromoTuples)
        
        let nonBuyXGetYPromos = Dictionary(grouping: Self.getBestStandardPromoAndAllStackablePromosAndAdditionalFeesForEachOrderLine(standardPromoTuples: standardPromoTuples)) { $0.promoDiscount.dcOrderLine.seq }
        
        switch promoPlan {
        case .CCFOffInvoice, .CCFOnInvoice, .CMAOffInvoice, .CMAOnInvoice, .CTMOffInvoice, .CTMOnInvoice, .OffInvoiceAccrual:
            for dcOrderLine in dcOrderLines {
                if let promoTuples = nonBuyXGetYPromos[dcOrderLine.seq], let best = promoTuples.first {
                    let promoSectionNid = best.dcPromoSection.promoSectionRecord.recNid
                    dcOrderLine.addDiscountOrFee(promoPlan: promoPlan, promoSectionNid: promoSectionNid, qtyDiscounted: best.promoDiscount.qtyDiscounted, unitDisc: best.promoDiscount.unitDisc, rebateAmount: best.promoDiscount.rebateAmount)
                }
            }
            
        case .Default, .Stackable, .AdditionalFee:
            for dcOrderLine in dcOrderLines {
                if let freeGoods = buyXgetYPromos[dcOrderLine.seq] {
                    for freeGood in freeGoods {
                        let promoSectionNid = freeGood.dcPromoSection.promoSectionRecord.recNid
                        let qtyFree = freeGood.promoDiscount.qtyDiscounted
                        dcOrderLine.addFreeGoods(promoSectionNid: promoSectionNid, qtyFree: qtyFree)
                    }
                }
                
                if let promoTuples = nonBuyXGetYPromos[dcOrderLine.seq] {
                    
                    for promoTuple in promoTuples {
                        let promoSectionNid = promoTuple.dcPromoSection.promoSectionRecord.recNid
                        
                        let qtyDiscounted = dcOrderLine.qtyNotFree
                        //let netPrice = dcOrderLine.totalOfAllUnitDiscounts
                        let unitDisc = promoTuple.promoDiscount.unitDisc
                        let rebateAmount = promoTuple.promoDiscount.rebateAmount
                        
                        dcOrderLine.addDiscountOrFee(promoPlan: promoPlan, promoSectionNid: promoSectionNid, qtyDiscounted: qtyDiscounted, unitDisc: unitDisc, rebateAmount: rebateAmount)
                    }
                    
                }
            }
            
            break
        }
        
    }

}
