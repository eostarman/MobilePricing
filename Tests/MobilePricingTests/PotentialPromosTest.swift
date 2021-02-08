//
//  PotentialPromosTest.swift
//  MobilePricingTests
//
//  Created by Michael Rutherford on 2/8/21.
//

import XCTest
@testable import MobilePricing
import MobileDownload

class PotentialPromosTest: XCTestCase {

    func testTriggeredAmountOffPromo() throws {
        mobileDownload = MobileDownload()
        let mike = mobileDownload.testCustomer()
        
        let beer = mobileDownload.testItem()
        
        let promoSection1 = mobileDownload.testPromoSection(customer: mike, PromoItem(beer, amountOff: 1.55))
        promoSection1.caseMinimum = 1

        let promoSection10 = mobileDownload.testPromoSection(customer: mike, PromoItem(beer, amountOff: 1.74))
        promoSection10.caseMinimum = 10
        
        let promoSection100 = mobileDownload.testPromoSection(customer: mike, PromoItem(beer, amountOff: 1.99))
        promoSection100.caseMinimum = 100
        
        let promoService = PromoService(mike, christmasDay)
        
        let beerSale = MockOrderLine(itemNid: beer.recNid, qtyOrdered: 1, unitPrice: 10.00)
        
        // the discount is triggered at 10 cases - so buying 1 case of beer isn't enough for the discount
        promoService.computeDiscounts(beerSale)
        XCTAssertEqual(beerSale.unitDiscount, 1.55)
        
        let potentialDiscounts = beerSale.potentialDiscounts.map({ $0.unitDisc }).sorted { $0.decimalValue < $1.decimalValue }
        
        XCTAssertEqual(potentialDiscounts.count, 2)
        XCTAssertEqual(potentialDiscounts[0], 1.74)
        XCTAssertEqual(potentialDiscounts[1], 1.99)
    }
}
