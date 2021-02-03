//  Created by Michael Rutherford on 1/20/21.

import Foundation
import MobileDownload
import MoneyAndExchangeRates

/// this wraps the original OrderLine so that I can track QtyAvailableForTrigger values across multiple BuyXGetY promos and into the off-invoice discount promos
/// (these promos shouldn't apply to an item that produced a free-good)
class FreebieAccumulator
{
    let dcOrderLine: IDCOrderLine
    let itemNid: Int
    let isPreferredFreeGoodLine: Bool
    let frontlinePrice: MoneyWithoutCurrency
    let originalQty: Int
    let qtyAvailableToDiscount: Int
    let seq: Int
    
    /// The trigger status is a function of the PromoSection I'm using (for one promo, this could be a trigger, and for another promo it could be a discounted target)
    var isTriggerItem: Bool
    var isTargetItem: Bool
    var triggerGroup: Int?
    
    /// this is a working accumulator used when processing buy-x-get-y groups (I go through the requirements, recording this value. Then, when the whole trigger is fired, I copy this into the QtyUsedAsTrigger)
    var qtyUsedThisPass: Int = 0
    
    /// when the trigger fires (causing the calculation of more QtyFree), I set this to reflect how much was consumed from this line in order to produce the new QtyFree
    var qtyUsedAsTriggerThatMustBeFullPrice: Int = 0
    var qtyUsedAsTriggerThatMayBeDiscounted: Int = 0
    var qtyUsedAsTriggerWhenOnlyUnusedFreebiesWereEarned: Int = 0
    var qtyFree: Int = 0
    
    /// I'll compute the free goods using a clone of the original accumulators. Then, when I find the "best" one, I'll use it's cloned accumulators to update the original ones.
    private let clonedFrom: FreebieAccumulator?
    
    init(cloneFrom: FreebieAccumulator) {
        dcOrderLine = cloneFrom.dcOrderLine
        itemNid = cloneFrom.itemNid
        isPreferredFreeGoodLine = cloneFrom.isPreferredFreeGoodLine
        frontlinePrice = cloneFrom.frontlinePrice
        originalQty = cloneFrom.originalQty
        qtyAvailableToDiscount = cloneFrom.qtyAvailableToDiscount
        seq = cloneFrom.seq
        isTriggerItem = cloneFrom.isTriggerItem
        isTargetItem = cloneFrom.isTargetItem
        triggerGroup = cloneFrom.triggerGroup
        qtyUsedThisPass = cloneFrom.qtyUsedThisPass
        qtyUsedAsTriggerThatMustBeFullPrice = cloneFrom.qtyUsedAsTriggerThatMustBeFullPrice
        qtyUsedAsTriggerThatMayBeDiscounted = cloneFrom.qtyUsedAsTriggerThatMayBeDiscounted
        qtyUsedAsTriggerWhenOnlyUnusedFreebiesWereEarned = cloneFrom.qtyUsedAsTriggerWhenOnlyUnusedFreebiesWereEarned
        qtyFree = cloneFrom.qtyFree
        
        self.clonedFrom = cloneFrom
    }
    
    init(dcOrderLine: IDCOrderLine, useQtyOrderedForPricingAndPromos: Bool, mayUseQtyOrderedForBuyXGetY: Bool)
    {
        self.dcOrderLine = dcOrderLine
        
        self.itemNid = dcOrderLine.itemNid
        self.isPreferredFreeGoodLine = dcOrderLine.isPreferredFreeGoodLine
        self.frontlinePrice = dcOrderLine.unitPrice ?? .zero
        
        self.originalQty = mayUseQtyOrderedForBuyXGetY && (useQtyOrderedForPricingAndPromos || dcOrderLine.basePricesAndPromosOnQtyOrdered)
            ? max(dcOrderLine.qtyOrdered ?? 0, dcOrderLine.qtyShipped ?? 0)
            : dcOrderLine.qtyShipped ?? 0
        
        qtyAvailableToDiscount = dcOrderLine.qtyShipped ?? 0
        
        seq = dcOrderLine.seq
        
        self.isTriggerItem = false
        self.isTargetItem = false
        
        self.clonedFrom = nil
    }
    
    func getClone() -> FreebieAccumulator {
        FreebieAccumulator(cloneFrom: self)
    }
    
    func updateOriginalFromThisClone()    {
        guard let clonedFrom = clonedFrom else {
            fatalError("This is not a clone")
        }
        
        clonedFrom.qtyUsedAsTriggerThatMustBeFullPrice = qtyUsedAsTriggerThatMustBeFullPrice
        clonedFrom.qtyUsedAsTriggerThatMayBeDiscounted = qtyUsedAsTriggerThatMayBeDiscounted
        clonedFrom.qtyUsedAsTriggerWhenOnlyUnusedFreebiesWereEarned = qtyUsedAsTriggerWhenOnlyUnusedFreebiesWereEarned
        clonedFrom.qtyFree = qtyFree
    }
    
    func setTriggerStatus(promoSection: PromoSection)
    {
        isTriggerItem = promoSection.isTriggerItemOrRelatedAltPack(itemNid: itemNid)
        isTargetItem = promoSection.hasDiscount(itemNid: itemNid)
        triggerGroup =  promoSection.getTriggerGroup(itemNid: itemNid)
    }
    
    var isTriggerAndTargetItem: Bool {
        isTriggerItem && isTargetItem
    }
    
    /// I fiddle with this while trying to figure out if the trigger will succeed. So, I may change it for 3 items, then discover the 4th item causes the trigger to fail
    var qtyUnusedInBuyXGetYPromos: Int {
        originalQty - qtyUsedAsTriggerThatMustBeFullPrice - qtyFree - qtyUsedAsTriggerThatMayBeDiscounted - qtyUsedAsTriggerWhenOnlyUnusedFreebiesWereEarned - qtyUsedThisPass
    }
    
    /// If we're pricing based on QtyOrdered, we need this information so we don't decide to say 1 free on a qty shipped 0 line
    var qtyAvailableToBeFreeGoods: Int {
        max(min(qtyAvailableToDiscount - qtyFree, qtyUnusedInBuyXGetYPromos), 0)
    }
    
    /// If an item was used to trigger a free-goods promo, but the promo wasn't actually used at all (i.e. no freebies due to the promo are actually on the order)
    var qtyAvailableForStandardPromos: Int {
        max(qtyAvailableToDiscount - qtyUsedAsTriggerThatMustBeFullPrice - qtyFree, 0)
    }
}
