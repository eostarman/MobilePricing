//
//  File.swift
//  
//
//  Created by Michael Rutherford on 1/29/21.
//

import Foundation
import MoneyAndExchangeRates
import MobileDownload

class MockOrderLine: IDCOrderLine {
    var freeGoods: [LineFreeGoods] = []
    var discounts: [LinePromoOrFee] = []
    var fees: [LinePromoOrFee] = []
    
    internal init(itemNid: Int, qtyOrdered: Int, unitPrice: MoneyWithoutCurrency) {
        self.itemNid = itemNid
        self.seq = 0
        self.isPreferredFreeGoodLine = false
        self.qtyOrdered = qtyOrdered
        self.qtyShipped = qtyOrdered
        self.basePricesAndPromosOnQtyOrdered = false
        self.unitPrice = unitPrice
        self.unitSplitCaseCharge = .zero
    }
    
    let itemNid: Int
    
    var seq: Int
    
    var isPreferredFreeGoodLine: Bool
    
    var qtyOrdered: Int
    
    var qtyShipped: Int
    
    var basePricesAndPromosOnQtyOrdered: Bool
    
    var unitPrice: MoneyWithoutCurrency
    
    var unitFeeTotal: MoneyWithoutCurrency {
        fees.map({ $0.qtyDiscounted * $0.unitDisc }).reduce(.zero, +)
    }

    
    var unitDiscountTotal: MoneyWithoutCurrency {
        discounts.map({ $0.qtyDiscounted * $0.unitDisc }).reduce(.zero, +)
    }
    
    var unitSplitCaseCharge: MoneyWithoutCurrency
    
    var qtyNotFree: Int {
        let qtyOrderedOrShipped = basePricesAndPromosOnQtyOrdered ? qtyOrdered : qtyShipped
        return qtyOrderedOrShipped - freeGoods.map({ $0.qtyFree}).reduce(0, +)
    }
    
    var unitNetAfterDiscount: MoneyWithoutCurrency {
        unitPrice - unitDiscountTotal
    }
    
    func getCokePromoTotal() -> MoneyWithoutCurrency {
        return .zero
    }
    
    func clearAllPromoData() {
        freeGoods = []
        discounts = []
    }
    
    func addFreeGoods(promoSectionNid: Int, qtyFree: Int) {
        freeGoods.append(LineFreeGoods(promoSectionNid: promoSectionNid, qtyFree: qtyFree))
    }
    
    func addDiscountOrFee(promoPlan: ePromoPlan, promoSectionNid: Int, qtyDiscounted: Int, unitDisc: MoneyWithoutCurrency, rebateAmount: MoneyWithoutCurrency) {
        let x = LinePromoOrFee(promoPlan: promoPlan, promoSectionNid: promoSectionNid, qtyDiscounted: qtyDiscounted, unitDisc: unitDisc, rebateAmount: rebateAmount)
        if x.isFee {
            fees.append(x)
        } else {
            discounts.append(x)
        }
    }
}

struct LineFreeGoods {
    let promoSectionNid: Int
    let qtyFree: Int
}

struct LinePromoOrFee {
    let promoPlan: ePromoPlan
    let promoSectionNid: Int
    let qtyDiscounted: Int
    let unitDisc: MoneyWithoutCurrency
    let rebateAmount: MoneyWithoutCurrency
    
    var isFee: Bool {
        promoPlan == .AdditionalFee
    }
}
