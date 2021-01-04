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

    func testPriceSheetRecordItemPrice() {
        mobileDownload = MobileDownload()
        let priceSheet = testPriceSheet(priceSheetNid: 11)
        priceSheet.currency = .EUR
//        let item = testItem(itemNid: 1001)
//        let customer = testCustomer(cusNid: 505)

        XCTAssertNil(priceSheet.getPrice(itemNid: 1001, priceLevel: 1))

        priceSheet.setPrice(itemNid: 1001, priceLevel: 1, price: 1.55)
        XCTAssertEqual(Money(1.55, .EUR), priceSheet.getPrice(itemNid: 1001, priceLevel: 1))
    }


    func testPriceSheetRecordActiveDate() {
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

}
