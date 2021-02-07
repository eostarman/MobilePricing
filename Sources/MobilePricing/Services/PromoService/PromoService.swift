//  Created by Michael Rutherford on 1/23/21.

import Foundation
import MobileDownload
import MoneyAndExchangeRates

/// <summary>
/// Service to compute promotions (discounts and rebates), additional fees and taxes (not sales-taxes) for an order - this is from DiscountCalculator.cs
/// </summary>
public class PromoService
{
    let transactionCurrency: Currency
    let promoDate: Date
    
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
            
            if promoSection.getTargetItemNids(promoDate: promoDate).isEmpty {
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
    
    /// for creating unit tests
    public convenience init(_ customer: CustomerRecord, _ promoDate: Date, transactionCurrency: Currency = .USD) {
        let promoSections = Self.getPromoSectionRecords(cusNid: customer.recNid, promoDate: promoDate, deliveryDate: promoDate)

        self.init(transactionCurrency: transactionCurrency, promoSections: promoSections, promoDate: promoDate)
    }
    
    public init(transactionCurrency: Currency, promoSections: [PromoSectionRecord], promoDate: Date) {
        self.transactionCurrency = transactionCurrency
        self.promoDate = promoDate
        
        // round up all promotions that are available to the CusNid on the given PromoDate
        let allActivePromoSections = promoSections.map { DCPromoSection(promoSectionRecord: $0, transactionCurrency: transactionCurrency, promoDate: promoDate) }
        
        let hasContractPromoSections = allActivePromoSections.contains { $0.isContractPromo }
        if !hasContractPromoSections {
            nonContractPromoSections = allActivePromoSections
            contractPromoSections = []
            itemNidsCoveredByContractPromos = []
        } else {
            // a contract-promo will dictate the discounts for any items within the contract-promo (no other promotions can be considered for the discount unless they're also contract promos)
            // Also, we need to include the additional-fee promoSections (these control fees and (e.g.) state and excise taxes)
            
            let allContractPromoSections = allActivePromoSections.filter { $0.isContractPromo }
                
            nonContractPromoSections = allActivePromoSections.filter { !$0.isContractPromo }
            contractPromoSections = allActivePromoSections.filter { $0.isContractPromo || $0.isAdditionalFee }
            itemNidsCoveredByContractPromos = Set(allContractPromoSections.flatMap({ $0.promoSectionRecord.getTargetItemNids(promoDate: promoDate)}))
        }
    }
    
    private func getFreebieAccumulators(_ dcOrderLines: [DCOrderLine]) -> [FreebieAccumulator] {
        
        let orderLines = dcOrderLines.map {x in FreebieAccumulator(dcOrderLine: x, useQtyOrderedForPricingAndPromos: useQtyOrderedForPricingAndPromos, mayUseQtyOrderedForBuyXGetY: mayUseQtyOrderedForBuyXGetY) }
        
        return orderLines
    }
    
    private func getNonBuyXGetYPromoSections(_ promoSections: [DCPromoSection], _ dcOrderLines: [DCOrderLine], _ promoPlan: ePromoPlan, processingTaxes: Bool) -> [DCPromoSection] {
        
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
    
    private func getPromoTuplesThatProvideDiscounts(_ promoSections: [DCPromoSection], _ dcOrderLines: [DCOrderLine], _ promoPlan: ePromoPlan, processingTaxes: Bool) -> PromoSolution {
        
        var promoSolution = PromoSolution()
        
        let orderLines = getFreebieAccumulators(dcOrderLines)
        
        let nonBuyXGetYPromoSections = getNonBuyXGetYPromoSections(promoSections, dcOrderLines, promoPlan, processingTaxes: processingTaxes)
        
        if nonBuyXGetYPromoSections.isEmpty {
            return promoSolution
        }
       
        let orderLinesByItemNid = Dictionary(grouping: orderLines) { $0.itemNid }
       
        let numberOfDecimalsInLineItemPrices = mobileDownload.handheld.nbrPriceDecimals
        
        var discountsByOrderLine: [Int: [PromoDiscount]] = [:]
        
        // now, scan all standard promos (cents-off, percent-off) and apply to the items not covered by the buy-x-get-y promos above
        for promoSection in nonBuyXGetYPromoSections {
            
            let discountsOnThisOrder = NonBuyXGetYService.computeNonBuyXGetYDiscountsOnThisOrder(transactionCurrency: transactionCurrency, promoDate: promoDate,
                                                                                                          dcPromoSection: promoSection,
                                                                                                          orderLinesByItemNid: orderLinesByItemNid,
                                                                                                          nbrPriceDecimals: numberOfDecimalsInLineItemPrices)
            
            for promoDiscount in discountsOnThisOrder {
                let promoTuple = PromoTuple(dcPromoSection: promoSection, promoDiscount: promoDiscount)
                promoSolution.append(promoTuple)
                
                if var existing = discountsByOrderLine[promoDiscount.dcOrderLine.seq] {
                    existing.append(promoDiscount)
                } else {
                    discountsByOrderLine[promoDiscount.dcOrderLine.seq] = [promoDiscount]
                }
            }
        }

        return promoSolution
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
    
    private func getBuyXGetYPromoSolution(_ promoSections: [DCPromoSection], _ dcOrderLines: [DCOrderLine]) -> PromoSolution {
        let freebieAccumulators = getFreebieAccumulators(dcOrderLines)
        
        let buyXgetYSolution = BuyXGetYService.getBuyXGetYPromos(transactionCurrency: transactionCurrency, promoDate: promoDate, allPromoSections: promoSections, orderLines: freebieAccumulators, itemNidsCoveredByContractPromos: itemNidsCoveredByContractPromos)
        
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
    
    private func getPromoSolutionForOnePromoPlan(_ promoSections: [DCPromoSection], _ dcOrderLines: [DCOrderLine], _ promoPlan: ePromoPlan, processingTaxes: Bool = false) -> PromoSolution {
        
        let promoSolution = getPromoTuplesThatProvideDiscounts(promoSections, dcOrderLines, promoPlan, processingTaxes: processingTaxes)
        
        let bestPromoTuples = Self.getBestStandardPromoAndAllStackablePromosAndAdditionalFeesForEachOrderLine(promoSolution.promoTuples)
        
        return PromoSolution(bestPromoTuples, promoSolution.unusedFreebies)
    }
    
    private func applyPromoSolutionToOrderLines(_ promoSolution: PromoSolution, _ dcOrderLines: [DCOrderLine]) {
        if promoSolution.promoTuples.isEmpty {
            return
        }
        
        let promosByOrderLine = Dictionary(grouping: promoSolution.promoTuples) { $0.dcOrderLine.seq }
        
        for dcOrderLine in dcOrderLines {
            guard let promoTuples = promosByOrderLine[dcOrderLine.seq] else {
                continue
            }
            
            for promoTuple in promoTuples {
                
                if promoTuple.isFromBuyXGetYFreePromo {
                    let promoSectionNid = promoTuple.dcPromoSection.promoSectionRecord.recNid
                    let qtyFree = promoTuple.qtyDiscounted
                    let rebateAmount = promoTuple.rebateAmount
                    dcOrderLine.addFreeGoods(promoSectionNid: promoSectionNid, qtyFree: qtyFree, rebateAmount: rebateAmount)
                } else {
                    let promoPlan = promoTuple.dcPromoSection.promoSectionRecord.promoPlan
                    
                    let promoSectionNid = promoTuple.dcPromoSection.promoSectionRecord.recNid
                    
                    let unitDisc = promoTuple.unitDisc
                    let rebateAmount = promoTuple.rebateAmount
                    
                    if promoPlan == .AdditionalFee {
                        if promoTuple.dcPromoSection.isTax {
                            dcOrderLine.addTax(promoSectionNid: promoSectionNid, unitTax: unitDisc)
                        } else {
                            dcOrderLine.addFee(promoSectionNid: promoSectionNid, unitFee: unitDisc)
                        }
                    } else {
                        dcOrderLine.addDiscount(promoPlan: promoPlan, promoSectionNid: promoSectionNid, unitDisc: unitDisc, rebateAmount: rebateAmount)
                    }
                }
            }
        }
    }
    
    private func computeDiscounts(_ tiers: Tiers, _ dcOrderLines: [DCOrderLine]) -> PromoSolution {
        var solution = PromoSolution()
        
        for tier in 0 ..< tiers.count {
            let tierSolution = computeDiscountsForOneTier(tiers[tier], dcOrderLines)
            solution.append(contentsOf: tierSolution)
        }
        
        return solution
    }
    
    private func computeDiscountsForOneTier(_ promoSections: [DCPromoSection], _ dcOrderLines: [DCOrderLine]) -> PromoSolution {
        
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
   
        let fees = getPromoSolutionForOnePromoPlan(promoSections, dcOrderLines, .AdditionalFee, processingTaxes: false)
        let taxes = getPromoSolutionForOnePromoPlan(promoSections, dcOrderLines, .AdditionalFee, processingTaxes: true)
        
        let discountsFeesAndTaxes = PromoSolution(cmaDiscounts, ctmDiscounts, ccfDiscounts, defaultDiscounts, stackableDiscounts, fees, taxes)
        applyPromoSolutionToOrderLines(discountsFeesAndTaxes, dcOrderLines)
        
        let solution = PromoSolution(buyXGetYSolution, discountsFeesAndTaxes)
        return solution
    }
    
    
    @discardableResult
    public func computeDiscounts(_ dcOrderLines: DCOrderLine ...) -> PromoSolution {
        computeDiscounts(dcOrderLines)
    }
    
    /// Compute the discount from all promotions. Update the orderLines with the results, and also return the results as a single promoSolution
    /// - Parameter dcOrderLines: the lines to be discounted - these will be updated with the computed free-goods, discounts, fees and taxes. Note that the 'seq' property of the orderLines will be reset to a value from 0 ..< count (to make them unique and to determine the order of assignment of (e.g.) free goods)
    /// - Returns: the promoSolution (which contains unusedFreebies) that has been applied to the order
    public func computeDiscounts(_ dcOrderLines: [DCOrderLine]) -> PromoSolution {
        for seq in 0 ..< dcOrderLines.count {
            dcOrderLines[seq].seq = seq
            dcOrderLines[seq].clearAllPromoData()
        }
        
        if itemNidsCoveredByContractPromos.isEmpty {
            return computeDiscounts(Tiers(nonContractPromoSections), dcOrderLines)
        } else {
            let contractLines = dcOrderLines.filter { itemNidsCoveredByContractPromos.contains($0.itemNid) }
            let nonContractLines = dcOrderLines.filter { !itemNidsCoveredByContractPromos.contains($0.itemNid) }
            
            let contractDiscounts = computeDiscounts(Tiers(contractPromoSections), contractLines)
            let nonContractDiscounts = computeDiscounts(Tiers(nonContractPromoSections), nonContractLines)
            
            let solution = PromoSolution(contractDiscounts, nonContractDiscounts)
            return solution
        }
    }
    
    
    /// The promotions can be "tiered". This means that one tier is computed and applied before the second tier is compute (so that the second tier's discount is based on the first tier's discounted price). Stackable promotions are all computed from the same base frontline price
    struct Tiers {
        private let tiers: [Int]
        private let promoSectionsByTier: [Int: [DCPromoSection]]
        
        var count: Int { tiers.count }
        subscript(index: Int) -> [DCPromoSection] {
            promoSectionsByTier[tiers[index]] ?? []
        }
        
        func promoSections(tier: Int) -> [DCPromoSection] {
            promoSectionsByTier[tier] ?? []
        }
        
        init(_ promoSections: [DCPromoSection]) {
            
            promoSectionsByTier = Dictionary(grouping: promoSections) { $0.promoTierSequence }
            
            tiers = promoSections.map({ $0.promoTierSequence }).unique().sorted()
        }
    }
}
