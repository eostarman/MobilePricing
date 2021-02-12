//
//  TaxTests.swift
//  MobilePricingTests
//
//  Created by Michael Rutherford on 2/6/21.
//

import XCTest
@testable import MobilePricing
import MobileDownload
import MoneyAndExchangeRates

/// this tests the taxes (like excise taxes) that are computed per-line-item on an order (these are not the same as sales taxes where you're selling to a consumer not to a retailer who will in turn sell to a consumer)
/// this is basically the same as additional fees that are not taxes
class TaxTests: XCTestCase {
    
    /// compute a $1.00 tax for the beer sale
    func testBasicTax() throws {
        mobileDownload = MobileDownload()
        
        let beer = mobileDownload.testItem()
        
        let promoCode = mobileDownload.testPromoCode()
        promoCode.isTieredPromo = false
        
        let promoSection = mobileDownload.testPromoSection(promoCode: promoCode, PromoItem(beer, amountOff: 1.00))
        promoSection.promoPlan = .AdditionalFee
        promoSection.additionalFeePromo_IsTax = true
        
        func beerSale(_ qtyOrdered: Int) -> MockOrderLine {
            MockOrderLine(itemNid: beer.recNid, qtyOrdered: qtyOrdered, unitPrice: 10.00)
        }
        
        if true {
            let solution = getPromoTestSolution([promoSection], [beerSale(3)])
            
            XCTAssertEqual(solution.sale.unitCharge, 1.00)
        }
    }
    
    /// compute a 10% tax on the discounted beer ($10.00 - $2.00 discount). The tax is $0.80
    func testTaxAfterDiscount() throws {
        mobileDownload = MobileDownload()
        
        let beer = mobileDownload.testItem()
        
        let promoCodeForDiscount = mobileDownload.testPromoCode()
        promoCodeForDiscount.isTieredPromo = false
        let discountPromoSection = mobileDownload.testPromoSection(promoCode: promoCodeForDiscount, PromoItem(beer, amountOff: 2.00))
        
        
        let promoCodeForTax = mobileDownload.testPromoCode()
        promoCodeForTax.isTieredPromo = true
        promoCodeForTax.promoTierSeq = 1
        
        let taxPromoSection = mobileDownload.testPromoSection(promoCode: promoCodeForTax, PromoItem(beer, percentOff: 10.0))
        taxPromoSection.promoPlan = .AdditionalFee
        taxPromoSection.additionalFeePromo_IsTax = true
        
        
        func beerSale(_ qtyOrdered: Int) -> MockOrderLine {
            MockOrderLine(itemNid: beer.recNid, qtyOrdered: qtyOrdered, unitPrice: 10.00)
        }
        
        if true {
            let solution = getPromoTestSolution([discountPromoSection, taxPromoSection], [beerSale(3)])
            
            XCTAssertEqual(solution.sale.unitDiscount, 2.00)
            XCTAssertEqual(solution.sale.unitCharge, 0.80)
        }
    }
    
    /// compute a 10% tax on the discounted beer ($10.00 - $2.00 discount). The tax is computed before the discount so it's $1.00
    func testTaxBeforeDiscount() throws {
        mobileDownload = MobileDownload()
        
        let beer = mobileDownload.testItem()
        
        let promoCodeForDiscount = mobileDownload.testPromoCode()
        let discountPromoSection = mobileDownload.testPromoSection(promoCode: promoCodeForDiscount, PromoItem(beer, amountOff: 2.00))
        
        let promoCodeForTax = mobileDownload.testPromoCode()
        
        let taxPromoSection = mobileDownload.testPromoSection(promoCode: promoCodeForTax, PromoItem(beer, percentOff: 10.0))
        taxPromoSection.promoPlan = .AdditionalFee
        taxPromoSection.additionalFeePromo_IsTax = true
        
        func beerSale(_ qtyOrdered: Int) -> MockOrderLine {
            MockOrderLine(itemNid: beer.recNid, qtyOrdered: qtyOrdered, unitPrice: 10.00)
        }
        
        if true {
            let solution = getPromoTestSolution([discountPromoSection, taxPromoSection], [beerSale(3)])
            
            XCTAssertEqual(solution.sale.unitDiscount, 2.00)
            XCTAssertEqual(solution.sale.unitCharge, 1.00)
        }
    }
    
    
    
}
