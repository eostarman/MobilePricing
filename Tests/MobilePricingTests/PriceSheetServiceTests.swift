//
//  PriceSheetServiceTests.swift
//  MobilePricingTests
//
//  Created by Michael Rutherford on 1/3/21.
//

import XCTest
import MobileDownload
@testable import MobilePricing
import MoneyAndExchangeRates

class PriceSheetServiceTests: XCTestCase {

    func testItemPrice() {
        mobileDownload = MobileDownload()
        let priceSheet = mobileDownload.testPriceSheet()
        priceSheet.currency = .EUR
        let beer = mobileDownload.testItem()

        XCTAssertNil(priceSheet.getPrice(beer, priceLevel: 1))

        priceSheet.setPrice(beer, priceLevel: 1, price: 1.55)
        XCTAssertEqual(Money(1.55, .EUR), priceSheet.getPrice(beer, priceLevel: 1))
    }

    func testActiveDate() {
        mobileDownload = MobileDownload()
        let priceSheet = mobileDownload.testPriceSheet()
        
        priceSheet.startDate = christmasDay
        priceSheet.endDate = dayAfterChristmas

        XCTAssertFalse(priceSheet.isActive(on: christmasEve))

        XCTAssertTrue(priceSheet.isActive(on: christmasDay))
        XCTAssertTrue(priceSheet.isActive(on: dayAfterChristmas))

        // however, if the endDate is when this price sheet was superceded by another, then the other price sheet is effective on the endDate - not this one
        priceSheet.endDateIsSupercededDate = true
        XCTAssertFalse(priceSheet.isActive(on: dayAfterChristmas))
    }

    func testQtyBasedMinimums() {
        mobileDownload = MobileDownload()
        let priceSheet = mobileDownload.testPriceSheet()

        let beer = mobileDownload.testItem()

        priceSheet.setPrice(beer, priceLevel: 1, price: 1.55)

        XCTAssertFalse(priceSheet.isFrontlinePriceLevelTriggered(beer, priceLevel: 1, triggerQuantities: [:]))

        priceSheet.setAutoColumn(priceLevel: 1, minimumCases: 10)

        XCTAssertFalse(priceSheet.isFrontlinePriceLevelTriggered(beer, priceLevel: 1, triggerQuantities: [beer.recNid:9]))

        XCTAssertTrue(priceSheet.isFrontlinePriceLevelTriggered(beer, priceLevel: 1, triggerQuantities: [beer.recNid:10]))
    }

    func testWeightBasedMinimumsMixAndMatch() {
        mobileDownload = MobileDownload()

        let beer = mobileDownload.testItem()
        beer.itemWeight = 2.0               // e.g. each 1 of these things will weigh 2lbs

        let hamburger = mobileDownload.testItem()
        hamburger.itemWeight = 0.5               // e.g. each 1 of these things will weigh 2lbs

        let priceSheet = mobileDownload.testPriceSheet()

        priceSheet.setPrice(beer, priceLevel: 1, price: 1.55)
        priceSheet.setPrice(hamburger, priceLevel: 2, price: 1.55)

        // the column doesn't exist - so that's false
        XCTAssertFalse(priceSheet.isFrontlinePriceLevelTriggered(beer, priceLevel: 1, triggerQuantities: [:]))

        // the column is not an automatic column - so that's false
        priceSheet.setNonAutoColumn(priceLevel: 1)
        XCTAssertFalse(priceSheet.isFrontlinePriceLevelTriggered(beer, priceLevel: 1, triggerQuantities: [:]))

        // the column is an automatic, but there are no trigger quantities
        priceSheet.setAutoColumn(pricelevel: 1, minimumWeight: 10)
        XCTAssertFalse(priceSheet.isFrontlinePriceLevelTriggered(beer, priceLevel: 1, triggerQuantities: [:]))

        // the column is automatic, but 4 of item 1001 is only 8lbs (or maybe kilos)
        XCTAssertFalse(priceSheet.isFrontlinePriceLevelTriggered(beer, priceLevel: 1, triggerQuantities: [beer.recNid:4]))

        // 4 of item 1001, and 3 of item 1002 is only 7.5lbs
        XCTAssertFalse(priceSheet.isFrontlinePriceLevelTriggered(beer, priceLevel: 1, triggerQuantities: [beer.recNid:4, hamburger.recNid:3]))

        // 4 of item 1001, and 4 of item 1002 is 8lbs
        XCTAssertTrue(priceSheet.isFrontlinePriceLevelTriggered(beer, priceLevel: 1, triggerQuantities: [beer.recNid:4, hamburger.recNid:3, hamburger.recNid:1]))
    }

    func testNonMixAndMatch() {
        mobileDownload = MobileDownload()
        let priceSheet = mobileDownload.testPriceSheet()
        priceSheet.perItemMinimums = true

        let beer = mobileDownload.testItem()
        let soda = mobileDownload.testItem()

        priceSheet.setPrice(beer, priceLevel: 1, price: 1.55)
        priceSheet.setPrice(soda, priceLevel: 1, price: 1.55)

        priceSheet.setAutoColumn(priceLevel: 1, minimumCases: 10)

        // you haven't bought anything yet - so, the auto-column isn't triggered
        XCTAssertFalse(priceSheet.isFrontlinePriceLevelTriggered(beer, priceLevel: 1, triggerQuantities: [:]))

        // you only bought 9, but the trigger (per-item) is that you need to buy 10
        XCTAssertFalse(priceSheet.isFrontlinePriceLevelTriggered(beer, priceLevel: 1, triggerQuantities: [beer.recNid:9]))

        // okay - you bought 10, and this meets the minimum for item #1001
        XCTAssertTrue(priceSheet.isFrontlinePriceLevelTriggered(beer, priceLevel: 1, triggerQuantities: [beer.recNid:10]))

        // you bought 10 of item #1002, so item #1001 isn't triggered
        XCTAssertFalse(priceSheet.isFrontlinePriceLevelTriggered(beer, priceLevel: 1, triggerQuantities: [soda.recNid:10]))
    }

}
