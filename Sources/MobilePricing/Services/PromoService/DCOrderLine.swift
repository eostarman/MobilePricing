//  Created by Michael Rutherford on 1/22/21.

import Foundation
import MoneyAndExchangeRates
import MobileDownload

// note: I use MoneyWithoutCurrency rather than the more natural-seeming Money. Why? Because the currency used on an order (e.g. USD or EUR) is the same for all
// amounts on the order. If I used Money, then I'd need to keep checking to make sure when I add two amounts that the currencies were the same.

/// In c# this is an interface to the orderLine data needed in the DiscountCalculator
public protocol DCOrderLine: AnyObject {
    var itemNid: Int { get }
    var isPreferredFreeGoodLine: Bool { get }
    var basePricesAndPromosOnQtyOrdered: Bool { get }
    
    var qtyOrdered: Int { get }
    var qtyShipped: Int { get }
    var unitPrice: MoneyWithoutCurrency? { get }
    
    var unitDiscount: MoneyWithoutCurrency { get }
    var unitFee: MoneyWithoutCurrency { get }
    var unitTax: MoneyWithoutCurrency { get }
    
    var unitSplitCaseCharge: MoneyWithoutCurrency { get set }
    
    /// how many of the qtyShipped will be free due to buy-x-get-y promos
    var qtyFree: Int { get }
    /// now many of the qtyShipped have a discount (zero if there is no unitDisc)
    var qtyDiscounted: Int { get }
    
    var unitNetAfterDiscount: MoneyWithoutCurrency { get }
    
    func getCokePromoTotal() -> MoneyWithoutCurrency
    
    var seq: Int { get set }
    
    // mpr: note that this is different in DiscountCalculator.cs - I found the code that assigns the default promos to the orderLine very confusing (likely buggy)
    func clearAllPromoData()
    func addFreeGoods(promoSectionNid: Int, qtyFree: Int, rebateAmount: MoneyWithoutCurrency)
    func addDiscount(promoPlan: ePromoPlan, promoSectionNid: Int, unitDisc: MoneyWithoutCurrency, rebateAmount: MoneyWithoutCurrency)
    func addFee(promoSectionNid: Int, unitFee: MoneyWithoutCurrency)
    func addTax(promoSectionNid: Int, unitTax: MoneyWithoutCurrency)
    func addPotentialDiscount(potentialDiscount: PotentialDiscount)
}
