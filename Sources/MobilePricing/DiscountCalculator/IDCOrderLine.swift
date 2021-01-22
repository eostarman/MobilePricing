//
//  File.swift
//  
//
//  Created by Michael Rutherford on 1/22/21.
//

import Foundation
import MoneyAndExchangeRates
import MobileDownload

/// In c# this is an interface to the orderLine data needed in the DiscountCalculator
protocol IDCOrderLine {
    var itemNid: Int { get }
    var seq: Int { get }
    var IsPreferredFreeGoodLine: Bool { get }
    var qtyOrdered: Int { get }
    var qtyShipped: Int { get }
    var basePricesAndPromosOnQtyOrdered: Bool { get }
    var unitPrice: Money { get }
    var totalOfAllUnitDiscounts: Money { get }
    var unitSplitCaseCharge: Money { get }
    
    func getCokePromoTotal() -> Money
    
    func clearAllPromoData()
    func setPromoPlanData(promoPlan: ePromoPlan, unitDisc: Money, promoSectionNid: Int)
    func setPromoData(promoSectionNid: Int, qtyDiscounted: Int, unitDisc: Money, rebateAmount: Money)
}
