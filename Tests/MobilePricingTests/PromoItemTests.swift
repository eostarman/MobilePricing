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
        XCTAssertEqual(amountOff.getAmountOff(), 1.74)
        
        let percentOff = PromoItem(beer, percentOff: 30)
        XCTAssertEqual(percentOff.getPercentOff(), 30)
        
        let promoPrice = PromoItem(beer, promotedPrice: 2.33)
        XCTAssertEqual(promoPrice.getPromoPrice(), 2.33)
    }
    
    func testAmountOffPromotion() {
        mobileDownload = MobileDownload()
        let beer = mobileDownload.testItem()
        
        let amountOff = PromoItem(beer, amountOff: 1.74)
        let amountOffSavings = amountOff.getUnitDisc(promoCurrency: .EUR, transactionCurrency: .EUR, frontlinePrice: 10.00, nbrPriceDecimals: 2)
        XCTAssertEqual(amountOffSavings, 1.74)
    }
    
    func testPercentoffPromotion() {
        mobileDownload = MobileDownload()
        let beer = mobileDownload.testItem()
        
        let percentOff = PromoItem(beer, percentOff: 30)
        let percentOffSavings = percentOff.getUnitDisc(promoCurrency: .EUR, transactionCurrency: .EUR, frontlinePrice: 10.00, nbrPriceDecimals: 2)
        XCTAssertEqual(percentOffSavings, 3.00)
    }
    
    func testPromoPricePromotion() {
        mobileDownload = MobileDownload()
        let beer = mobileDownload.testItem()
        
        let promoPrice = PromoItem(beer, promotedPrice: 2.33)
        let promoPriceSavings = promoPrice.getUnitDisc(promoCurrency: .EUR, transactionCurrency: .EUR, frontlinePrice: 10.00, nbrPriceDecimals: 2)
        XCTAssertEqual(promoPriceSavings, 7.67)
    }
}
