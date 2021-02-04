//
//  MixAndMatchPromoTests.swift
//  MobilePricingTests
//
//  Created by Michael Rutherford on 1/7/21.
//

import XCTest
import MobileDownload
@testable import MobilePricing
import MoneyAndExchangeRates

class BuyXGetYPerItemPromoTests: XCTestCase {
    
    func testBasicCalculation() {
        mobileDownload = MobileDownload()
        let promoSection = mobileDownload.testPromoSection()
        let promo = BuyXGetYPerItemPromoSection(promoSectionRecord: promoSection, itemNids: [], qtyX: 10, qtyY: 3)
        
        var solution: BuyXGetYPerItemPromoSection.Solution
        
        solution = promo.compute(qtySold: 13)
        XCTAssertEqual(solution.qtyAtFullPrice, 10)
        XCTAssertEqual(solution.qtyFree, 3)
        XCTAssertEqual(solution.unusedFreebies, 0)
        XCTAssertEqual(solution.qtyToAddToEarnMoreFreebies, 0)
        
        solution = promo.compute(qtySold: 10)
        XCTAssertEqual(solution.qtyAtFullPrice, 10)
        XCTAssertEqual(solution.qtyFree, 3)
        XCTAssertEqual(solution.unusedFreebies, 3)
        XCTAssertEqual(solution.qtyToAddToEarnMoreFreebies, 0)
        
        solution = promo.compute(qtySold: 7)
        XCTAssertEqual(solution.qtyAtFullPrice, 7)
        XCTAssertEqual(solution.qtyFree, 0)
        XCTAssertEqual(solution.unusedFreebies, 0)
        XCTAssertEqual(solution.qtyToAddToEarnMoreFreebies, 3)
        
        solution = promo.compute(qtySold: 11)
        XCTAssertEqual(solution.qtyAtFullPrice, 10)
        XCTAssertEqual(solution.qtyFree, 3)
        XCTAssertEqual(solution.unusedFreebies, 2)
        XCTAssertEqual(solution.qtyToAddToEarnMoreFreebies, 0)
        
        
        solution = promo.compute(qtySold: 22)
        XCTAssertEqual(solution.qtyAtFullPrice, 19)
        XCTAssertEqual(solution.qtyFree, 3)
        XCTAssertEqual(solution.unusedFreebies, 0)
        XCTAssertEqual(solution.qtyToAddToEarnMoreFreebies, 1)
        
        solution = promo.compute(qtySold: 25)
        XCTAssertEqual(solution.qtyAtFullPrice, 20)
        XCTAssertEqual(solution.qtyFree, 6)
        XCTAssertEqual(solution.unusedFreebies, 1)
        XCTAssertEqual(solution.qtyToAddToEarnMoreFreebies, 0)
        
        solution = promo.compute(qtySold: 26)
        XCTAssertEqual(solution.qtyAtFullPrice, 20)
        XCTAssertEqual(solution.qtyFree, 6)
        XCTAssertEqual(solution.unusedFreebies, 0)
        XCTAssertEqual(solution.qtyToAddToEarnMoreFreebies, 0)
    }

    func testBuyXGetYPerItemPromo() throws {
        mobileDownload = MobileDownload()
        
        let beer = mobileDownload.testItem()

        let promoSection = mobileDownload.testPromoSection()
        
        promoSection.isBuyXGetY = true
        promoSection.isMixAndMatch = false
        promoSection.qtyX = 10
        promoSection.qtyY = 1
        
        promoSection.setPromoItems([ PromoItem(beer, percentOff: 100) ])
        
        let buyXGetYPromo = promoSection.getBuyXGetYPerItemPromo(promoDate: christmasDay)
        
        XCTAssertEqual(buyXGetYPromo?.qtyX, 10)
        XCTAssertEqual(buyXGetYPromo?.qtyY, 1)
    }
}
