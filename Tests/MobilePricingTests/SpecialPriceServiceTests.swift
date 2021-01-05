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

        _ = testItem(itemNid: 1001)
        
        let customer = testCustomer(cusNid: 100)
        customer.transactionCurrencyNid = Currency.EUR.currencyNid

        customer.specialPrices = [
            SpecialPrice(itemNid: 1001, price: 1.75, startDate: christmasDay, endDate: nil),
            SpecialPrice(itemNid: 1001, price: 1.95, startDate: dayAfterChristmas, endDate: nil)
        ]

        if true {
            let priceBeforeChristmasDay = SpecialPriceService.getCustomerSpecialPrice(cusNid: customer.recNid, itemNid: 1001, date: christmasEve)
            XCTAssertNil(priceBeforeChristmasDay)

            let priceOnChristmasDay = SpecialPriceService.getCustomerSpecialPrice(cusNid: customer.recNid, itemNid: 1001, date: christmasDay)
            XCTAssertNotNil(priceOnChristmasDay)
            XCTAssertEqual(priceOnChristmasDay!, MoneyWithoutCurrency(1.75).withCurrency(.EUR))

            let priceAfterChristmas = SpecialPriceService.getCustomerSpecialPrice(cusNid: customer.recNid, itemNid: 1001, date: dayAfterChristmas)
            XCTAssertNotNil(priceAfterChristmas)
            XCTAssertEqual(priceAfterChristmas!, MoneyWithoutCurrency(1.95).withCurrency(.EUR))
        }

        // make sure the sequence of the data doesn't matter (the most-recent date is always used)
        if true {
            customer.specialPrices?.reverse()

            let priceBeforeChristmasDay = SpecialPriceService.getCustomerSpecialPrice(cusNid: customer.recNid, itemNid: 1001, date: christmasEve)
            XCTAssertNil(priceBeforeChristmasDay)

            let priceOnChristmasDay = SpecialPriceService.getCustomerSpecialPrice(cusNid: customer.recNid, itemNid: 1001, date: christmasDay)
            XCTAssertNotNil(priceOnChristmasDay)
            XCTAssertEqual(priceOnChristmasDay!, MoneyWithoutCurrency(1.75).withCurrency(.EUR))

            let priceAfterChristmas = SpecialPriceService.getCustomerSpecialPrice(cusNid: customer.recNid, itemNid: 1001, date: dayAfterChristmas)
            XCTAssertNotNil(priceAfterChristmas)
            XCTAssertEqual(priceAfterChristmas!, MoneyWithoutCurrency(1.95).withCurrency(.EUR))
        }
    }

}
