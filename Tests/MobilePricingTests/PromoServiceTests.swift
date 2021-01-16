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
        mobileDownload.testPromotion(customer: mike, amountOff)

        let promoService = PromoService(mike, christmasDay)
        
        XCTAssertFalse(promoService.isEmpty)

        let amountOffSavings = amountOff.getAmountOff(unitPrice: Money(10.00, .EUR))
        XCTAssertEqual(amountOffSavings, Money(1.74, .EUR))
    }

    func testSingleAmountOffPromo() throws {
        mobileDownload = MobileDownload()
        let mike = mobileDownload.testCustomer()
        
        let beer = mobileDownload.testItem()

        mobileDownload.testPromotion(customer: mike, PromoItem(beer, amountOff: 1.74))

        let promoService = PromoService(mike, christmasDay)

        let beerSale = SaleLine(id: 1, itemNid: beer.recNid, qtyOrdered: 1, unitPrice: Money(10.00, .EUR))

        promoService.computeDiscounts(beerSale)
        
        XCTAssertEqual(beerSale.unitDisc, Money(1.74, .EUR))
    }
    
    func testPromoInWrongCurrency() throws {
        mobileDownload = MobileDownload()
        let mike = mobileDownload.testCustomer()
        
        let beer = mobileDownload.testItem()

        mobileDownload.testPromotion(customer: mike, PromoItem(beer, amountOff: 1.74))

        let promoService = PromoService(mike, christmasDay)

        let beerSale = SaleLine(id: 1, itemNid: beer.recNid, qtyOrdered: 1, unitPrice: Money(10.00, .USD))

        promoService.computeDiscounts(beerSale)
        
        XCTAssertNil(beerSale.unitDisc)
    }
    
    func testPromoInDifferentCurrency() throws {
        mobileDownload = MobileDownload()
        let mike = mobileDownload.testCustomer()
        
        let beer = mobileDownload.testItem()
        
        let exchange = ExchangeRatesService(ExchangeRate(from: .EUR, to: .USD, date: .distantPast, rate: 2.0))
        mobileDownload.handheld.exchangeRates = exchange
        
        mobileDownload.testPromotion(customer: mike, PromoItem(beer, amountOff: 1.74))

        let promoService = PromoService(mike, christmasDay)

        let beerSale = SaleLine(id: 1, itemNid: beer.recNid, qtyOrdered: 1, unitPrice: Money(10.00, .USD))

        promoService.computeDiscounts(beerSale)
        
        XCTAssertEqual(beerSale.unitDisc, Money(2 * 1.74, .USD))
    }
    
    func testTriggeredAmountOffPromo() throws {
        mobileDownload = MobileDownload()
        let mike = mobileDownload.testCustomer()
        
        let beer = mobileDownload.testItem()

        let promoSection = mobileDownload.testPromotion(customer: mike, PromoItem(beer, amountOff: 1.74))
        promoSection.caseMinimum = 10
        
        let promoService = PromoService(mike, christmasDay)
        
        let beerSale = SaleLine(id: 1, itemNid: beer.recNid, qtyOrdered: 1, unitPrice: Money(10.00, .EUR))
        let moreBeerSales = SaleLine(id: 2, itemNid: beer.recNid, qtyOrdered: 9, unitPrice: Money(10.00, .EUR))
        
        
        // the discount is triggered at 10 cases
        promoService.computeDiscounts(beerSale, moreBeerSales)
        XCTAssertEqual(beerSale.unitDisc, Money(1.74, .EUR))
        
        
        // buying 1 case of beer isn't enough for the discount
        promoService.computeDiscounts(beerSale)
        XCTAssertNil(beerSale.unitDisc)
    }
    
    func testTwoAmountOffPromosNotReversed() throws {
        mobileDownload = MobileDownload()
        let mike = mobileDownload.testCustomer()
        
        let beer = mobileDownload.testItem()

        mobileDownload.testPromotion(customer: mike, PromoItem(beer, amountOff: 1.74))
        mobileDownload.testPromotion(customer: mike, PromoItem(beer, amountOff: 1.55))
  
        let promoService = PromoService(mike, christmasDay)

        let beerSale = SaleLine(id: 1, itemNid: beer.recNid, qtyOrdered: 1, unitPrice: Money(10.00, .EUR))

        promoService.computeDiscounts(beerSale)
        
        XCTAssertEqual(beerSale.unitDisc, Money(1.74, .EUR))
    }
    
    func testTwoAmountOffPromosReversed() throws {
        mobileDownload = MobileDownload()
        let mike = mobileDownload.testCustomer()
        
        let beer = mobileDownload.testItem()

        mobileDownload.testPromotion(customer: mike, PromoItem(beer, amountOff: 1.55))
        mobileDownload.testPromotion(customer: mike, PromoItem(beer, amountOff: 1.74))
  
        let promoService = PromoService(mike, christmasDay)

        let beerSale = SaleLine(id: 1, itemNid: beer.recNid, qtyOrdered: 1, unitPrice: Money(10.00, .EUR))

        promoService.computeDiscounts(beerSale)
        
        XCTAssertEqual(beerSale.unitDisc, Money(1.74, .EUR))
    }
    
    func testMixAndMatchTriggeredAmountOffPromo() throws {
        mobileDownload = MobileDownload()
        let mike = mobileDownload.testCustomer()
        
        let beer = mobileDownload.testItem()
        let darkBeer = mobileDownload.testItem()

        let promoSection = mobileDownload.testPromotion(customer: mike,
                                                        PromoItem(beer, amountOff: 1.74),
                                                        PromoItem(darkBeer, amountOff: 1.55))
        promoSection.caseMinimum = 10
        promoSection.isMixAndMatch = true
        
        let promoService = PromoService(mike, christmasDay)
        
        let beerSale = SaleLine(id: 1, itemNid: beer.recNid, qtyOrdered: 1, unitPrice: Money(10.00, .EUR))
        let darkBeerSale = SaleLine(id: 2, itemNid: darkBeer.recNid, qtyOrdered: 9, unitPrice: Money(10.00, .EUR))
        
        
        // the discount is triggered at 10 cases
        promoService.computeDiscounts(beerSale, darkBeerSale)
        XCTAssertEqual(beerSale.unitDisc, Money(1.74, .EUR))
        XCTAssertEqual(darkBeerSale.unitDisc, Money(1.55, .EUR))
        
        
        // buying 1 case of beer isn't enough for the discount
        promoService.computeDiscounts(beerSale)
        XCTAssertNil(beerSale.unitDisc)
    }
    
    func testNonMixAndMatchTriggeredAmountOffPromo() throws {
        mobileDownload = MobileDownload()
        let mike = mobileDownload.testCustomer()
        
        let beer = mobileDownload.testItem()
        let darkBeer = mobileDownload.testItem()

        let promoSection = mobileDownload.testPromotion(customer: mike,
                                                        PromoItem(beer, amountOff: 1.74),
                                                        PromoItem(darkBeer, amountOff: 1.55))
        promoSection.caseMinimum = 10
        promoSection.isMixAndMatch = false
        
        let promoService = PromoService(mike, christmasDay)
        
        let beerSale = SaleLine(id: 1, itemNid: beer.recNid, qtyOrdered: 10, unitPrice: Money(10.00, .EUR))
        let darkBeerSale = SaleLine(id: 2, itemNid: darkBeer.recNid, qtyOrdered: 9, unitPrice: Money(10.00, .EUR))
        
        
        // the discount is triggered at 10 cases
        promoService.computeDiscounts(beerSale, darkBeerSale)
        XCTAssertEqual(beerSale.unitDisc, Money(1.74, .EUR))
        XCTAssertNil(darkBeerSale.unitDisc)
    }
}

//MARK helpers for testing

fileprivate extension MobileDownload {
    @discardableResult
    func testPromotion(customer: CustomerRecord, _ promoItems: PromoItem ...) -> PromoSectionRecord {
        let promoSection = mobileDownload.testPromoSection()
        let promoCode = mobileDownload.testPromoCode()
        
        promoCode.promoCustomers = [ customer.recNid ]
        promoCode.currency = .EUR
        
        promoSection.promoCodeNid = promoCode.recNid
        promoSection.isMixAndMatch = true
        promoSection.promoPlan = .Default
        promoSection.setPromoItems(promoItems)
        
        for promoItem in promoItems {
            promoItem.promoSectionNid = promoSection.recNid
        }
        
        return promoSection
    }
}
