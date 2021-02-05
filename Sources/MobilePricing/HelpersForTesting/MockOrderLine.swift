//  Created by Michael Rutherford on 1/29/21.

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
    
    var qtyOrdered: Int?
    
    var qtyShipped: Int?
    
    var basePricesAndPromosOnQtyOrdered: Bool
    
    var unitPrice: MoneyWithoutCurrency?
    
    var unitSplitCaseCharge: MoneyWithoutCurrency
    
    var unitFeeTotal: MoneyWithoutCurrency {
        fees.map({ $0.unitDisc }).reduce(.zero, +)
    }
    
    var unitDiscount: MoneyWithoutCurrency {
        discounts.map({ $0.unitDisc }).reduce(.zero, +)
    }
    
    var qtyFree: Int {
        freeGoods.map({ $0.qtyFree}).reduce(0, +)
    }
    
    var unitNetAfterDiscount: MoneyWithoutCurrency {
        (unitPrice ?? .zero) - unitDiscount + unitSplitCaseCharge
    }
    
    func getCokePromoTotal() -> MoneyWithoutCurrency {
        discounts.filter({ $0.promoPlan.isCokePromo }).map({ $0.unitDisc }).reduce(.zero, +)
    }
    
    func clearAllPromoData() {
        freeGoods = []
        discounts = []
    }
    
    func addFreeGoods(promoSectionNid: Int, qtyFree: Int) {
        freeGoods.append(LineFreeGoods(promoSectionNid: promoSectionNid, qtyFree: qtyFree))
    }
    
    func addDiscountOrFee(promoPlan: ePromoPlan, promoSectionNid: Int, unitDisc: MoneyWithoutCurrency, rebateAmount: MoneyWithoutCurrency) {
        let x = LinePromoOrFee(promoPlan: promoPlan, promoSectionNid: promoSectionNid, unitDisc: unitDisc, rebateAmount: rebateAmount)
        if x.promoPlan == .AdditionalFee {
            fees.append(x)
        } else {
            discounts.append(x)
        }
    }
}

extension MockOrderLine {
    
    struct LineFreeGoods {
        let promoSectionNid: Int
        let qtyFree: Int
    }
    
    struct LinePromoOrFee {
        let promoPlan: ePromoPlan
        let promoSectionNid: Int
        let unitDisc: MoneyWithoutCurrency
        let rebateAmount: MoneyWithoutCurrency
    }
}
