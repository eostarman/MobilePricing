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
        let beer = testItem()
        beer.defaultPrice = 1.50

        let price = DefaultPriceService.getDefaultPrice(beer, christmasDay)

        XCTAssertNotNil(price)
        XCTAssertEqual(price!, MoneyWithoutCurrency(1.50))
    }

    func testSimpleDefaultPriceWithPrior() throws {
        let beer = testItem()
        beer.defaultPricePrior = 1.33
        beer.defaultPriceEffectiveDate = christmasDay
        beer.defaultPrice = 1.50

        let priceBeforeChristmasDay = DefaultPriceService.getDefaultPrice(beer, christmasEve)
        XCTAssertNotNil(priceBeforeChristmasDay)
        XCTAssertEqual(priceBeforeChristmasDay!, MoneyWithoutCurrency(1.33))

        let priceOnChristmasDay = DefaultPriceService.getDefaultPrice(beer, christmasDay)
        XCTAssertNotNil(priceOnChristmasDay)
        XCTAssertEqual(priceOnChristmasDay!, MoneyWithoutCurrency(1.50))

        let priceAfterChristmasDay = DefaultPriceService.getDefaultPrice(beer, dayAfterChristmas)
        XCTAssertNotNil(priceAfterChristmasDay)
        XCTAssertEqual(priceAfterChristmasDay!, MoneyWithoutCurrency(1.50))
    }

    func testSimpleDefaultPriceWithPriorAndFuturePrices() throws {
        let beer = testItem()
        beer.defaultPricePrior = 1.33
        beer.defaultPriceEffectiveDate = christmasDay
        beer.defaultPrice = 1.50
        beer.defaultPrice2EffectiveDate = dayAfterChristmas
        beer.defaultPrice2 = 1.75

        let priceBeforeChristmasDay = DefaultPriceService.getDefaultPrice(beer, christmasEve)
        XCTAssertNotNil(priceBeforeChristmasDay)
        XCTAssertEqual(priceBeforeChristmasDay!, MoneyWithoutCurrency(1.33))

        let priceOnChristmasDay = DefaultPriceService.getDefaultPrice(beer, christmasDay)
        XCTAssertNotNil(priceOnChristmasDay)
        XCTAssertEqual(priceOnChristmasDay!, MoneyWithoutCurrency(1.50))

        let priceAfterChristmasDay = DefaultPriceService.getDefaultPrice(beer, dayAfterChristmas)
        XCTAssertNotNil(priceAfterChristmasDay)
        XCTAssertEqual(priceAfterChristmasDay!, MoneyWithoutCurrency(1.75))
    }

}
