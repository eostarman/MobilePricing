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
        let promo = BuyXGetYPerItemPromo(qtyX: 10, qtyY: 3)
        
        var result: BuyXGetYPerItemPromo.Result
        
        result = promo.compute(qtySold: 13)
        XCTAssertEqual(result.qtyAtFullPrice, 10)
        XCTAssertEqual(result.qtyFree, 3)
        XCTAssertEqual(result.unusedFreebies, 0)
        XCTAssertEqual(result.qtyToAddToEarnMoreFreebies, 0)
        
        result = promo.compute(qtySold: 10)
        XCTAssertEqual(result.qtyAtFullPrice, 10)
        XCTAssertEqual(result.qtyFree, 3)
        XCTAssertEqual(result.unusedFreebies, 3)
        XCTAssertEqual(result.qtyToAddToEarnMoreFreebies, 0)
        
        result = promo.compute(qtySold: 7)
        XCTAssertEqual(result.qtyAtFullPrice, 7)
        XCTAssertEqual(result.qtyFree, 0)
        XCTAssertEqual(result.unusedFreebies, 0)
        XCTAssertEqual(result.qtyToAddToEarnMoreFreebies, 3)
        
        result = promo.compute(qtySold: 11)
        XCTAssertEqual(result.qtyAtFullPrice, 10)
        XCTAssertEqual(result.qtyFree, 3)
        XCTAssertEqual(result.unusedFreebies, 2)
        XCTAssertEqual(result.qtyToAddToEarnMoreFreebies, 0)
        
        
        result = promo.compute(qtySold: 22)
        XCTAssertEqual(result.qtyAtFullPrice, 19)
        XCTAssertEqual(result.qtyFree, 3)
        XCTAssertEqual(result.unusedFreebies, 0)
        XCTAssertEqual(result.qtyToAddToEarnMoreFreebies, 1)
        
        result = promo.compute(qtySold: 25)
        XCTAssertEqual(result.qtyAtFullPrice, 20)
        XCTAssertEqual(result.qtyFree, 6)
        XCTAssertEqual(result.unusedFreebies, 1)
        XCTAssertEqual(result.qtyToAddToEarnMoreFreebies, 0)
        
        result = promo.compute(qtySold: 26)
        XCTAssertEqual(result.qtyAtFullPrice, 20)
        XCTAssertEqual(result.qtyFree, 6)
        XCTAssertEqual(result.unusedFreebies, 0)
        XCTAssertEqual(result.qtyToAddToEarnMoreFreebies, 0)
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
                
        let buyXGetYPromo = promoSection.getBuyXGetYPerItemPromo()
        
        XCTAssertEqual(buyXGetYPromo?.qtyX, 10)
        XCTAssertEqual(buyXGetYPromo?.qtyY, 1)
    }
}
