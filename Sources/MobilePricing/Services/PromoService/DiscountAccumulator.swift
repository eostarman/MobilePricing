//
//  File.swift
//  
//
//  Created by Michael Rutherford on 5/23/21.
//

import Foundation
import MobileDownload
import MoneyAndExchangeRates

/// Used when computing standard promotion discounts (not the buy-x-get-y-free promotions - for those, there's the FreebieAccumulator)
class DiscountAccumulator {
    let dcOrderLine: DCOrderLine
    let itemNid: Int
    
    let qtyForTriggers: Int
    let qtyToDiscount: Int
    
    var frontlinePrice: MoneyWithoutCurrency {
        dcOrderLine.unitNetAfterDiscount
    }
    
    // for DCOrderLine
    let id: UUID
    let isPreferredFreeGoodLine: Bool
    let basePricesAndPromosOnQtyOrdered: Bool
    let qtyOrdered: Int
    let qtyShippedOrExpectedToBeShipped: Int
    let unitPrice: MoneyWithoutCurrency?
    let unitNetAfterDiscount: MoneyWithoutCurrency
    var seq: Int

    init(dcOrderLine: DCOrderLine, useQtyOrderedForPricingAndPromos: Bool)
    {
        self.dcOrderLine = dcOrderLine
        
        self.itemNid = dcOrderLine.itemNid
        
        self.qtyForTriggers = useQtyOrderedForPricingAndPromos || dcOrderLine.basePricesAndPromosOnQtyOrdered
            ? max(dcOrderLine.qtyOrdered, dcOrderLine.qtyShippedOrExpectedToBeShipped)
            : dcOrderLine.qtyShippedOrExpectedToBeShipped
        
        qtyToDiscount = dcOrderLine.qtyShippedOrExpectedToBeShipped
        
        seq = dcOrderLine.seq
        
        id = dcOrderLine.id
        isPreferredFreeGoodLine = dcOrderLine.isPreferredFreeGoodLine
        basePricesAndPromosOnQtyOrdered = dcOrderLine.basePricesAndPromosOnQtyOrdered
        qtyOrdered = dcOrderLine.qtyOrdered
        qtyShippedOrExpectedToBeShipped = dcOrderLine.qtyShippedOrExpectedToBeShipped
        unitPrice = dcOrderLine.unitPrice
        unitNetAfterDiscount = dcOrderLine.unitNetAfterDiscount
    }
    
    //MARK DCOrderLine

    var freeGoods: [LineItemFreeGoods] = []
    var discounts: [LineItemDiscount] = []
    var charges: [LineItemCharge] = []
    var credits: [LineItemCredit] = []
    var potentialDiscounts: [PotentialDiscount] = []
    
    func clearAllPromoData() {
        freeGoods = []
        discounts = []
        charges = []
        credits = []
        potentialDiscounts = []
    }
    
    func addFreeGoods(promoSectionNid: Int?, qtyFree: Int, rebateAmount: MoneyWithoutCurrency) {
        freeGoods.append(LineItemFreeGoods(promoSectionNid: promoSectionNid, qtyFree: qtyFree, rebateAmount: rebateAmount))
    }
    
    func addDiscount(promoPlan: ePromoPlan, promoSectionNid: Int?, unitDisc: MoneyWithoutCurrency, rebateAmount: MoneyWithoutCurrency) {
        discounts.append(LineItemDiscount(promoPlan: promoPlan, promoSectionNid: promoSectionNid, unitDisc: unitDisc, rebateAmount: rebateAmount))
    }
    
    func addCharge(_ charge: LineItemCharge) {
        charges.append(charge)
    }
    
    func addCredit(_ credit: LineItemCredit) {
        credits.append(credit)
    }
    
    public func addPotentialDiscount(potentialDiscount: PotentialDiscount) {
        potentialDiscounts.append(potentialDiscount)
    }
}
