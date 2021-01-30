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
    
    func getFreebieBundles(_ promoSection: PromoSectionRecord, orderLines: MockOrderLine ...) -> [FreebieBundle] {
        
        for seq in 0 ..< orderLines.count {
            orderLines[seq].seq = seq
        }
        let dcPromoSection = DCPromoSection(promoSectionRecord: promoSection, transactionCurrency: .USD)
        
        let lines = orderLines.map({ FreebieAccumulator(dcOrderLine: $0, useQtyOrderedForPricingAndPromos: false, mayUseQtyOrderedForBuyXGetY: false)})
        
        BuyXGetYCalculator.resetAccumulators(dcPromoSection, lines)
        
        let triggersAndTargets = FreebieTriggersAndTargets(lines: lines)
        
        let bundles = BuyXGetYCalculator.getFreebieBundles(promoSection: promoSection, triggers: triggersAndTargets.triggers, targets: triggersAndTargets.targets)
        
        return bundles
    }
    
    func testBuyXGetYNonMixAndMatch() throws {
        mobileDownload = MobileDownload()
        
        let promoSection = mobileDownload.testPromoSection()
        
        let beer = mobileDownload.testItem()
        
        promoSection.isBuyXGetY = true
        promoSection.isMixAndMatch = false
        promoSection.qtyX = 10
        promoSection.qtyY = 1
        
        let promoItem = PromoItem(beer, percentOff: 100)
        promoSection.setPromoItems([promoItem])
        
        func beerSale(_ qtyOrdered: Int) -> MockOrderLine {
            MockOrderLine(itemNid: beer.recNid, qtyOrdered: qtyOrdered, unitPrice: 10.00)
        }
        
        if true {
            let bundles = getFreebieBundles(promoSection, orderLines: beerSale(9))
            
            XCTAssertEqual(bundles.count, 0)
        }
        
        if true {
            let bundles = getFreebieBundles(promoSection, orderLines: beerSale(10))
            
            XCTAssertEqual(bundles.count, 1)
            XCTAssertEqual(bundles[0].qtyFree, 0)
            XCTAssertEqual(bundles[0].unusedFreeQty, 1)
        }
        
        if true {
            let bundles = getFreebieBundles(promoSection, orderLines: beerSale(11))
            
            XCTAssertEqual(bundles.count, 1)
            XCTAssertEqual(bundles[0].qtyFree, 1)
            XCTAssertEqual(bundles[0].unusedFreeQty, 0)
        }
        
        if true {
            let bundles = getFreebieBundles(promoSection, orderLines: beerSale(21))
            
            XCTAssertEqual(bundles.count, 2)
            XCTAssertEqual(bundles[0].qtyFree, 1)
            XCTAssertEqual(bundles[0].unusedFreeQty, 0)
            
            XCTAssertEqual(bundles[1].qtyFree, 0)
            XCTAssertEqual(bundles[1].unusedFreeQty, 1)
        }
        
        if true {
            let bundles = getFreebieBundles(promoSection, orderLines: beerSale(32))
            
            XCTAssertEqual(bundles.count, 3)
            XCTAssertEqual(bundles[0].qtyFree, 1)
            XCTAssertEqual(bundles[0].unusedFreeQty, 0)
            
            XCTAssertEqual(bundles[1].qtyFree, 1)
            XCTAssertEqual(bundles[1].unusedFreeQty, 0)
            
            XCTAssertEqual(bundles[2].qtyFree, 0)
            XCTAssertEqual(bundles[2].unusedFreeQty, 1)
        }
    }
    
}
