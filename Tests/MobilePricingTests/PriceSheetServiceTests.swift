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
        let priceSheet = testPriceSheet(priceSheetNid: 11)
        priceSheet.currency = .EUR
        //        let item = testItem(itemNid: 1001)
        //        let customer = testCustomer(cusNid: 505)

        XCTAssertNil(priceSheet.getPrice(itemNid: 1001, priceLevel: 1))

        priceSheet.setPrice(itemNid: 1001, priceLevel: 1, price: 1.55)
        XCTAssertEqual(Money(1.55, .EUR), priceSheet.getPrice(itemNid: 1001, priceLevel: 1))
    }

    func testActiveDate() {
        mobileDownload = MobileDownload()
        let priceSheet = testPriceSheet(priceSheetNid: 11)
        
        priceSheet.startDate = christmasDay
        priceSheet.endDate = dayAfterChristmas

        XCTAssertFalse(priceSheet.isActive(on: christmasEve))

        XCTAssertTrue(priceSheet.isActive(on: christmasDay))
        XCTAssertTrue(priceSheet.isActive(on: dayAfterChristmas))

        // however, if the endDate is when this price sheet was superceded by another, then the other price sheet is effective on the endDate - not this one
        priceSheet.endDateIsSupercededDate = true
        XCTAssertFalse(priceSheet.isActive(on: dayAfterChristmas))
    }

    func testAutoColumnTriggeringBasedOnMinimumCases() {
        mobileDownload = MobileDownload()
        let priceSheet = testPriceSheet(priceSheetNid: 11)

        _ = testItem(itemNid: 1001)

        priceSheet.setPrice(itemNid: 1001, priceLevel: 1, price: 1.55)

        XCTAssertFalse(priceSheet.isFrontlinePriceLevelTriggered(triggerQuantities: [:], itemNid: 1001, priceLevel: 1))

        priceSheet.setAutoColumnBasedOnMinimumCases(priceLevel: 1, minimumCases: 10)

        XCTAssertFalse(priceSheet.isFrontlinePriceLevelTriggered(triggerQuantities: [1001:9], itemNid: 1001, priceLevel: 1))

        XCTAssertTrue(priceSheet.isFrontlinePriceLevelTriggered(triggerQuantities: [1001:10], itemNid: 1001, priceLevel: 1))
    }

    func testAutoColumnTriggeringBasedOnMinimumWeightMixAndMMatch() {
        mobileDownload = MobileDownload()

        let item1001 = testItem(itemNid: 1001)
        item1001.itemWeight = 2.0               // e.g. each 1 of these things will weigh 2lbs

        let item1002 = testItem(itemNid: 1002)
        item1002.itemWeight = 0.5               // e.g. each 1 of these things will weigh 2lbs

        let priceSheet = testPriceSheet(priceSheetNid: 11)

        priceSheet.setPrice(itemNid: 1001, priceLevel: 1, price: 1.55)
        priceSheet.setPrice(itemNid: 1002, priceLevel: 2, price: 1.55)

        // the column doesn't exist - so that's false
        XCTAssertFalse(priceSheet.isFrontlinePriceLevelTriggered(triggerQuantities: [:], itemNid: 1001, priceLevel: 1))

        // the column is not an automatic column - so that's false
        priceSheet.setNonAutoColumn(priceLevel: 1)
        XCTAssertFalse(priceSheet.isFrontlinePriceLevelTriggered(triggerQuantities: [:], itemNid: 1001, priceLevel: 1))

        // the column is an automatic, but there are no trigger quantities
        priceSheet.setAutoColumnBasedOnMinimumWeight(pricelevel: 1, minimumWeight: 10)
        XCTAssertFalse(priceSheet.isFrontlinePriceLevelTriggered(triggerQuantities: [:], itemNid: 1001, priceLevel: 1))

        // the column is automatic, but 4 of item 1001 is only 8lbs (or maybe kilos)
        XCTAssertFalse(priceSheet.isFrontlinePriceLevelTriggered(triggerQuantities: [1001:4], itemNid: 1001, priceLevel: 1))

        // 4 of item 1001, and 3 of item 1002 is only 7.5lbs
        XCTAssertFalse(priceSheet.isFrontlinePriceLevelTriggered(triggerQuantities: [1001:4, 1002:3], itemNid: 1001, priceLevel: 1))

        // 4 of item 1001, and 4 of item 1002 is 8lbs
        XCTAssertTrue(priceSheet.isFrontlinePriceLevelTriggered(triggerQuantities: [1001:4, 1002:3, 1002:1], itemNid: 1001, priceLevel: 1))
    }

    func testAutoColumnPerItemTriggeringBasedOnMinimumCases() {
        mobileDownload = MobileDownload()
        let priceSheet = testPriceSheet(priceSheetNid: 11)
        priceSheet.perItemMinimums = true

        _ = testItem(itemNid: 1001)
        _ = testItem(itemNid: 1002)

        priceSheet.setPrice(itemNid: 1001, priceLevel: 1, price: 1.55)
        priceSheet.setPrice(itemNid: 1002, priceLevel: 1, price: 1.55)

        priceSheet.setAutoColumnBasedOnMinimumCases(priceLevel: 1, minimumCases: 10)

        // you haven't bought anything yet - so, the auto-column isn't triggered
        XCTAssertFalse(priceSheet.isFrontlinePriceLevelTriggered(triggerQuantities: [:], itemNid: 1001, priceLevel: 1))

        // you only bought 9, but the trigger (per-item) is that you need to buy 10
        XCTAssertFalse(priceSheet.isFrontlinePriceLevelTriggered(triggerQuantities: [1001:9], itemNid: 1001, priceLevel: 1))

        // okay - you bought 10, and this meets the minimum for item #1001
        XCTAssertTrue(priceSheet.isFrontlinePriceLevelTriggered(triggerQuantities: [1001:10], itemNid: 1001, priceLevel: 1))

        // you bought 10 of item #1002, so item #1001 isn't triggered
        XCTAssertFalse(priceSheet.isFrontlinePriceLevelTriggered(triggerQuantities: [1002:10], itemNid: 1001, priceLevel: 1))
    }

    func testPriceSheetService() {
        mobileDownload = MobileDownload()

        _ = testWarehouse(whseNid: 1)
        _ = testCustomer(cusNid: 100)

        let service = PriceSheetService(shipFromWhseNid: 1, cusNid: 100, date: christmasDay)

    }
}
