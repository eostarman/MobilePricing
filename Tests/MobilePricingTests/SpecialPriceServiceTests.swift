//
//  SpecialPriceServiceTests.swift
//  MobilePricingTests
//
//  Created by Michael Rutherford on 1/3/21.
//

import XCTest
import MobileDownload
@testable import MobilePricing
import MoneyAndExchangeRates

class SpecialPriceServiceTests: XCTestCase {

    func testBasicSpecialPrice() throws {

        mobileDownload = MobileDownload()

        let beer = testItem()
        
        let mike = testCustomer()
        mike.transactionCurrencyNid = Currency.EUR.currencyNid

        mike.specialPrices = [
            SpecialPrice(itemNid: beer.recNid, price: 1.75, startDate: christmasDay, endDate: nil),
            SpecialPrice(itemNid: beer.recNid, price: 1.95, startDate: dayAfterChristmas, endDate: nil)
        ]

        if true {
            let priceBeforeChristmasDay = SpecialPriceService.getCustomerSpecialPrice(mike, beer, date: christmasEve)
            XCTAssertNil(priceBeforeChristmasDay)

            let priceOnChristmasDay = SpecialPriceService.getCustomerSpecialPrice(mike, beer, date: christmasDay)
            XCTAssertNotNil(priceOnChristmasDay)
            XCTAssertEqual(priceOnChristmasDay!, MoneyWithoutCurrency(1.75).withCurrency(.EUR))

            let priceAfterChristmas = SpecialPriceService.getCustomerSpecialPrice(mike, beer, date: dayAfterChristmas)
            XCTAssertNotNil(priceAfterChristmas)
            XCTAssertEqual(priceAfterChristmas!, MoneyWithoutCurrency(1.95).withCurrency(.EUR))
        }

        // make sure the sequence of the data doesn't matter (the most-recent date is always used)
        if true {
            mike.specialPrices?.reverse()

            let priceBeforeChristmasDay = SpecialPriceService.getCustomerSpecialPrice(mike, beer, date: christmasEve)
            XCTAssertNil(priceBeforeChristmasDay)

            let priceOnChristmasDay = SpecialPriceService.getCustomerSpecialPrice(mike, beer, date: christmasDay)
            XCTAssertNotNil(priceOnChristmasDay)
            XCTAssertEqual(priceOnChristmasDay!, MoneyWithoutCurrency(1.75).withCurrency(.EUR))

            let priceAfterChristmas = SpecialPriceService.getCustomerSpecialPrice(mike, beer, date: dayAfterChristmas)
            XCTAssertNotNil(priceAfterChristmas)
            XCTAssertEqual(priceAfterChristmas!, MoneyWithoutCurrency(1.95).withCurrency(.EUR))
        }
    }

}
