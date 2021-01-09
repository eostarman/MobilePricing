//
//  PriceSheetServicePricingTests.swift
//  MobilePricingTests
//
//  Created by Michael Rutherford on 1/5/21.
//

import XCTest
import MobileDownload
@testable import MobilePricing
import MoneyAndExchangeRates

class PriceSheetServicePricingTests: XCTestCase {

    func testNonAutoColumns() {
        mobileDownload = MobileDownload()

        let holland = mobileDownload.testWarehouse()

        let mike = mobileDownload.testCustomer()

        let beer = mobileDownload.testItem()

        // set up the beer price sheet
        let priceSheet = mobileDownload.testPriceSheet()

        priceSheet.startDate = christmasDay
        priceSheet.endDate = christmasDay

        // price level #1 has a price for beer
        priceSheet.setNonAutoColumn(priceLevel: 1)
        priceSheet.setAutoColumn(priceLevel: 2, minimumCases: 10)

        priceSheet.setPrice(beer, priceLevel: 1, price: 1.57)
        priceSheet.setPrice(beer, priceLevel: 2, price: 1.44)

        XCTAssertEqual(priceSheet.getPrice(beer, priceLevel: 1), Money(1.57, .USD))
        XCTAssertEqual(priceSheet.getPrice(beer, priceLevel: 2), Money(1.44, .USD))


        // mike can buy beer from price sheet column (level) #1. Use this "contract" price even if there's a better one available
        if true {
            priceSheet.assignTo(mike, priceLevel: 1, canUseAutomaticColumns: false)

            // okay - let's fire up a service to provide pricing from the mobileDownload
            let pricer = PriceSheetService(holland, mike, christmasDay)

            let price = pricer.getPrice(beer, triggerQuantities: [:], transactionCurrency: .USD)
            let priceAt100 = pricer.getPrice(beer, triggerQuantities: [beer.recNid:100], transactionCurrency: .USD)

            XCTAssertEqual(price?.priceLevel, 1)
            XCTAssertEqual(price?.price, Money(1.57, .USD))
            XCTAssertEqual(priceAt100?.priceLevel, 1)
            XCTAssertEqual(priceAt100?.price, Money(1.57, .USD))
        }

        // when mike buys beer, use the price from price sheet column (level) #2.
        if true {
            priceSheet.assignTo(mike, priceLevel: 2, canUseAutomaticColumns: false)

            // okay - let's fire up a service to provide pricing from the mobileDownload
            let pricer = PriceSheetService(holland, mike, christmasDay)

            let price = pricer.getPrice(beer, triggerQuantities: [:], transactionCurrency: .USD)

            XCTAssertEqual(price?.priceLevel, 2)
            XCTAssertEqual(price?.price, Money(1.44, .USD))
        }
    }

    func testAutoColumns() {
        mobileDownload = MobileDownload()

        let holland = mobileDownload.testWarehouse()
        let mike = mobileDownload.testCustomer()
        let beer = mobileDownload.testItem()
        let priceSheet = mobileDownload.testPriceSheet()

        // set up the beer price sheet
        if true {
            priceSheet.startDate = christmasDay
            priceSheet.endDate = christmasDay

            priceSheet.setNonAutoColumn(priceLevel: 1)
            priceSheet.setAutoColumn(priceLevel: 2, minimumCases: 10)
            priceSheet.setAutoColumn(priceLevel: 3, minimumCases: 50)

            priceSheet.setPrice(beer, priceLevel: 1, price: 1.57)
            priceSheet.setPrice(beer, priceLevel: 2, price: 1.44)
            priceSheet.setPrice(beer, priceLevel: 3, price: 1.2)
        }

        // automatic columns (price at 1 case, 10 cases and 50 cases)
        // mike can buy beer from price sheet column (level) #1, but if the order is big enough, he can get it cheaper
        if true {
            priceSheet.assignTo(mike, priceLevel: 1, canUseAutomaticColumns: true)

            // okay - let's fire up a service to provide pricing from the mobileDownload
            let pricer = PriceSheetService(holland, mike, christmasDay)

            let priceAt1 = pricer.getPrice(beer, triggerQuantities: [beer.recNid:9], transactionCurrency: .USD)
            let priceAt10 = pricer.getPrice(beer, triggerQuantities: [beer.recNid:10], transactionCurrency: .USD)
            let priceAt50 = pricer.getPrice(beer, triggerQuantities: [beer.recNid:50], transactionCurrency: .USD)

            XCTAssertEqual(priceAt1?.priceLevel, 1)
            XCTAssertEqual(priceAt10?.priceLevel, 2)
            XCTAssertEqual(priceAt50?.priceLevel, 3)

            XCTAssertEqual(priceAt1?.price, Money(1.57, .USD))
            XCTAssertEqual(priceAt10?.price, Money(1.44, .USD))
            XCTAssertEqual(priceAt50?.price, Money(1.20, .USD))
        }
    }

    func makeSingleItemPriceSheet() {

    }

    func testAssignmentByPriceRule() {
        mobileDownload = MobileDownload()

        let holland = mobileDownload.testWarehouse()
        let mike = mobileDownload.testCustomer()
        let beer = mobileDownload.testItem()
        let specialPriceSheet = mobileDownload.testPriceSheet()
        let hollandPriceSheet = mobileDownload.testPriceSheet()

        // the price of beer bought from the Holland warehouse is 1.55; however, mike is on a special (higher) price of 1.83 because he has a nifty beer cooler
        if true {
            specialPriceSheet.assignTo(mike, priceLevel: 1, canUseAutomaticColumns: false)
            specialPriceSheet.setNonAutoColumn(priceLevel: 1)
            specialPriceSheet.setPrice(beer, priceLevel: 1, price: 1.83)
        }

        // set up the rule-assigned price sheet
        if true {
            specialPriceSheet.setNonAutoColumn(priceLevel: 1)
            specialPriceSheet.setPrice(beer, priceLevel: 1, price: 1.33)
        }

        // set up Holland's price sheet
        if true {
            hollandPriceSheet.assignTo(holland, priceLevel: 1, canUseAutomaticColumns: false)
            hollandPriceSheet.setNonAutoColumn(priceLevel: 1)
            hollandPriceSheet.setPrice(beer, priceLevel: 1, price: 1.55)
        }
    }

    func testPrecedenceCustomerVsWarehouse() {
        mobileDownload = MobileDownload()

        let holland = mobileDownload.testWarehouse()
        let mike = mobileDownload.testCustomer()
        let beer = mobileDownload.testItem()

        let mikesPriceSheet = mobileDownload.testPriceSheet()
        let specialPriceSheet = mobileDownload.testPriceSheet()
        let hollandPriceSheet = mobileDownload.testPriceSheet()

        // the price of beer bought from the Holland warehouse is 1.55; however, mike is on a special (higher) price of 1.83 because he has a nifty beer cooler
        if true {
            mikesPriceSheet.assignTo(mike, priceLevel: 1, canUseAutomaticColumns: false)
            mikesPriceSheet.setNonAutoColumn(priceLevel: 1)
            mikesPriceSheet.setPrice(beer, priceLevel: 1, price: 1.83)
        }

        // set up the rule-assigned price sheet
        if true {
            specialPriceSheet.setNonAutoColumn(priceLevel: 1)
            specialPriceSheet.setPrice(beer, priceLevel: 1, price: 1.33)
        }

        // set up Holland's price sheet
        if true {
            hollandPriceSheet.assignTo(holland, priceLevel: 1, canUseAutomaticColumns: false)
            hollandPriceSheet.setNonAutoColumn(priceLevel: 1)
            hollandPriceSheet.setPrice(beer, priceLevel: 1, price: 1.55)
        }

        // mike's price sheet is to be used here
        if true {
            let pricer = PriceSheetService(holland, mike, christmasDay)

            let price = pricer.getPrice(beer, triggerQuantities: [:], transactionCurrency: .USD)

            XCTAssertEqual(price?.priceSheetNid, mikesPriceSheet.recNid)
            XCTAssertEqual(price?.price, Money(1.83, .USD))
        }

        // mike doesn't have an assigned price book (list) so the warehouse' one is used instead
        if true {
            mikesPriceSheet.unassignFrom(mike)

            let pricer = PriceSheetService(holland, mike, christmasDay)

            let price = pricer.getPrice(beer, triggerQuantities: [:], transactionCurrency: .USD)

            XCTAssertEqual(price?.priceSheetNid, hollandPriceSheet.recNid)
            XCTAssertEqual(price?.price, Money(1.55, .USD))
        }

        // holland doesn't have an assigned price book now either so no price is found
        if true {
            hollandPriceSheet.unassignFrom(holland)

            let pricer = PriceSheetService(holland, mike, christmasDay)

            let price = pricer.getPrice(beer, triggerQuantities: [:], transactionCurrency: .USD)

            XCTAssertNil(price)
        }
    }
}
