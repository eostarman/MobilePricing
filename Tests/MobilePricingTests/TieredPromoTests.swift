//
//  TieredPromoTests.swift
//  MobilePricingTests
//
//  Created by Michael Rutherford on 2/5/21.
//

import XCTest
@testable import MobilePricing
import MobileDownload
import MoneyAndExchangeRates

/// Tiered promotions work like this:
/// 1. Tier (-1) refers to all promotions not assigned to any tier (this is for all US customers since support for tiers was added for CCBA) - this is computed first based on each orderLine's frontlinePrice
/// 2. Tier (0) is computed next. But, the frontlinePrice is after discounts computed from step 1
/// So, if the item is $10.00 and tier 1 provides a $2.00 discount and tier 2 provides 10% then tier 2 is computed as 10% of $10.00 - $2.00 - so, $0.80
/// If the promotions were "stackable" then each would be computed against the original price (in this case, the 10% would provide a discount of $1.00)
/// If the promotions are "standard", then we pick the one with the deepest discount (in this case keeping the $2.00 discount and ignoring the 10% discount)

class TieredPromoTests: XCTestCase {
    
    func testBasicTiersForBeer() throws {
        mobileDownload = MobileDownload()
        
        let beer = mobileDownload.testItem()
        
        let promoCode = mobileDownload.testPromoCode()
        promoCode.isTieredPromo = false
        let promoSection = mobileDownload.testPromoSection(promoCode: promoCode, PromoItem(beer, amountOff: 1.00))
        
        
        let tier1PromoCode = mobileDownload.testPromoCode()
        tier1PromoCode.isTieredPromo = true
        tier1PromoCode.promoTierSeq = 1
        let tier1PromoSection = mobileDownload.testPromoSection(promoCode: tier1PromoCode, PromoItem(beer, amountOff: 0.50))
        
        
        func beerSale(_ qtyOrdered: Int) -> MockOrderLine {
            MockOrderLine(itemNid: beer.recNid, qtyOrdered: qtyOrdered, unitPrice: 10.00)
        }
        
        if true {
            let solution = getPromoTestSolution([promoSection, tier1PromoSection], [beerSale(3)])
            
            XCTAssertEqual(solution.sale.unitDiscount, 1.50)
        }
    }
    
    func testPercentOffTier() throws {
        mobileDownload = MobileDownload()
        
        let beer = mobileDownload.testItem()
        
        let promoCode = mobileDownload.testPromoCode()
        promoCode.isTieredPromo = false
        let promoSection = mobileDownload.testPromoSection(promoCode: promoCode, PromoItem(beer, amountOff: 2.00))
        
        
        let tier1PromoCode = mobileDownload.testPromoCode()
        tier1PromoCode.isTieredPromo = true
        tier1PromoCode.promoTierSeq = 1
        let tier1PromoSection = mobileDownload.testPromoSection(promoCode: tier1PromoCode, PromoItem(beer, percentOff: 10.0))
        
        
        func beerSale(_ qtyOrdered: Int) -> MockOrderLine {
            MockOrderLine(itemNid: beer.recNid, qtyOrdered: qtyOrdered, unitPrice: 10.00)
        }
        
        if true {
            let solution = getPromoTestSolution([promoSection, tier1PromoSection], [beerSale(3)])
            
            XCTAssertEqual(solution.sale.unitDiscount, 2.80)
        }
    }
}
