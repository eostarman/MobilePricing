//
//  PromoServiceTests.swift
//  MobilePricingTests
//
//  Created by Michael Rutherford on 1/7/21.
//

import XCTest
import MobileDownload
@testable import MobilePricing
import MoneyAndExchangeRates

class PromoServiceTests: XCTestCase {
    
    func testBasicPromoService() throws {
        mobileDownload = MobileDownload()
        let mike = mobileDownload.testCustomer()
        
        let beer = mobileDownload.testItem()

        let amountOff = PromoItem(beer, amountOff: 1.74)
        mobileDownload.testPromoSection(customer: mike, amountOff)

        let promoService = PromoService(mike, christmasDay)
        
        XCTAssertFalse(promoService.isEmpty)

        let amountOffSavings = amountOff.getAmountOff(unitPrice: Money(10.00, .USD))
        XCTAssertEqual(amountOffSavings, Money(1.74, .USD))
    }

    func testSingleAmountOffPromo() throws {
        mobileDownload = MobileDownload()
        let mike = mobileDownload.testCustomer()
        
        let beer = mobileDownload.testItem()

        mobileDownload.testPromoSection(customer: mike, PromoItem(beer, amountOff: 1.74))

        let promoService = DiscountCalculator(mike, christmasDay)
        
        let beerSale = MockOrderLine(itemNid: beer.recNid, qtyOrdered: 1, unitPrice: 10.00)

        promoService.computeDiscounts(beerSale)
        
        XCTAssertEqual(beerSale.unitDiscount, 1.74)
    }
    
    func testPromoInWrongCurrency() throws {
        mobileDownload = MobileDownload()
        let mike = mobileDownload.testCustomer()
        
        let beer = mobileDownload.testItem()

        mobileDownload.testPromoSection(customer: mike, PromoItem(beer, amountOff: 1.74))

        let promoService = DiscountCalculator(mike, christmasDay, transactionCurrency: .EUR)

        let beerSale = MockOrderLine(itemNid: beer.recNid, qtyOrdered: 1, unitPrice: 10.00)

        promoService.computeDiscounts(beerSale)
        
        XCTAssertEqual(beerSale.unitDiscount, .zero)
    }
    
    func testPromoInDifferentCurrency() throws {
        mobileDownload = MobileDownload()
        let mike = mobileDownload.testCustomer()
        
        let beer = mobileDownload.testItem()
        
        let exchange = ExchangeRatesService(ExchangeRate(from: .EUR, to: .USD, date: .distantPast, rate: 2.0))
        mobileDownload.handheld.exchangeRates = exchange
        
        mobileDownload.testPromoSection(customer: mike, PromoItem(beer, amountOff: 1.74))

        let promoService = DiscountCalculator(mike, christmasDay)

        let beerSale = MockOrderLine(itemNid: beer.recNid, qtyOrdered: 2, unitPrice: 10.00)

        promoService.computeDiscounts(beerSale)
        
        XCTAssertEqual(beerSale.unitDiscount, 1.74)
    }
    
    func testTriggeredAmountOffPromo() throws {
        mobileDownload = MobileDownload()
        let mike = mobileDownload.testCustomer()
        
        let beer = mobileDownload.testItem()

        let promoSection = mobileDownload.testPromoSection(customer: mike, PromoItem(beer, amountOff: 1.74))
        promoSection.caseMinimum = 10
        
        let promoService = DiscountCalculator(mike, christmasDay)
        
        let beerSale = MockOrderLine(itemNid: beer.recNid, qtyOrdered: 1, unitPrice: 10.00)
        let moreBeerSales = MockOrderLine(itemNid: beer.recNid, qtyOrdered: 9, unitPrice: 10.00)
        
        
        // the discount is triggered at 10 cases
        promoService.computeDiscounts(beerSale, moreBeerSales)
        XCTAssertEqual(beerSale.unitDiscount, 1.74)
        
        
        // buying 1 case of beer isn't enough for the discount
        promoService.computeDiscounts(beerSale)
        XCTAssertEqual(beerSale.unitDiscount, .zero)
    }
    
    func testTwoAmountOffPromosNotReversed() throws {
        mobileDownload = MobileDownload()
        let mike = mobileDownload.testCustomer()
        
        let beer = mobileDownload.testItem()

        mobileDownload.testPromoSection(customer: mike, currency: .EUR, PromoItem(beer, amountOff: 1.74))
        mobileDownload.testPromoSection(customer: mike, currency: .EUR, PromoItem(beer, amountOff: 1.55))
  
        let promoService = DiscountCalculator(mike, christmasDay, transactionCurrency: .EUR)

        let beerSale = MockOrderLine(itemNid: beer.recNid, qtyOrdered: 1, unitPrice: 10.00)

        promoService.computeDiscounts(beerSale)
        
        XCTAssertEqual(beerSale.unitDiscount, 1.74)
    }
    
    func testTwoAmountOffPromosReversed() throws {
        mobileDownload = MobileDownload()
        let mike = mobileDownload.testCustomer()
        
        let beer = mobileDownload.testItem()

        mobileDownload.testPromoSection(customer: mike, PromoItem(beer, amountOff: 1.55))
        mobileDownload.testPromoSection(customer: mike, PromoItem(beer, amountOff: 1.74))
  
        let promoService = DiscountCalculator(mike, christmasDay)

        let beerSale = MockOrderLine(itemNid: beer.recNid, qtyOrdered: 1, unitPrice: 10.00)

        promoService.computeDiscounts(beerSale)
        
        XCTAssertEqual(beerSale.unitDiscount, 1.74)
    }
    
    func testMixAndMatchTriggeredAmountOffPromo() throws {
        mobileDownload = MobileDownload()
        let mike = mobileDownload.testCustomer()
        
        let beer = mobileDownload.testItem()
        let darkBeer = mobileDownload.testItem()

        let promoSection = mobileDownload.testPromoSection(customer: mike, currency: .EUR, PromoItem(beer, amountOff: 1.74), PromoItem(darkBeer, amountOff: 1.55))
        promoSection.caseMinimum = 10
        promoSection.isMixAndMatch = true
        
        let promoService = DiscountCalculator(mike, christmasDay, transactionCurrency: .EUR)
        
        let beerSale = MockOrderLine(itemNid: beer.recNid, qtyOrdered: 1, unitPrice: 10.00)
        let darkBeerSale = MockOrderLine(itemNid: darkBeer.recNid, qtyOrdered: 9, unitPrice: 10.00)
        
        
        // the discount is triggered at 10 cases
        promoService.computeDiscounts(beerSale, darkBeerSale)
        XCTAssertEqual(beerSale.unitDiscount, 1.74)
        XCTAssertEqual(darkBeerSale.unitDiscount, 1.55)
        
        
        // buying 1 case of beer isn't enough for the discount
        promoService.computeDiscounts(beerSale)
        XCTAssertEqual(beerSale.unitDiscount, .zero)
    }
    
    func testNonMixAndMatchTriggeredAmountOffPromo() throws {
        mobileDownload = MobileDownload()
        let mike = mobileDownload.testCustomer()
        
        let beer = mobileDownload.testItem()
        let darkBeer = mobileDownload.testItem()

        let promoSection = mobileDownload.testPromoSection(customer: mike, currency: .EUR, PromoItem(beer, amountOff: 1.74), PromoItem(darkBeer, amountOff: 1.55))
        promoSection.caseMinimum = 10
        promoSection.isMixAndMatch = false
        
        let promoService = DiscountCalculator(mike, christmasDay, transactionCurrency: .EUR)
        
        let beerSale = MockOrderLine(itemNid: beer.recNid, qtyOrdered: 10, unitPrice: 10.00)
        let darkBeerSale = MockOrderLine(itemNid: darkBeer.recNid, qtyOrdered: 9, unitPrice: 10.00)
        
        // the discount is triggered at 10 cases
        promoService.computeDiscounts(beerSale, darkBeerSale)
        XCTAssertEqual(beerSale.unitDiscount, 1.74)
        XCTAssertEqual(darkBeerSale.unitDiscount, 0.00)
    }
}
