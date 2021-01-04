//
//  ItemDefaultPriceServiceTests.swift
//  MobilePricingTests
//
//  Created by Michael Rutherford on 1/2/21.
//

import XCTest
import MobileDownload
@testable import MobilePricing
import MoneyAndExchangeRates

class DefaultPriceServiceTests: XCTestCase {

    override func setUpWithError() throws {
        mobileDownload = MobileDownload()
    }

    override func tearDownWithError() throws {
        mobileDownload = MobileDownload()
    }

    func testSimpleDefaultPrice() throws {
        let item = testItem(itemNid: 1001)
        item.defaultPrice = 1.50

        let price = DefaultPriceService.getDefaultPrice(itemNid: 1001, date: christmasDay)

        XCTAssertNotNil(price)
        XCTAssertEqual(price!, MoneyWithoutCurrency(1.50))
    }

    func testSimpleDefaultPriceWithPrior() throws {
        let item = testItem(itemNid: 1001)
        item.defaultPricePrior = 1.33
        item.defaultPriceEffectiveDate = christmasDay
        item.defaultPrice = 1.50

        let priceBeforeChristmasDay = DefaultPriceService.getDefaultPrice(itemNid: 1001, date: christmasEve)
        XCTAssertNotNil(priceBeforeChristmasDay)
        XCTAssertEqual(priceBeforeChristmasDay!, MoneyWithoutCurrency(1.33))

        let priceOnChristmasDay = DefaultPriceService.getDefaultPrice(itemNid: 1001, date: christmasDay)
        XCTAssertNotNil(priceOnChristmasDay)
        XCTAssertEqual(priceOnChristmasDay!, MoneyWithoutCurrency(1.50))

        let priceAfterChristmasDay = DefaultPriceService.getDefaultPrice(itemNid: 1001, date: dayAfterChristmas)
        XCTAssertNotNil(priceAfterChristmasDay)
        XCTAssertEqual(priceAfterChristmasDay!, MoneyWithoutCurrency(1.50))
    }

    func testSimpleDefaultPriceWithPriorAndFuturePrices() throws {
        let item = testItem(itemNid: 1001)
        item.defaultPricePrior = 1.33
        item.defaultPriceEffectiveDate = christmasDay
        item.defaultPrice = 1.50
        item.defaultPrice2EffectiveDate = dayAfterChristmas
        item.defaultPrice2 = 1.75

        let priceBeforeChristmasDay = DefaultPriceService.getDefaultPrice(itemNid: 1001, date: christmasEve)
        XCTAssertNotNil(priceBeforeChristmasDay)
        XCTAssertEqual(priceBeforeChristmasDay!, MoneyWithoutCurrency(1.33))

        let priceOnChristmasDay = DefaultPriceService.getDefaultPrice(itemNid: 1001, date: christmasDay)
        XCTAssertNotNil(priceOnChristmasDay)
        XCTAssertEqual(priceOnChristmasDay!, MoneyWithoutCurrency(1.50))

        let priceAfterChristmasDay = DefaultPriceService.getDefaultPrice(itemNid: 1001, date: dayAfterChristmas)
        XCTAssertNotNil(priceAfterChristmasDay)
        XCTAssertEqual(priceAfterChristmasDay!, MoneyWithoutCurrency(1.75))
    }

}
