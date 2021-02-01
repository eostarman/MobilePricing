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

    let nonContractPromoSections: [DCPromoSection]
    let contractPromoSections: [DCPromoSection]
    let itemNidsCoveredByContractPromos: Set<Int>
    
    var useQtyOrderedForPricingAndPromos: Bool { mobileDownload.handheld.useQtyOrderedForPricingAndPromos }
    var mayUseQtyOrderedForBuyXGetY: Bool { !mobileDownload.handheld.doNotUseQtyOrderedForBuyXGetY }
    
    public static func getPromoSectionRecords(cusNid: Int, promoDate: Date, deliveryDate: Date) -> [PromoSectionRecord] {
        
        let promoCodesForThisCustomer = Set(mobileDownload.promoCodes.getAll().filter({ $0.isCustomerSelected(cusNid) }).map { $0.recNid })

        func doKeep(promoSection: PromoSectionRecord) -> Bool {

            if !promoCodesForThisCustomer.contains(promoSection.promoCodeNid) {
                return false
            }
            
            if !promoSection.isActiveOnDate(promoDate) {
                return false
            }

            if !promoSection.isAvailableOnWeekday(deliveryDate) {
                return false
            }
            
            if promoSection.getTargetItemNids().isEmpty {
                return false
            }
            
            switch promoSection.promoPlan {
            case .Default, .Stackable, .AdditionalFee, .CCFOnInvoice, .CTMOnInvoice, .CMAOnInvoice:
                return true
                
            case .OffInvoiceAccrual, .CCFOffInvoice, .CTMOffInvoice, .CMAOffInvoice:
                return false
            }
        }
        
        let allPromoSections = mobileDownload.promoSections.getAll().filter({x in doKeep(promoSection: x)})
        return allPromoSections
    }

    init(transactionCurrency: Currency, promoSections: [PromoSectionRecord]) {
        self.transactionCurrency = transactionCurrency
        
        // round up all promotions that are available to the CusNid on the given PromoDate
        let allActivePromoSections = promoSections.map { DCPromoSection(promoSectionRecord: $0, transactionCurrency: transactionCurrency) }

        let allContractPromoSections = allActivePromoSections.filter { $0.isContractPromo }
        
        if allContractPromoSections.isEmpty {
            nonContractPromoSections = allActivePromoSections
            contractPromoSections = []
            itemNidsCoveredByContractPromos = []
        } else {
            nonContractPromoSections = allActivePromoSections.filter { !$0.isContractPromo }
            contractPromoSections = allContractPromoSections
            itemNidsCoveredByContractPromos = Set(allContractPromoSections.flatMap({ $0.promoSectionRecord.getTargetItemNids()}))
        }

    }
    
    private func getFreebieAccumulators(_ dcOrderLines: [IDCOrderLine]) -> [FreebieAccumulator] {
        
        let orderLines = dcOrderLines.map {x in FreebieAccumulator(dcOrderLine: x, useQtyOrderedForPricingAndPromos: useQtyOrderedForPricingAndPromos, mayUseQtyOrderedForBuyXGetY: mayUseQtyOrderedForBuyXGetY) }
        
        return orderLines
    }
    
    private func getNonBuyXGetYPromoSections(_ promoSections: [DCPromoSection], _ dcOrderLines: [IDCOrderLine], _ promoPlan: ePromoPlan, processingTaxes: Bool) -> [DCPromoSection] {
        
        let itemNidsOnTheOrder = dcOrderLines.map { $0.itemNid }.unique()
        
        func doKeep(promoSection: DCPromoSection) -> Bool {
            if promoSection.promoSectionRecord.isBuyXGetY {
                return false
            }
  
            if promoSection.promoSectionRecord.promoPlan != promoPlan {
                return false
            }
            
            if promoPlan == .AdditionalFee {
                if promoSection.promoSectionRecord.additionalFeePromo_IsTax != processingTaxes {
                    return false
                }
            }

            if !promoSection.isTarget(forAnyItemNid: itemNidsOnTheOrder) {
                return false
            }
            
            return true
        }
        
        let allPromoSections = promoSections.filter({x in doKeep(promoSection: x)})
        
        return allPromoSections
    }
    
    private func getPromoTuplesThatProvideDiscounts(_ promoSections: [DCPromoSection], _ dcOrderLines: [IDCOrderLine], _ promoPlan: ePromoPlan, processingTaxes: Bool) -> PromoSolution {

        let orderLines = getFreebieAccumulators(dcOrderLines)
        
        let allPromoSections = getNonBuyXGetYPromoSections(promoSections, dcOrderLines, promoPlan, processingTaxes: processingTaxes)

        var resultingSolution = PromoSolution()
        
        // use the orderLine's Seq as the key
        var previousDiscounts: [Int: [PromoDiscount]] = [:]
        
        let orderLinesByItemNid = Dictionary(grouping: orderLines) { $0.itemNid }
        
        let nonBuyXGetYPromoSections = allPromoSections.filter { !$0.promoSectionRecord.isBuyXGetY }
        let promoSectionsByTier = Dictionary(grouping: nonBuyXGetYPromoSections) { $0.promoTierSequence ?? -1 }
        let promoTierSequences = nonBuyXGetYPromoSections.map({ $0.promoTierSequence ?? -1 }).unique().sorted()
        
        let numberOfDecimalsInLineItemPrices = mobileDownload.handheld.nbrPriceDecimals
        
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
                    resultingSolution.append(promoTuple)
                    
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
        
        return resultingSolution
    }
    
    private static func getBestStandardPromoAndAllStackablePromosAndAdditionalFeesForEachOrderLine(_ allPromoTuples: [PromoTuple]) -> [PromoTuple] {
        let standardPromoTuples = allPromoTuples.filter { !$0.dcPromoSection.promoSectionRecord.isBuyXGetY }
        
        if standardPromoTuples.isEmpty {
            return []
        }
        
        var results: [PromoTuple] = []
        
        let tuplesByOrderLine = Dictionary(grouping: standardPromoTuples) { $0.dcOrderLine.seq }
        
        for (_, tuples) in tuplesByOrderLine {
            // we're looking at a single orderLine here - if there's only one tuple, then use it. Otherwise, categorize and process the list of tuples
            if tuples.count == 1 {
                results.append(contentsOf: tuples)
                continue
            }
            
            let sortedDiscounts: [PromoTuple] = tuples
                .sorted { x, y in
                    // largest discount first
                    if x.unitDisc != y.unitDisc {
                        return x.unitDisc > y.unitDisc
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
    
    private func getBuyXGetYPromoSolution(_ promoSections: [DCPromoSection], _ dcOrderLines: [IDCOrderLine]) -> PromoSolution {
        let freebieAccumulators = getFreebieAccumulators(dcOrderLines)
        
        let buyXgetYSolution = BuyXGetYCalculator.getBuyXGetYPromos(transactionCurrency: transactionCurrency, allPromoSections: promoSections, orderLines: freebieAccumulators, itemNidsCoveredByContractPromos: itemNidsCoveredByContractPromos)
        
        let allBuyXGetYPromosSorted = buyXgetYSolution.promoTuples
            //.filter({ $0.dcPromoSection.promoSectionRecord.isBuyXGetY})
            .sorted { x, y in
                // largest discount first
                if x.dcPromoSection.promoSectionRecord.qtyX != y.dcPromoSection.promoSectionRecord.qtyX {
                    return x.dcPromoSection.promoSectionRecord.qtyX > y.dcPromoSection.promoSectionRecord.qtyX
                }
                
                return x.dcOrderLine.seq < y.dcOrderLine.seq
            }
        
        return PromoSolution(allBuyXGetYPromosSorted, buyXgetYSolution.unusedFreebies)
    }
    
    private func getPromoSolutionForOnePromoPlan(_ promoSections: [DCPromoSection], _ dcOrderLines: [IDCOrderLine], _ promoPlan: ePromoPlan, processingTaxes: Bool = false) -> PromoSolution {
        
        let promoSolution = getPromoTuplesThatProvideDiscounts(promoSections, dcOrderLines, promoPlan, processingTaxes: false)

        let bestPromoTuples = Self.getBestStandardPromoAndAllStackablePromosAndAdditionalFeesForEachOrderLine(promoSolution.promoTuples)
        
        return PromoSolution(bestPromoTuples, promoSolution.unusedFreebies)
    }
    
    private func applyPromoSolutionToOrderLines(_ promoSolution: PromoSolution, _ dcOrderLines: [IDCOrderLine]) {
        let promosByOrderLine = Dictionary(grouping: promoSolution.promoTuples) { $0.dcOrderLine.seq }
        
        for dcOrderLine in dcOrderLines {
            guard let promoTuples = promosByOrderLine[dcOrderLine.seq] else {
                continue
            }
            
            for promoTuple in promoTuples {
                
                if promoTuple.isFromBuyXGetYFreePromo {
                    let promoSectionNid = promoTuple.dcPromoSection.promoSectionRecord.recNid
                    let qtyFree = promoTuple.qtyDiscounted
                    dcOrderLine.addFreeGoods(promoSectionNid: promoSectionNid, qtyFree: qtyFree)
                } else {
                    let promoPlan = promoTuple.dcPromoSection.promoSectionRecord.promoPlan
                    
                    let promoSectionNid = promoTuple.dcPromoSection.promoSectionRecord.recNid
                    
                    let qtyDiscounted = dcOrderLine.qtyNotFree
                    //let netPrice = dcOrderLine.totalOfAllUnitDiscounts
                    let unitDisc = promoTuple.unitDisc
                    let rebateAmount = promoTuple.rebateAmount
                    
                    dcOrderLine.addDiscountOrFee(promoPlan: promoPlan, promoSectionNid: promoSectionNid, qtyDiscounted: qtyDiscounted, unitDisc: unitDisc, rebateAmount: rebateAmount)
                }
            }
        }
    }
    
    private func computeDiscounts(_ promoSections: [DCPromoSection], _ dcOrderLines: [IDCOrderLine]) -> PromoSolution {
        
        // First ask each promoSection to compute the discounts for this order.
        // Do the BuyXGetY promos first so that we can prevent applying discounts to the "free goods bundles"
        // for BuyX, it's important to put the largest (X) first (so, Buy5get3 and Buy2Get1 will work)
        // for standard promos it doesn't matter ... I'll compute all the ones that are triggered, then pick the deepest discount for each item
 
        let buyXGetYSolution = getBuyXGetYPromoSolution(promoSections, dcOrderLines)
        applyPromoSolutionToOrderLines(buyXGetYSolution, dcOrderLines)
        
        // these are Coke-specific promotions. Normally if a discount exceeds the frontline price, we reduce the discount; for the Coke promotions we instead
        // increase the frontline prices
        let cmaDiscounts = getPromoSolutionForOnePromoPlan(promoSections, dcOrderLines, .CMAOnInvoice)
        let ctmDiscounts = getPromoSolutionForOnePromoPlan(promoSections, dcOrderLines, .CTMOnInvoice)
        let ccfDiscounts = getPromoSolutionForOnePromoPlan(promoSections, dcOrderLines, .CCFOnInvoice)
        
        let defaultDiscounts = getPromoSolutionForOnePromoPlan(promoSections, dcOrderLines, .Default)
        let stackableDiscounts = getPromoSolutionForOnePromoPlan(promoSections, dcOrderLines, .Stackable)
        
        let allDefaultDiscounts = PromoSolution(cmaDiscounts, ctmDiscounts, ccfDiscounts, defaultDiscounts, stackableDiscounts)
        applyPromoSolutionToOrderLines(allDefaultDiscounts, dcOrderLines)
        
        let additionalFees = getPromoSolutionForOnePromoPlan(promoSections, dcOrderLines, .AdditionalFee, processingTaxes: false)
        let lineItemTaxes = getPromoSolutionForOnePromoPlan(promoSections, dcOrderLines, .AdditionalFee, processingTaxes: true)
        
        let feesAndTaxes = PromoSolution(additionalFees, lineItemTaxes)
        applyPromoSolutionToOrderLines(feesAndTaxes, dcOrderLines)
        
        let solution = PromoSolution(buyXGetYSolution, allDefaultDiscounts, feesAndTaxes)
        return solution
    }
    
    /// Compute the discount from all promotions. Update the orderLines with the results, and also return the results as a single promoSolution
    /// - Parameter dcOrderLines: the lines to be discounted - these will be updated with the computed free-goods, discounts, fees and taxes
    /// - Returns: the promoSolution (which contains unusedFreebies) that has been applied to the order
    func computeDiscounts(_ dcOrderLines: [IDCOrderLine]) -> PromoSolution {

        if itemNidsCoveredByContractPromos.isEmpty {
            return computeDiscounts(nonContractPromoSections, dcOrderLines)
        } else {
            let contractLines = dcOrderLines.filter { itemNidsCoveredByContractPromos.contains($0.itemNid) }
            let nonContractLines = dcOrderLines.filter { !itemNidsCoveredByContractPromos.contains($0.itemNid) }
            
            let contractDiscounts = computeDiscounts(contractPromoSections, contractLines)
            let nonContractDiscounts = computeDiscounts(nonContractPromoSections, nonContractLines)
            
            let solution = PromoSolution(contractDiscounts, nonContractDiscounts)
            return solution
        }
    }
}
