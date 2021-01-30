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
    var isPreferredFreeGoodLine: Bool { get }
    var qtyOrdered: Int { get }
    var qtyShipped: Int { get }
    var basePricesAndPromosOnQtyOrdered: Bool { get }
    var unitPrice: MoneyWithoutCurrency { get }
    
    var unitDiscountTotal: MoneyWithoutCurrency { get }
    var unitFeeTotal: MoneyWithoutCurrency { get }
    var unitSplitCaseCharge: MoneyWithoutCurrency { get }
    
    var qtyNotFree: Int { get }
    var unitNetAfterDiscount: MoneyWithoutCurrency { get }
    
    func getCokePromoTotal() -> MoneyWithoutCurrency
    
    // mpr: note that this is different in DiscountCalculator.cs - I found the code that assigns the default promos to the orderLine very confusing (likely buggy)
    func clearAllPromoData()
    func addFreeGoods(promoSectionNid: Int, qtyFree: Int)
    func addDiscountOrFee(promoPlan: ePromoPlan, promoSectionNid: Int, qtyDiscounted: Int, unitDisc: MoneyWithoutCurrency, rebateAmount: MoneyWithoutCurrency)
}
