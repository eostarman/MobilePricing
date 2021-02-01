//  Created by Michael Rutherford on 1/23/21.

import Foundation
import MobileDownload
import MoneyAndExchangeRates

struct BuyXGetYCalculator {
    
    /// Compute a collection of zero or more FreebieBundles. A FreebieBundle describe the earned free-goods - some may be on the order and some may not be on the order yet. The orderLines are wrapped in FreebieAccumulator
    /// objects - this is so we can track how many items were used to produce free goods so we don't discount them unless that's allowed.
    /// - Parameters:
    ///   - promoSection: the buy-x-get-y free promotion
    ///   - triggers: triggers from the orderLines on the order
    ///   - targets: targets for the orderLines on the order
    /// - Returns: a collection of zero or more FreebieBundles (these describe the earned free-goods - some may be on the order
    private static func getFreebieBundles(promoSection: PromoSectionRecord, triggers: [FreebieAccumulator], targets:[FreebieAccumulator]) -> [FreebieBundle] {
        if triggers.isEmpty {
            return []
        }
        
        let triggersByTriggerGroup = Dictionary(grouping: triggers) { $0.triggerGroup }
        let triggersByItem = Dictionary(grouping: triggers) { $0.itemNid }
        
        var triggerGroupsSatisfied = promoSection.triggerGroupsWithNonZeroMinimums.isEmpty
        
        var resultingBundles: [FreebieBundle] = []
        
        while true {
            var isTriggered = true
            
            if promoSection.isMixAndMatch {
                var qty = promoSection.qtyX
                
                if !triggerGroupsSatisfied {
                    // Here, we are going through the trigger groups for the "Additional Requirements" section in the promo sections panel
                    for triggerGroup in promoSection.triggerGroupsWithNonZeroMinimums {
                        var triggerGroupMinimum = promoSection.getTriggerGroupMinimum(triggerGroup: triggerGroup)
                        
                        guard let triggers = triggersByTriggerGroup[triggerGroup] else {
                            continue
                        }
                        
                        for trigger in triggers.filter({ $0.qtyUnusedInBuyXGetYPromos > 0 }) {
                            let qtyToUseForTrigger = min(trigger.qtyUnusedInBuyXGetYPromos, triggerGroupMinimum)
                            
                            if qtyToUseForTrigger == 0 {
                                continue
                            }
                            
                            trigger.qtyUsedThisPass += qtyToUseForTrigger
                            
                            triggerGroupMinimum -= qtyToUseForTrigger
                            
                            qty -= qtyToUseForTrigger
                            
                            if (triggerGroupMinimum == 0) {
                                break
                            }
                        }
                        
                        if triggerGroupMinimum > 0 {
                            isTriggered = false
                            break
                        }
                    }
                    
                    triggerGroupsSatisfied = true
                }
                
                // Okay, we have not failed in the criteria for the additional requirements, let's see if we have triggers fired
                if isTriggered, qty > 0 {
                    // Deplete out the quantities to see if we have tripped the free goods trigger
                    for trigger in triggers.filter({ $0.qtyUnusedInBuyXGetYPromos > 0 }) {
                        let qtyToUseForTrigger = min(trigger.qtyUnusedInBuyXGetYPromos, qty)
                        
                        if qtyToUseForTrigger > 0 {
                            trigger.qtyUsedThisPass += qtyToUseForTrigger
                            
                            qty -= qtyToUseForTrigger
                            
                            if qty == 0 {
                                break
                            }
                        }
                    }
                    
                    if qty > 0 {
                        isTriggered = false
                    }
                }
                
            } else {
                // every item in the trigger items has a minimum required (the QtyX applies to each item individually)
                for group in triggersByItem {
                    var itemMinimum = promoSection.qtyX
                    
                    for trigger in group.value.filter({ $0.qtyUnusedInBuyXGetYPromos > 0 }) {
                        let qtyToUseForTrigger = min(trigger.qtyUnusedInBuyXGetYPromos, itemMinimum)
                        
                        if qtyToUseForTrigger > 0 {
                            trigger.qtyUsedThisPass += qtyToUseForTrigger
                            
                            itemMinimum -= qtyToUseForTrigger
                            
                            if itemMinimum == 0 {
                                break
                            }
                        }
                    }
                    
                    if itemMinimum > 0 {
                        isTriggered = false
                        break
                    }
                }
            }
            
            if !isTriggered {
                break
            }
            
            let freebieTriggers = triggers.filter({ $0.qtyUsedThisPass != 0 }).map({ FreebieTrigger(item: $0, qtyUsedAsTrigger: $0.qtyUsedThisPass) })
            let oldQtyUsedThisPass = freebieTriggers.map({ $0.item.qtyUsedThisPass })
            
            for freebieTrigger in freebieTriggers {
                if promoSection.isFullPriceTriggers {
                    freebieTrigger.item.qtyUsedAsTriggerThatMustBeFullPrice += freebieTrigger.item.qtyUsedThisPass
                } else {
                    freebieTrigger.item.qtyUsedAsTriggerThatMayBeDiscounted += freebieTrigger.item.qtyUsedThisPass
                }
                freebieTrigger.item.qtyUsedThisPass = 0
            }
            
            /* among lines that have the same UnitDisc, we try to first use lines that are as large as possible while
             * not exceeding the quantity of the promotion.  this isn't perfect (or even very good) but it makes the case work
             * where you have totally separate free goods lines each with the correct quantity of freebies for your promotion,
             * which is the common case for many people that would use multiple promotions targeting the same freebie. e.g.:
             *
             * target qty: 7
             * sorted lines: 7, 5, 4, 3, 12, 8 */
            
            var earnedQtyFree = promoSection.qtyY
            
            var freebieTargets: [FreebieTarget] = []
            
            for target in targets {
                if earnedQtyFree == 0 {
                    break
                }
                
                let qtyFreeHere = min(earnedQtyFree, target.qtyAvailableToBeFreeGoods)
                if qtyFreeHere == 0 {
                    continue
                }
                
                earnedQtyFree -= qtyFreeHere
                
                target.qtyFree += qtyFreeHere
                
                freebieTargets.append(FreebieTarget(item: target, qtyFreeHere: qtyFreeHere))
            }
            
            let qtyFree = promoSection.qtyY - earnedQtyFree // these free items are on the order
            let unusedFreeQty = earnedQtyFree    // these free items are not even on the order (UnusedFreebies)
            
            let itemNidsForUnusedFreeQty = unusedFreeQty > 0 ? promoSection.getTargetItemNids() : []
            
            // I'm not expecting a bunch of freebie entries, but maybe a single entry produced multiple times (so, I think the freebies.Where() is okay without a Dictionary<>)
            let newFreebie = FreebieBundle(freebieTriggers: freebieTriggers, freebieTargets: freebieTargets, qtyFree: qtyFree, unusedFreeQty: unusedFreeQty, itemNidsForUnusedFreeQty: itemNidsForUnusedFreeQty)
            
            resultingBundles.append(newFreebie)
            
            if qtyFree == 0 {
                // The trigger fired, but I didn't use *any* of the free goods. Let the user know that they *could* take free goods based on this promotion.
                // Since they didn't though, leave the trigger quantities available for any standard promos. If they got at least 1 free items, then the trigger items cannot be further discounted.
                for i in 0 ..< freebieTriggers.count {
                    let item = freebieTriggers[i].item
                    let qty = oldQtyUsedThisPass[i]
                    
                    if promoSection.isFullPriceTriggers {
                        item.qtyUsedAsTriggerThatMustBeFullPrice -= qty
                    } else {
                        item.qtyUsedAsTriggerThatMayBeDiscounted -= qty
                    }
                    item.qtyUsedAsTriggerWhenOnlyUnusedFreebiesWereEarned += qty
                }
            }
        }
        
        return resultingBundles
    }
    
    static func getBuyXGetYPromos(transactionCurrency: Currency, allPromoSections: [DCPromoSection], orderLines: [FreebieAccumulator], itemNidsCoveredByContractPromos: Set<Int>) -> PromoSolution {
        var buyXGetYPromos = allPromoSections.filter { $0.promoSectionRecord.isBuyXGetY }
        
        var promoTuples: [PromoTuple] = []
        var unusedFreebies: [UnusedFreebie] = []
        
        while !buyXGetYPromos.isEmpty {
            // these (3) variables refer to the promo section that provides the best discount for the customer in this pass.
            var bestClones: [FreebieAccumulator] = []
            var bestPromoDiscounts: PromoDiscounts? = nil
            var bestDCPromoSection: DCPromoSection? = nil
            
            var unusedFreebiesFromThisPass: [UnusedFreebie] = []
            var ineffectualPromoSections: [DCPromoSection] = []
            
            for promoSection in buyXGetYPromos {
                let clones = orderLines.map { $0.getClone() }
                
                let discounts = getPromoDiscounts(promoSection, clones, itemNidsCoveredByContractPromos: itemNidsCoveredByContractPromos)
                
                // here's a promo section that doesn't do anything - if triggered, it will either give me real discounts, or it'll have "potential" discounts ("unused freebies").
                if discounts.unusedFreebies.isEmpty && discounts.discounts.isEmpty {
                    ineffectualPromoSections.append(promoSection)
                    continue
                }
                
                if !discounts.unusedFreebies.isEmpty {
                    unusedFreebiesFromThisPass.append(contentsOf: discounts.unusedFreebies)
                }
                
                if !discounts.discounts.isEmpty {
                    var useThisPromoSection = false
                    
                    if let bestSoFar = bestPromoDiscounts {
                        
                        if (discounts.totalDisc > bestSoFar.totalDisc) {
                            useThisPromoSection = true
                        }
                        else if (discounts.totalDisc == bestSoFar.totalDisc && discounts.totalQtyDiscounted > bestSoFar.totalQtyDiscounted) {
                            useThisPromoSection = true
                        }
                    } else {
                        useThisPromoSection = true
                    }
                    
                    if useThisPromoSection {
                        bestClones = clones
                        bestPromoDiscounts = discounts
                        bestDCPromoSection = promoSection
                    }
                }
            }
            
            // if nothing produces a discount, then we're done (but remember to return the unused freebies if there are any).
            guard let dcPromoSection = bestDCPromoSection, let promoDiscounts = bestPromoDiscounts else {
                unusedFreebies.append(contentsOf: unusedFreebiesFromThisPass)
                break
            }
            
            // I have a "best" discount, so choose it and "apply" it
            for clone in bestClones {
                clone.updateOriginalFromThisClone()
            }
            
            unusedFreebies.append(contentsOf: promoDiscounts.unusedFreebies)
            
            let discountsByOrderLine = Dictionary(grouping: promoDiscounts.discounts) { $0.dcOrderLine.seq }
            
            for (_, discountsForOneOrderLine) in discountsByOrderLine {
                
                let discountsByAmounts = Dictionary(grouping: discountsForOneOrderLine, by: { DiscountAndRebate($0) })
                
                for (_, discountsByAmount) in discountsByAmounts {
                    let totalQtyDiscount = discountsByAmount.map {$0.qtyDiscounted }.reduce(0, +)
                    let first = discountsByAmount.first!
                    
                    let promoDiscount = PromoDiscount(dcOrderLine: first.dcOrderLine, qtyDiscounted: totalQtyDiscount, unitDisc: first.unitDisc, rebateAmount: first.rebateAmount)
                    
                    let promoTuple = PromoTuple(dcPromoSection: dcPromoSection, promoDiscount: promoDiscount)
                    promoTuples.append(promoTuple)
                }
            }
            
            // I've used it and it's done its best (given us real discounts and also any unused-freebies) - so don't use it any more.
            buyXGetYPromos.removeAll(where: { $0 === dcPromoSection })
            
            // but, these guys were useless - and they're not going to get any better going forward
            for x in ineffectualPromoSections {
                buyXGetYPromos.removeAll(where: { $0 === x })
            }
        }
        
        return PromoSolution(promoTuples, unusedFreebies)
    }
    
    fileprivate struct DiscountAndRebate : Hashable {
        let unitDisc: MoneyWithoutCurrency
        let rebateAmount: MoneyWithoutCurrency
        
        init(_ promoDiscount: PromoDiscount) {
            unitDisc = promoDiscount.unitDisc
            rebateAmount = promoDiscount.rebateAmount
        }
    }
    
    private static func resetAccumulators(_ promoSection: PromoSection, _ orderLines : [FreebieAccumulator]) {
        for line in orderLines {
            line.qtyUsedThisPass = 0
            line.setTriggerStatus(promoSection: promoSection)
        }
    }
    
    private static func getPromoDiscounts(_ promoSection: PromoSection, _ allOrderLines : [FreebieAccumulator], itemNidsCoveredByContractPromos: Set<Int>) -> PromoDiscounts {
        let orderLines: [FreebieAccumulator]
        
        if !promoSection.promoSectionRecord.isContractPromo && !itemNidsCoveredByContractPromos.isEmpty {
            orderLines = allOrderLines.filter { !itemNidsCoveredByContractPromos.contains($0.itemNid) }
        } else {
            orderLines = allOrderLines
        }
        
        resetAccumulators(promoSection, orderLines)
        
        let triggersAndTargets = FreebieTriggersAndTargets(lines: orderLines)
        
        
        // if *this order* doesn't have any valid trigger items, then don't try to compute any free goods
        if (triggersAndTargets.triggers.isEmpty)
        {
            return PromoDiscounts(promoSection: promoSection, totalDisc: .zero, discounts: [], unusedFreebies: [], freebieBundles: [])
        }
        
        var allUnusedFreebies: [UnusedFreebie] = []
        var allFreebieBundles: [FreebieBundle] = []
        
        if promoSection.promoSectionRecord.isMixAndMatch {
            for newFreebie in getFreebieBundles(promoSection: promoSection.promoSectionRecord, triggers: triggersAndTargets.triggers, targets: triggersAndTargets.targets) {
                if let oldFreebie = allFreebieBundles.filter({ newFreebie.matches(other: $0) }).first {
                    oldFreebie.nbrTimes += 1
                } else {
                    allFreebieBundles.append(newFreebie)
                }
                
                let totalUnusedFreeQty = allFreebieBundles.map({ $0.unusedFreeQty * $0.nbrTimes }).reduce(0, +)
                
                if totalUnusedFreeQty > 0 {
                    let freeItemNids = promoSection.promoSectionRecord.getFreeItemNids()
                    allUnusedFreebies.append(UnusedFreebie(promoSection: promoSection.promoSectionRecord, qtyFree: totalUnusedFreeQty, itemNids: freeItemNids))
                }
            }
        } else {
            let itemNids = orderLines.filter({ $0.isTriggerItem }).map({ $0.itemNid }).unique()
            
            let triggersByItemNid = Dictionary(grouping: triggersAndTargets.triggers) { $0.itemNid }
            let targetsByItemNid = Dictionary(grouping: triggersAndTargets.targets) { $0.itemNid }
            
            for itemNid in itemNids {
                var unusedFreebies = 0
                
                let triggers = triggersByItemNid[itemNid] ?? []
                let targets = targetsByItemNid[itemNid] ?? []
                
                let freebieBundles = getFreebieBundles(promoSection: promoSection.promoSectionRecord, triggers: triggers, targets: targets)
                
                for newFreebie in freebieBundles {
                    if let oldFreebie = allFreebieBundles.filter({ newFreebie.matches(other: $0) }).first {
                        oldFreebie.nbrTimes += 1
                    } else {
                        allFreebieBundles.append(newFreebie)
                    }
                    
                    unusedFreebies += newFreebie.unusedFreeQty
                }
                
                if unusedFreebies > 0 {
                    let unused = UnusedFreebie(promoSection: promoSection.promoSectionRecord, qtyFree: unusedFreebies, itemNids: [ itemNid ])
                    allUnusedFreebies.append(unused)
                }
            }
        }
        
        var allDiscounts: [PromoDiscount] = []
        
        for freebieBundle in allFreebieBundles {
            for b in freebieBundle.freebieTargets.filter({ $0.qtyFreeHere > 0 }) {
                let rebateAmount = promoSection.promoSectionRecord.getPromoItems().filter({ $0.itemNid == b.item.itemNid }).first?.unitRebate ?? .zero
                // mpr: bug - I've mixed the transactionCurrency with the promoCurrency
                let promoDiscount =  PromoDiscount(dcOrderLine: b.item.dcOrderLine, qtyDiscounted: freebieBundle.nbrTimes * b.qtyFreeHere, unitDisc: b.item.frontlinePrice, rebateAmount: rebateAmount)
                
                allDiscounts.append(promoDiscount)
            }
        }
        
        let totalDisc = allDiscounts.map({ $0.totalDisc }).reduce(MoneyWithoutCurrency.zero, +)
        
        let promoDiscounts = PromoDiscounts(promoSection: promoSection, totalDisc: totalDisc, discounts: allDiscounts, unusedFreebies: allUnusedFreebies, freebieBundles: allFreebieBundles)
        
        return promoDiscounts
    }
}
