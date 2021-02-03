//
//  AmountOffPromoTests.swift
//  MobilePricingTests
//
//  Created by Michael Rutherford on 2/2/21.
//

import XCTest
@testable import MobilePricing
import MobileDownload
import MoneyAndExchangeRates

class AmountOffPromoTests: XCTestCase {

    func testMixAndMatchAmountOff() throws {
        mobileDownload = MobileDownload()
        
        let beer = mobileDownload.testItem()
        
        let promoSection = mobileDownload.testPromoSection(PromoItem(beer, amountOff: 1.00))
        
        func beerSale(_ qtyOrdered: Int) -> MockOrderLine {
            MockOrderLine(itemNid: beer.recNid, qtyOrdered: qtyOrdered, unitPrice: 10.00)
        }
        
        if true {
            let solution = getPromoTestSolution(promoSection, beerSale(3))
            
            XCTAssertEqual(solution.sale.totalDiscount, 1.00)
        }
    }
    
    func testMixAndMatchAmountOffWithExchangeRate() throws {
        mobileDownload = MobileDownload()
        
        mobileDownload.handheld.exchangeRates = ExchangeRatesService(ExchangeRate(from: .USD, to: .EUR, date: christmasDay, rate: 2.0))
        
        let beer = mobileDownload.testItem()
        
        let promoSection = mobileDownload.testPromoSection(PromoItem(beer, amountOff: 1.00))
        
        func beerSale(_ qtyOrdered: Int) -> MockOrderLine {
            MockOrderLine(itemNid: beer.recNid, qtyOrdered: qtyOrdered, unitPrice: 10.00)
        }
        
        if true {
            let solution = getPromoTestSolution(transactionCurrency: .EUR, promoSection, beerSale(3))
            
            XCTAssertEqual(solution.sale.totalDiscount, 2.00)
        }
    }
}
