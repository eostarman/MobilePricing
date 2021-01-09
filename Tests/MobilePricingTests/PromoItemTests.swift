//
//  PromoItemTests.swift
//  MobilePricingTests
//
//  Created by Michael Rutherford on 1/7/21.
//

import XCTest
import MobileDownload
@testable import MobilePricing
import MoneyAndExchangeRates

class PromoItemTests: XCTestCase {

    func testBasicPromoItems() throws {
        mobileDownload = MobileDownload()
        
        let beer = mobileDownload.testItem()
        
        let amountOff = PromoItem(beer, amountOff: 1.74)
        XCTAssertEqual(amountOff.getAmountOff(currency: .USD), Money(1.74, .USD))
        
        let percentOff = PromoItem(beer, percentOff: 30)
        XCTAssertEqual(percentOff.getPercentOff(), 30)
        
        let promoPrice = PromoItem(beer, promotedPrice: 2.33)
        XCTAssertEqual(promoPrice.getPromoPrice(currency: .ZAR), Money(2.33, .ZAR))
    }
    
    func testAmountOffPromotion() {
        mobileDownload = MobileDownload()
        let beer = mobileDownload.testItem()
        
        let amountOff = PromoItem(beer, amountOff: 1.74)
        let amountOffSavings = amountOff.getUnitDisc(promoCurrency: .EUR, unitPrice: Money(10.00, .EUR), nbrPriceDecimals: 2, unitSplitCaseCharge: nil)
        XCTAssertEqual(amountOffSavings, Money(1.74, .EUR))
    }
    
    func testPercentoffPromotion() {
        mobileDownload = MobileDownload()
        let beer = mobileDownload.testItem()
        
        let percentOff = PromoItem(beer, percentOff: 30)
        let percentOffSavings = percentOff.getUnitDisc(promoCurrency: .EUR, unitPrice: Money(10.00, .EUR), nbrPriceDecimals: 2, unitSplitCaseCharge: nil)
        XCTAssertEqual(percentOffSavings, Money(3.00, .EUR))
    }
    
    func testPromoPricePromotion() {
        mobileDownload = MobileDownload()
        let beer = mobileDownload.testItem()
        
        let promoPrice = PromoItem(beer, promotedPrice: 2.33)
        let promoPriceSavings = promoPrice.getUnitDisc(promoCurrency: .EUR, unitPrice: Money(10.00, .EUR), nbrPriceDecimals: 2, unitSplitCaseCharge: nil)
        XCTAssertEqual(promoPriceSavings, Money(7.67, .EUR))
    }
}
