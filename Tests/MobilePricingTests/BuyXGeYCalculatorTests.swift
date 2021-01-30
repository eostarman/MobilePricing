//
//  BuyXGeYCalculatorTests.swift
//  MobilePricingTests
//
//  Created by Michael Rutherford on 1/29/21.
//

import XCTest
@testable import MobilePricing
import MobileDownload
import MoneyAndExchangeRates

class BuyXGeYCalculatorTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        mobileDownload = MobileDownload()
        
        let promoSection = mobileDownload.testPromoSection()
        promoSection.isBuyXGetY = true
        promoSection.isMixAndMatch = false
        promoSection.qtyX = 10
        promoSection.qtyY = 1
        
        
        let beer = mobileDownload.testItem()
        let priceOfBeer: MoneyWithoutCurrency = 10.00
        
        let orderLine = MockOrderLine(itemNid: beer.recNid, seq: 0, isPreferredFreeGoodLine: false, qtyOrdered: 10, qtyShipped: 10, basePricesAndPromosOnQtyOrdered: true, unitPrice: priceOfBeer, unitSplitCaseCharge: .zero)
        
        let lines = [orderLine].map({ FreebieAccumulator(dcOrderLine: $0, useQtyOrderedForPricingAndPromos: false, mayUseQtyOrderedForBuyXGetY: false)})
        
        let triggersAndTargets = FreebieTriggersAndTargets(lines: lines)
        
        let bundles = BuyXGetYCalculator.getFreebieBundles(promoSection: promoSection, triggers: triggersAndTargets.triggers, targets: triggersAndTargets.targets)
        
        

    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
