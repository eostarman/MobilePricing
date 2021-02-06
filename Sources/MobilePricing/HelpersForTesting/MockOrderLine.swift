//  Created by Michael Rutherford on 1/29/21.

import Foundation
import MoneyAndExchangeRates
import MobileDownload

class MockOrderLine: IDCOrderLine {

    var freeGoods: [LineFreeGoods] = []
    var discounts: [LineDiscount] = []
    var fees: [LineFee] = []
    var taxes: [LineTax] = []
    
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
    
    var basePricesAndPromosOnQtyOrdered: Bool
    
    var qtyOrdered: Int?
    
    var qtyShipped: Int
    
    var unitPrice: MoneyWithoutCurrency?
    
    var unitSplitCaseCharge: MoneyWithoutCurrency
    
    
    var qtyFree: Int {
        freeGoods.map({ $0.qtyFree}).reduce(0, +)
    }
    
    var qtyDiscounted: Int {
        discounts.isEmpty ? 0 : qtyShipped - qtyFree
    }

    var unitDiscount: MoneyWithoutCurrency {
        discounts.map({ $0.unitDisc }).reduce(.zero, +)
    }
    
    var unitFee: MoneyWithoutCurrency {
        fees.map({ $0.unitFee }).reduce(.zero, +)
    }
    
    var unitTax: MoneyWithoutCurrency {
        taxes.map({ $0.unitTax }).reduce(.zero, +)
    }
    
    var unitNetAfterDiscount: MoneyWithoutCurrency {
        (unitPrice ?? .zero) - unitDiscount
    }
    
    func getCokePromoTotal() -> MoneyWithoutCurrency {
        discounts.filter({ $0.promoPlan.isCokePromo }).map({ $0.unitDisc }).reduce(.zero, +)
    }
    
    func clearAllPromoData() {
        freeGoods = []
        discounts = []
        fees = []
        taxes = []
    }
    
    func addFreeGoods(promoSectionNid: Int, qtyFree: Int, rebateAmount: MoneyWithoutCurrency) {
        freeGoods.append(LineFreeGoods(promoSectionNid: promoSectionNid, qtyFree: qtyFree, rebateAmount: rebateAmount))
    }
    
    func addDiscount(promoPlan: ePromoPlan, promoSectionNid: Int, unitDisc: MoneyWithoutCurrency, rebateAmount: MoneyWithoutCurrency) {
        discounts.append(LineDiscount(promoPlan: promoPlan, promoSectionNid: promoSectionNid, unitDisc: unitDisc, rebateAmount: rebateAmount))
    }
    
    func addFee(promoSectionNid: Int, unitFee: MoneyWithoutCurrency) {
        fees.append(LineFee(promoSectionNid: promoSectionNid, unitFee: unitFee))
    }
    
    func addTax(promoSectionNid: Int, unitTax: MoneyWithoutCurrency) {
        taxes.append(LineTax(promoSectionNid: promoSectionNid, unitTax: unitTax))
    }
}

extension MockOrderLine {
    
    struct LineFreeGoods {
        let promoSectionNid: Int
        let qtyFree: Int
        let rebateAmount: MoneyWithoutCurrency
    }
    
    struct LineDiscount {
        let promoPlan: ePromoPlan
        let promoSectionNid: Int
        let unitDisc: MoneyWithoutCurrency
        let rebateAmount: MoneyWithoutCurrency
    }
    
    struct LineTax {
        let promoSectionNid: Int
        let unitTax: MoneyWithoutCurrency
    }
    
    struct LineFee {
        let promoSectionNid: Int
        let unitFee: MoneyWithoutCurrency
    }
}
