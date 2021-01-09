//
//  MixAndMatchPromoTests.swift
//  MobilePricingTests
//
//  Created by Michael Rutherford on 1/7/21.
//

import XCTest
import MobileDownload
@testable import MobilePricing
import MoneyAndExchangeRates

class MixAndMatchPromoTests: XCTestCase {

    func testBasicPromo() throws {
        mobileDownload = MobileDownload()
        
        let beer = mobileDownload.testItem()
        
        
        let promoCode = mobileDownload.testPromoCode()
        let promoSection = mobileDownload.testPromoSection()
        
        promoCode.currency = .EUR
        promoSection.setPromoItems([ PromoItem(beer, percentOff: 10) ])
                
        let mixAndMatchPromo = MixAndMatchPromo(promoCode, promoSection)
      
        let isTriggered = mixAndMatchPromo.isTriggered(qtys: [beer.recNid:1])
        XCTAssertTrue(isTriggered)
        
        
        beer.defaultPrice = 1.50
        
    }
    
    func testBasicMixAndMatch() throws {
        mobileDownload = MobileDownload()
        
        let beer = mobileDownload.testItem()
        
        let amountOff = PromoItem(beer, amountOff: 1.74)
        
        let percentOff = PromoItem(beer, percentOff: 1.3)
        
        let promoPrice = PromoItem(beer, promotedPrice: 2.33)
        
        let promoSection = mobileDownload.testPromoSection()
        let promoCode = mobileDownload.testPromoCode()
        
        promoCode.currency = .USD
        beer.defaultPrice = 10.56
        
        promoSection.setPromoItems([PromoItem(beer, promotedPrice: 2.33)])
        
    }
    
    
    


}
