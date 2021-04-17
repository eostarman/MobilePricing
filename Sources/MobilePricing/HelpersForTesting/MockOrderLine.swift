//  Created by Michael Rutherford on 1/29/21.

import Foundation
import MoneyAndExchangeRates
import MobileDownload

class MockOrderLine: DCOrderLine {

    var freeGoods: [LineFreeGoods] = []
    var discounts: [LineDiscount] = []
    var charges: [LineItemCharge] = []
    var credits: [LineItemCredit] = []
    var potentialDiscounts: [PotentialDiscount] = []
    
    convenience init(_ item: ItemRecord, _ qtyOrdered: Int, _ unitPrice: MoneyWithoutCurrency = 10.00) {
        self.init(itemNid: item.recNid, qtyOrdered: qtyOrdered, unitPrice: unitPrice)
    }
    
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
    
    var qtyOrdered: Int
    
    var qtyShipped: Int?
    
    var qtyShippedOrExpectedToBeShipped: Int {
        qtyShipped ?? qtyOrdered
    }
    
    var unitPrice: MoneyWithoutCurrency?
    
    var unitSplitCaseCharge: MoneyWithoutCurrency
    
    var qtyFree: Int {
        freeGoods.map({ $0.qtyFree}).reduce(0, +)
    }
    
    var qtyDiscounted: Int {
        discounts.isEmpty ? 0 : qtyShippedOrExpectedToBeShipped - qtyFree
    }

    var unitDiscount: MoneyWithoutCurrency {
        discounts.map({ $0.unitDisc }).reduce(.zero, +)
    }
    
    var unitCharge: MoneyWithoutCurrency {
        charges.map({ $0.amount }).reduce(.zero, +)
    }
    
    var unitCredit: MoneyWithoutCurrency {
        credits.map({ $0.amount }).reduce(.zero, +)
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
        charges = []
        credits = []
        potentialDiscounts = []
    }
    
    func addFreeGoods(promoSectionNid: Int?, qtyFree: Int, rebateAmount: MoneyWithoutCurrency) {
        freeGoods.append(LineFreeGoods(promoSectionNid: promoSectionNid, qtyFree: qtyFree, rebateAmount: rebateAmount))
    }
    
    func addDiscount(promoPlan: ePromoPlan, promoSectionNid: Int?, unitDisc: MoneyWithoutCurrency, rebateAmount: MoneyWithoutCurrency) {
        discounts.append(LineDiscount(promoPlan: promoPlan, promoSectionNid: promoSectionNid, unitDisc: unitDisc, rebateAmount: rebateAmount))
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

extension MockOrderLine {
    
    struct LineFreeGoods {
        let promoSectionNid: Int?
        let qtyFree: Int
        let rebateAmount: MoneyWithoutCurrency
    }
    
    struct LineDiscount {
        let promoPlan: ePromoPlan
        let promoSectionNid: Int?
        let unitDisc: MoneyWithoutCurrency
        let rebateAmount: MoneyWithoutCurrency
    }
}
