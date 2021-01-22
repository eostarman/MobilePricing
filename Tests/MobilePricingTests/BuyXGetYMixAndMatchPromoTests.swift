//
//  BuyXGetYMixAndMatchPromoTests.swift
//  MobilePricingTests
//
//  Created by Michael Rutherford on 1/16/21.
//


import XCTest
import MobileDownload
@testable import MobilePricing
import MoneyAndExchangeRates

class BuyXGetYMixAndMatchPromoTests: XCTestCase {
    
    func testBasicCalculation() {
        mobileDownload = MobileDownload()
        
        let beer = mobileDownload.testItem()
        
        let triggerItemNids: Set<Int> = [ beer.recNid ]
        let freeItemNids: Set<Int> = [ beer.recNid ]
        
        let promo = BuyXGetYMixAndMatchPromo(triggerItemNids: triggerItemNids, freeItemNids: freeItemNids, qtyX: 10, qtyY: 1)
        
        var solution: BuyXGetYMixAndMatchPromo.Solution
        
        solution = promo.compute(qtys: [beer.recNid:11])
        
    }
}
