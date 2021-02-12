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
    
    private func getNonBuyXGetYSolution(_ promoSections: [DCPromoSection], _ dcOrderLines: [DCOrderLine], _ promoPlan: ePromoPlan, triggeredFlag: Bool, processingTaxes: Bool) -> NonBuyXGetYSolution {
        
        var promoSolution = NonBuyXGetYSolution()
        
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
            
            let promoDiscounts = NonBuyXGetYService.computeNonBuyXGetYDiscountsOnThisOrder(transactionCurrency: transactionCurrency,
                                                                                           promoDate: promoDate,
                                                                                           dcPromoSection: promoSection,
                                                                                           orderLinesByItemNid: orderLinesByItemNid,
                                                                                           nbrPriceDecimals: numberOfDecimalsInLineItemPrices,
                                                                                           triggeredFlag: triggeredFlag)
            
            for promoDiscount in promoDiscounts {
                let promoTuple = PromoTuple(promoSectionRecord: promoSection.promoSectionRecord, promoDiscount: promoDiscount)
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
        let standardPromoTuples = allPromoTuples.filter { !$0.promoSectionRecord.isBuyXGetY }
        
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
                    if x.promoSectionRecord.startDate != y.promoSectionRecord.startDate {
                        return x.promoSectionRecord.startDate > y.promoSectionRecord.startDate
                    }
                    
                    return x.promoSectionRecord.recNid < y.promoSectionRecord.recNid
                }
            
            var nonStackedPromos: [PromoTuple] = []
            var offInvoiceAccruals: [PromoTuple] = []
            var stackedPromos: [PromoTuple] = []
            var additionalFees: [PromoTuple] = []
            var additionalTaxes: [PromoTuple] = []
            
            // put the discounts into these 5 buckets
            for discount in sortedDiscounts {
                let section = discount.promoSectionRecord
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
    
    private func getBuyXGetYPromoSolution(_ promoSections: [DCPromoSection], _ dcOrderLines: [DCOrderLine]) -> BuyXGetYSolution {
        
        // old note: for BuyX, it's important to put the largest (X) first (so, Buy5get3 and Buy2Get1 will work)
        
        let freebieAccumulators = getFreebieAccumulators(dcOrderLines)
        
        let buyXgetYSolution = BuyXGetYService.getBuyXGetYPromos(transactionCurrency: transactionCurrency, promoDate: promoDate, allPromoSections: promoSections, orderLines: freebieAccumulators, itemNidsCoveredByContractPromos: itemNidsCoveredByContractPromos)
        
        let allBuyXGetYPromosSorted = buyXgetYSolution.promoTuples
            //.filter({ $0.dcPromoSection.promoSectionRecord.isBuyXGetY})
            .sorted { x, y in
                // largest discount first
                if x.promoSectionRecord.qtyX != y.promoSectionRecord.qtyX {
                    return x.promoSectionRecord.qtyX > y.promoSectionRecord.qtyX
                }
                
                return x.dcOrderLine.seq < y.dcOrderLine.seq
            }
        
        return BuyXGetYSolution(allBuyXGetYPromosSorted, buyXgetYSolution.unusedFreebies)
    }
    
    private func getPromoSolutionForOnePromoPlan(_ promoSections: [DCPromoSection], _ dcOrderLines: [DCOrderLine], _ promoPlan: ePromoPlan, triggeredFlag: Bool, processingTaxes: Bool = false) -> NonBuyXGetYSolution {
        
        let promoSolution = getNonBuyXGetYSolution(promoSections, dcOrderLines, promoPlan, triggeredFlag: triggeredFlag, processingTaxes: processingTaxes)
        
        if !triggeredFlag {
            return NonBuyXGetYSolution(promoSolution)
        }
        
        let bestPromoTuples = Self.getBestStandardPromoAndAllStackablePromosAndAdditionalFeesForEachOrderLine(promoSolution.promoTuples)
        
        return NonBuyXGetYSolution(bestPromoTuples)
    }
    
    private func applyPromoSolutionToOrderLines(_ promoSolution: BuyXGetYSolution, _ dcOrderLines: [DCOrderLine]) {
        if promoSolution.promoTuples.isEmpty {
            return
        }
        
        let promosByOrderLine = Dictionary(grouping: promoSolution.promoTuples) { $0.dcOrderLine.seq }
        
        for dcOrderLine in dcOrderLines {
            guard let promoTuples = promosByOrderLine[dcOrderLine.seq] else {
                continue
            }
            
            for promoTuple in promoTuples {
                
                let promoSectionNid = promoTuple.promoSectionRecord.recNid
                let qtyFree = promoTuple.qtyDiscounted
                let rebateAmount = promoTuple.rebateAmount
                dcOrderLine.addFreeGoods(promoSectionNid: promoSectionNid, qtyFree: qtyFree, rebateAmount: rebateAmount)
            }
        }
    }
    
    private func applyPromoSolutionToOrderLines(_ promoSolution: NonBuyXGetYSolution, _ dcOrderLines: [DCOrderLine], triggeredFlag: Bool) {
        if promoSolution.promoTuples.isEmpty {
            return
        }
        
        let promosByOrderLine = Dictionary(grouping: promoSolution.promoTuples) { $0.dcOrderLine.seq }
        
        for dcOrderLine in dcOrderLines {
            guard let promoTuples = promosByOrderLine[dcOrderLine.seq] else {
                continue
            }
            
            if !triggeredFlag {
                for promoTuple in promoTuples {
                    if promoTuple.isFromBuyXGetYFreePromo {
                        continue
                    }
                    let promoPlan = promoTuple.promoSectionRecord.promoPlan
                    if promoPlan == .AdditionalFee {
                        continue
                    }
                    
                    guard let potentialPromoItem = promoTuple.promoDiscount.potentialPromoItem else {
                        continue
                    }
                    
                    let potentialDiscount = PotentialDiscount(promoSection: potentialPromoItem.promoSection, triggerRequirements: potentialPromoItem.triggerRequirements, triggerQtys: potentialPromoItem.triggerQtys, promoItem: potentialPromoItem.promoItem, unitDiscount: promoTuple.unitDisc)
                    
                    dcOrderLine.addPotentialDiscount(potentialDiscount: potentialDiscount)
                }
                continue
            }
            
            for promoTuple in promoTuples {
                
                if promoTuple.isFromBuyXGetYFreePromo {
                    let promoSectionNid = promoTuple.promoSectionRecord.recNid
                    let qtyFree = promoTuple.qtyDiscounted
                    let rebateAmount = promoTuple.rebateAmount
                    dcOrderLine.addFreeGoods(promoSectionNid: promoSectionNid, qtyFree: qtyFree, rebateAmount: rebateAmount)
                } else {
                    let promoPlan = promoTuple.promoSectionRecord.promoPlan
                    
                    let promoSectionNid = promoTuple.promoSectionRecord.recNid
                    
                    let unitDisc = promoTuple.unitDisc
                    let rebateAmount = promoTuple.rebateAmount
                    
                    if promoPlan == .AdditionalFee {
                        if promoTuple.promoSectionRecord.isTax {
                            dcOrderLine.addCharge(.tax(amount: unitDisc, promoSectionNid: promoSectionNid))
                        } else {
                            dcOrderLine.addCharge(.fee(amount: unitDisc, promoSectionNid: promoSectionNid))
                        }
                    } else {
                        dcOrderLine.addDiscount(promoPlan: promoPlan, promoSectionNid: promoSectionNid, unitDisc: unitDisc, rebateAmount: rebateAmount)
                    }
                }
            }
        }
    }
    
    private func computeDiscountsTierByTier(_ tiers: Tiers, _ dcOrderLines: [DCOrderLine], triggeredFlag: Bool) -> NonBuyXGetYSolution {
        var solution = NonBuyXGetYSolution()
        
        for tier in 0 ..< tiers.count {
            let tierSolution = computeDiscountsForOneTier(tiers[tier], dcOrderLines, triggeredFlag: triggeredFlag)
            solution.append(contentsOf: tierSolution)
        }
        
        return solution
    }
    
    private func computeDiscountsForOneTier(_ promoSections: [DCPromoSection], _ dcOrderLines: [DCOrderLine], triggeredFlag: Bool) -> NonBuyXGetYSolution {
       
        // these are Coke-specific promotions. Normally if a discount exceeds the frontline price, we reduce the discount; for the Coke promotions we instead
        // increase the frontline prices
        let cmaDiscounts = getPromoSolutionForOnePromoPlan(promoSections, dcOrderLines, .CMAOnInvoice, triggeredFlag: triggeredFlag)
        let ctmDiscounts = getPromoSolutionForOnePromoPlan(promoSections, dcOrderLines, .CTMOnInvoice, triggeredFlag: triggeredFlag)
        let ccfDiscounts = getPromoSolutionForOnePromoPlan(promoSections, dcOrderLines, .CCFOnInvoice, triggeredFlag: triggeredFlag)
        
        let defaultDiscounts = getPromoSolutionForOnePromoPlan(promoSections, dcOrderLines, .Default, triggeredFlag: triggeredFlag)
        let stackableDiscounts = getPromoSolutionForOnePromoPlan(promoSections, dcOrderLines, .Stackable, triggeredFlag: triggeredFlag)
   
        let fees = getPromoSolutionForOnePromoPlan(promoSections, dcOrderLines, .AdditionalFee, triggeredFlag: triggeredFlag, processingTaxes: false)
        let taxes = getPromoSolutionForOnePromoPlan(promoSections, dcOrderLines, .AdditionalFee, triggeredFlag: triggeredFlag, processingTaxes: true)
        
        let discountsFeesAndTaxes = NonBuyXGetYSolution(cmaDiscounts, ctmDiscounts, ccfDiscounts, defaultDiscounts, stackableDiscounts, fees, taxes)
        
        applyPromoSolutionToOrderLines(discountsFeesAndTaxes, dcOrderLines, triggeredFlag: triggeredFlag)
        
        return discountsFeesAndTaxes
    }
    
    
    @discardableResult
    public func computeDiscounts(_ dcOrderLines: DCOrderLine ...) -> PromoSolution {
        computeDiscounts(dcOrderLines: dcOrderLines)
    }
    
    /// Compute the discount from all promotions. Update the orderLines with the results, and also return the results as a single promoSolution
    /// - Parameter dcOrderLines: the lines to be discounted - these will be updated with the computed free-goods, discounts, fees and taxes. Note that the 'seq' property of the orderLines will be reset to a value from 0 ..< count (to make them unique and to determine the order of assignment of (e.g.) free goods)
    /// - Returns: the promoSolution (which contains unusedFreebies) that has been applied to the order
    public func computeDiscounts(dcOrderLines: [DCOrderLine]) -> PromoSolution {
        
        for seq in 0 ..< dcOrderLines.count {
            dcOrderLines[seq].seq = seq
            dcOrderLines[seq].clearAllPromoData()
        }
        
        let _ = computeNonContractDiscounts(dcOrderLines: dcOrderLines, triggeredFlag: false)
        
        let contractSolution = computeContractDiscounts(dcOrderLines: dcOrderLines, triggeredFlag: true)
        let nonContractSolution = computeNonContractDiscounts(dcOrderLines: dcOrderLines, triggeredFlag: true)
        
        let solution = PromoSolution(contractSolution: contractSolution, nonContractSolution: nonContractSolution)
        return solution
    }
    
    
    public func computeContractDiscounts(dcOrderLines: [DCOrderLine], triggeredFlag: Bool) -> PromoSolution {

        let contractLines = dcOrderLines.filter { itemNidsCoveredByContractPromos.contains($0.itemNid) }
        
        // Do the BuyXGetY promos first so that we can prevent applying discounts to the "free goods bundles"
        let buyXGetYSolution: BuyXGetYSolution
            
        if triggeredFlag {
            buyXGetYSolution = getBuyXGetYPromoSolution(contractPromoSections.filter({ $0.isBuyXGetY }), contractLines)
            applyPromoSolutionToOrderLines(buyXGetYSolution, contractLines)
        } else {
            buyXGetYSolution = BuyXGetYSolution()
        }
        
        let nonBuyXGetYSolution = computeDiscountsTierByTier(Tiers(contractPromoSections.filter({ !$0.isBuyXGetY })), contractLines, triggeredFlag: triggeredFlag)
        
        return PromoSolution(buyXGetYSolution, nonBuyXGetYSolution)
    }
    
    public func computeNonContractDiscounts(dcOrderLines: [DCOrderLine], triggeredFlag: Bool) -> PromoSolution {

        let nonContractLines = dcOrderLines.filter { !itemNidsCoveredByContractPromos.contains($0.itemNid) }
        
        // Do the BuyXGetY promos first so that we can prevent applying discounts to the "free goods bundles"
        let buyXGetYSolution: BuyXGetYSolution
            
        if triggeredFlag {
            buyXGetYSolution = getBuyXGetYPromoSolution(nonContractPromoSections.filter({ $0.isBuyXGetY }), nonContractLines)
            applyPromoSolutionToOrderLines(buyXGetYSolution, nonContractLines)
        } else {
            buyXGetYSolution = BuyXGetYSolution()
        }
        
        let nonBuyXGetYSolution = computeDiscountsTierByTier(Tiers(nonContractPromoSections.filter({ !$0.isBuyXGetY })), nonContractLines, triggeredFlag: triggeredFlag)
        
        return PromoSolution(buyXGetYSolution, nonBuyXGetYSolution)
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
