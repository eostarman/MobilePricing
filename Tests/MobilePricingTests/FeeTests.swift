//
//  AdditionalFeeTests.swift
//  MobilePricingTests
//
//  Created by Michael Rutherford on 2/6/21.
//

import XCTest
@testable import MobilePricing
import MobileDownload
import MoneyAndExchangeRates

/// this tests the additional fees that are computed per-line-item on an order
/// this is basically the same as the line-item taxes
class FeeTests: XCTestCase {

    /// compute a $1.00 fee for the beer sale
    func testBasicFee() throws {
        mobileDownload = MobileDownload()
        
        let beer = mobileDownload.testItem()
        
        let promoCode = mobileDownload.testPromoCode(.USD)
        promoCode.isTieredPromo = false

        let promoSection = mobileDownload.testPromoSection(promoCode: promoCode, PromoItem(beer, amountOff: 1.00))
        promoSection.promoPlan = .AdditionalFee
        promoSection.additionalFeePromo_IsTax = false

        func beerSale(_ qtyOrdered: Int) -> MockOrderLine {
            MockOrderLine(itemNid: beer.recNid, qtyOrdered: qtyOrdered, unitPrice: 10.00)
        }
        
        if true {
            let solution = getPromoTestSolution([promoSection], [beerSale(3)])
            
            XCTAssertEqual(solution.sale.unitFee, 1.00)
        }
    }
    
    /// compute a 10% fee on the discounted beer ($10.00 - $2.00 discount). The fee is $0.80
    func testFeeAfterDiscount() throws {
        mobileDownload = MobileDownload()
        
        let beer = mobileDownload.testItem()
        
        let promoCodeForDiscount = mobileDownload.testPromoCode(.USD)
        promoCodeForDiscount.isTieredPromo = false
        let discountPromoSection = mobileDownload.testPromoSection(promoCode: promoCodeForDiscount, PromoItem(beer, amountOff: 2.00))
        
        
        let promoCodeForFee = mobileDownload.testPromoCode(.USD)
        promoCodeForFee.isTieredPromo = true
        promoCodeForFee.promoTierSeq = 1
        
        let feePromoSection = mobileDownload.testPromoSection(promoCode: promoCodeForFee, PromoItem(beer, percentOff: 10.0))
        feePromoSection.promoPlan = .AdditionalFee
        feePromoSection.additionalFeePromo_IsTax = false
        
        
        func beerSale(_ qtyOrdered: Int) -> MockOrderLine {
            MockOrderLine(itemNid: beer.recNid, qtyOrdered: qtyOrdered, unitPrice: 10.00)
        }
        
        if true {
            let solution = getPromoTestSolution([discountPromoSection, feePromoSection], [beerSale(3)])
            
            XCTAssertEqual(solution.sale.unitDiscount, 2.00)
            XCTAssertEqual(solution.sale.unitFee, 0.80)
        }
    }
    
    /// compute a 10% fee on the discounted beer ($10.00 - $2.00 discount). The fee is computed before the discount so it's $1.00
    func testFeeBeforeDiscount() throws {
        mobileDownload = MobileDownload()
        
        let beer = mobileDownload.testItem()
        
        let promoCodeForDiscount = mobileDownload.testPromoCode(.USD)
        let discountPromoSection = mobileDownload.testPromoSection(promoCode: promoCodeForDiscount, PromoItem(beer, amountOff: 2.00))
        
        let promoCodeForFee = mobileDownload.testPromoCode(.USD)

        let feePromoSection = mobileDownload.testPromoSection(promoCode: promoCodeForFee, PromoItem(beer, percentOff: 10.0))
        feePromoSection.promoPlan = .AdditionalFee
        feePromoSection.additionalFeePromo_IsTax = false
        
        func beerSale(_ qtyOrdered: Int) -> MockOrderLine {
            MockOrderLine(itemNid: beer.recNid, qtyOrdered: qtyOrdered, unitPrice: 10.00)
        }
        
        if true {
            let solution = getPromoTestSolution([discountPromoSection, feePromoSection], [beerSale(3)])
            
            XCTAssertEqual(solution.sale.unitDiscount, 2.00)
            XCTAssertEqual(solution.sale.unitFee, 1.00)
        }
    }

}
