//  Created by Michael Rutherford on 1/29/21.

import Foundation
import MoneyAndExchangeRates
import MobileDownload

public class MockOrderLine: DCOrderLine, SplitCaseChargeSource, Identifiable {
    public var id: UUID
    
    public var unitPrice: MoneyWithoutCurrency?
    
    public var freeGoods: [LineItemFreeGoods] = []
    public var discounts: [LineItemDiscount] = []
    public var charges: [LineItemCharge] = []
    public var credits: [LineItemCredit] = []
    public var potentialDiscounts: [PotentialDiscount] = []
    
    convenience init(_ item: ItemRecord, _ qtyOrdered: Int, _ unitPrice: MoneyWithoutCurrency = 10.00) {
        self.init(itemNid: item.recNid, qtyOrdered: qtyOrdered, unitPrice: unitPrice)
    }
    
    internal init(itemNid: Int, qtyOrdered: Int, unitPrice: MoneyWithoutCurrency) {
        self.id = UUID()
        self.seq = 0
        self.itemNid = itemNid
        self.isPreferredFreeGoodLine = false
        self.qtyOrdered = qtyOrdered
        self.qtyShipped = qtyOrdered
        self.basePricesAndPromosOnQtyOrdered = false
        self.unitPrice = unitPrice
    }
    
    public init(id: UUID, seq: Int, itemNid: Int, qtyOrdered: Int, qtyShipped: Int, basePricesAndPromosOnQtyOrdered: Bool, isPreferredFreeGoodLine: Bool) {
        self.id = id
        self.seq = seq
        self.itemNid = itemNid
        self.qtyOrdered = qtyOrdered
        self.qtyShipped = qtyShipped
        self.basePricesAndPromosOnQtyOrdered = basePricesAndPromosOnQtyOrdered
        self.isPreferredFreeGoodLine = isPreferredFreeGoodLine
    }
    
    public var seq: Int

    public let itemNid: Int
    
    public var qtyOrdered: Int
    
    public var qtyShipped: Int?

    public var basePricesAndPromosOnQtyOrdered: Bool
    
    public var isPreferredFreeGoodLine: Bool
    
    public var qtyShippedOrExpectedToBeShipped: Int {
        qtyShipped ?? qtyOrdered
    }
    
    public var qtyFree: Int {
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

    public var unitNetAfterDiscount: MoneyWithoutCurrency {
        (unitPrice ?? .zero) - unitDiscount
    }
    
    func getCokePromoTotal() -> MoneyWithoutCurrency {
        discounts.filter({ $0.promoPlan.isCokePromo }).map({ $0.unitDisc }).reduce(.zero, +)
    }
    
    public func clearAllPromoData() {
        freeGoods = []
        discounts = []
        charges = []
        credits = []
        potentialDiscounts = []
    }
    
    public func addFreeGoods(promoSectionNid: Int?, qtyFree: Int, rebateAmount: MoneyWithoutCurrency) {
        freeGoods.append(LineItemFreeGoods(promoSectionNid: promoSectionNid, qtyFree: qtyFree, rebateAmount: rebateAmount))
    }
    
    public func addDiscount(promoPlan: ePromoPlan, promoSectionNid: Int?, unitDisc: MoneyWithoutCurrency, rebateAmount: MoneyWithoutCurrency) {
        discounts.append(LineItemDiscount(promoPlan: promoPlan, promoSectionNid: promoSectionNid, unitDisc: unitDisc, rebateAmount: rebateAmount))
    }
    
    public func addCharge(_ charge: LineItemCharge) {
        charges.append(charge)
    }
    
    public func addCredit(_ credit: LineItemCredit) {
        credits.append(credit)
    }
    
    public func addPotentialDiscount(potentialDiscount: PotentialDiscount) {
        potentialDiscounts.append(potentialDiscount)
    }
}
