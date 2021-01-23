//  Created by Michael Rutherford on 1/22/21.

import Foundation
import MoneyAndExchangeRates
import MobileDownload

// note: I use MoneyWithoutCurrency rather than the more natural-seeming Money. Why? Because the currency used on an order (e.g. USD or EUR) is the same for all
// amounts on the order. If I used Money, then I'd need to keep checking to make sure when I add two amounts that the currencies were the same.

/// In c# this is an interface to the orderLine data needed in the DiscountCalculator
protocol IDCOrderLine {
    var itemNid: Int { get }
    var seq: Int { get }
    var IsPreferredFreeGoodLine: Bool { get }
    var qtyOrdered: Int { get }
    var qtyShipped: Int { get }
    var basePricesAndPromosOnQtyOrdered: Bool { get }
    var unitPrice: MoneyWithoutCurrency { get }
    var totalOfAllUnitDiscounts: MoneyWithoutCurrency { get }
    var unitSplitCaseCharge: MoneyWithoutCurrency { get }
    
    func getCokePromoTotal() -> MoneyWithoutCurrency
    
    func clearAllPromoData()
    func setPromoPlanData(promoPlan: ePromoPlan, unitDisc: MoneyWithoutCurrency, promoSectionNid: Int)
    func setPromoData(promoSectionNid: Int, qtyDiscounted: Int, unitDisc: MoneyWithoutCurrency, rebateAmount: MoneyWithoutCurrency)
}
