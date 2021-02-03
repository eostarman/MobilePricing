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

struct PromoTestSolution {
    let promoTuples: [PromoTuple]
    let unusedFreebies: [UnusedFreebie]
    let sale: MockOrderLine
    let sales: [MockOrderLine]
    
    init(promoSolution: PromoSolution, orderLines: [MockOrderLine]) {
        promoTuples = promoSolution.promoTuples
        unusedFreebies = promoSolution.unusedFreebies
        sale = orderLines.first!
        sales = orderLines
    }
}


func getPromoTestSolution(transactionCurrency: Currency = .USD, _ promoSection: PromoSectionRecord, _ orderLines: MockOrderLine ...) -> PromoTestSolution {

    let discountCalculator = DiscountCalculator(transactionCurrency: transactionCurrency, promoSections: [promoSection])
    
    let promoSolution = discountCalculator.computeDiscounts(orderLines)
    
    let solutionForTest = PromoTestSolution(promoSolution: promoSolution, orderLines: orderLines)
    
    return solutionForTest
}

class BuyXGetYCalculatorFreebieBundleTests: XCTestCase {

    func testBuy10Get1FreeNonMixAndMatch() throws {
        mobileDownload = MobileDownload()
        
        let promoSection = mobileDownload.testPromoSection()
        promoSection.isBuyXGetY = true
        promoSection.isMixAndMatch = false
        promoSection.qtyX = 10
        promoSection.qtyY = 1
        
        let beer = mobileDownload.testItem()
        
        let freeBeer = PromoItem(beer, percentOff: 100)
        promoSection.setPromoItems([freeBeer])
        
        func beerSale(_ qtyOrdered: Int) -> MockOrderLine {
            MockOrderLine(itemNid: beer.recNid, qtyOrdered: qtyOrdered, unitPrice: 10.00)
        }
        
        if true {
            let solution = getPromoTestSolution(promoSection, beerSale(9))
            
            XCTAssertEqual(solution.sale.totalDiscount, .zero)
        }
        
        if true {
            let solution = getPromoTestSolution(promoSection, beerSale(10))
            
            XCTAssertEqual(solution.promoTuples.count, 0)
            XCTAssertEqual(solution.unusedFreebies.count, 1)
            XCTAssertEqual(solution.unusedFreebies[0].qtyFree, 1)
        }
        
        if true {
            let solution = getPromoTestSolution(promoSection, beerSale(11))
            
            XCTAssertEqual(solution.promoTuples.count, 1)
            XCTAssertEqual(solution.unusedFreebies.count, 0)
            
            XCTAssertEqual(solution.promoTuples[0].qtyDiscounted, 1)
        }
        
        if true {
            let solution = getPromoTestSolution(promoSection, beerSale(21))
            
            XCTAssertEqual(solution.promoTuples.count, 1)
            XCTAssertEqual(solution.unusedFreebies.count, 1)
            
            XCTAssertEqual(solution.promoTuples[0].qtyDiscounted, 1)
            XCTAssertEqual(solution.unusedFreebies[0].qtyFree, 1)
        }
        
        if true {
            let solution = getPromoTestSolution(promoSection, beerSale(32))
            
            XCTAssertEqual(solution.promoTuples.count, 1)
            XCTAssertEqual(solution.unusedFreebies.count, 1)
            
            XCTAssertEqual(solution.promoTuples[0].qtyDiscounted, 2)
            XCTAssertEqual(solution.unusedFreebies[0].qtyFree, 1)
        }
    }

    func testBuy10Get1FreeMixAndMatch() throws {
        mobileDownload = MobileDownload()
        
        let promoSection = mobileDownload.testPromoSection()
        promoSection.isBuyXGetY = true
        promoSection.isMixAndMatch = true
        promoSection.qtyX = 10
        promoSection.qtyY = 1
        
        let beer = mobileDownload.testItem()
        let wine = mobileDownload.testItem()
        
        let freeBeer = PromoItem(beer, percentOff: 100)
        let freeWine = PromoItem(wine, percentOff: 100)
        promoSection.setPromoItems([freeBeer, freeWine])
        
        func beerSale(_ qtyOrdered: Int) -> MockOrderLine {
            MockOrderLine(itemNid: beer.recNid, qtyOrdered: qtyOrdered, unitPrice: 10.00)
        }
        func wineSale(_ qtyOrdered: Int) -> MockOrderLine {
            MockOrderLine(itemNid: wine.recNid, qtyOrdered: qtyOrdered, unitPrice: 10.00)
        }
        
        if true {
            let solution = getPromoTestSolution(promoSection, wineSale(1), beerSale(21))
            
            XCTAssertEqual(solution.promoTuples.count, 2)
            XCTAssertEqual(solution.unusedFreebies.count, 0)
            XCTAssertEqual(solution.promoTuples[0].dcOrderLine.itemNid, wine.recNid)
            XCTAssertEqual(solution.promoTuples[0].qtyDiscounted, 1)
            XCTAssertEqual(solution.promoTuples[1].dcOrderLine.itemNid, beer.recNid)
            XCTAssertEqual(solution.promoTuples[1].qtyDiscounted, 1)
        }
        
        if true {
            let solution = getPromoTestSolution(promoSection, beerSale(8), wineSale(1))
            
            XCTAssertEqual(solution.promoTuples.count, 0)
        }
        
        if true {
            let solution = getPromoTestSolution(promoSection, beerSale(8), wineSale(2))
            
            XCTAssertEqual(solution.promoTuples.count, 0)
            XCTAssertEqual(solution.unusedFreebies.count, 1)
        }
        
        if true {
            let solution = getPromoTestSolution(promoSection, beerSale(10), wineSale(1))
            
            XCTAssertEqual(solution.promoTuples.count, 1)
            XCTAssertEqual(solution.unusedFreebies.count, 0)
            XCTAssertEqual(solution.promoTuples[0].dcOrderLine.itemNid, wine.recNid)
        }
        
        if true {
            let solution = getPromoTestSolution(promoSection, wineSale(1), beerSale(10))
            
            XCTAssertEqual(solution.promoTuples.count, 1)
            XCTAssertEqual(solution.unusedFreebies.count, 0)
            XCTAssertEqual(solution.promoTuples[0].dcOrderLine.itemNid, wine.recNid)
        }
        
        if true {
            let preferredBeerSale = beerSale(21)
            preferredBeerSale.isPreferredFreeGoodLine = true
            let solution = getPromoTestSolution(promoSection, wineSale(1), preferredBeerSale)
            
            XCTAssertEqual(solution.promoTuples.count, 1)
            XCTAssertEqual(solution.unusedFreebies.count, 0)
            XCTAssertEqual(solution.promoTuples[0].dcOrderLine.itemNid, beer.recNid)
            XCTAssertEqual(solution.promoTuples[0].qtyDiscounted, 2)
        }
        
        if true {
            let preferredWineSale = wineSale(1)
            preferredWineSale.isPreferredFreeGoodLine = true
            let solution = getPromoTestSolution(promoSection, preferredWineSale, beerSale(21))
            
            XCTAssertEqual(solution.promoTuples.count, 2)
            XCTAssertEqual(solution.unusedFreebies.count, 0)
            XCTAssertEqual(solution.promoTuples[0].dcOrderLine.itemNid, wine.recNid)
            XCTAssertEqual(solution.promoTuples[0].qtyDiscounted, 1)
            XCTAssertEqual(solution.promoTuples[1].dcOrderLine.itemNid, beer.recNid)
            XCTAssertEqual(solution.promoTuples[1].qtyDiscounted, 1)
        }
    }

    /// Buy X of one item to get free goods of a different item (an item not in the trigger group)
    func testBuy10BeerGet1WineOrBeerFree() throws {
        mobileDownload = MobileDownload()
        
        let promoSection = mobileDownload.testPromoSection()
        promoSection.isBuyXGetY = true
        promoSection.isMixAndMatch = true
        promoSection.qtyX = 10
        promoSection.qtyY = 1
        
        let beer = mobileDownload.testItem()
        let wine = mobileDownload.testItem()
        
        let freeBeer = PromoItem(beer, percentOff: 100)
        freeBeer.isExplicitTriggerItem = true
        let freeWine = PromoItem(wine, percentOff: 100)
        promoSection.setPromoItems([freeBeer, freeWine])
        
        func beerSale(_ qtyOrdered: Int) -> MockOrderLine {
            MockOrderLine(itemNid: beer.recNid, qtyOrdered: qtyOrdered, unitPrice: 10.00)
        }
        func wineSale(_ qtyOrdered: Int) -> MockOrderLine {
            MockOrderLine(itemNid: wine.recNid, qtyOrdered: qtyOrdered, unitPrice: 10.00)
        }
        
        if true {
            let solution = getPromoTestSolution(promoSection, beerSale(8), wineSale(1))
            
            XCTAssertEqual(solution.promoTuples.count, 0)
        }
        
        if true {
            let solution = getPromoTestSolution(promoSection, beerSale(8), wineSale(2))
            
            XCTAssertEqual(solution.promoTuples.count, 0)
        }
        
        if true {
            let solution = getPromoTestSolution(promoSection, beerSale(10), wineSale(1))
            
            XCTAssertEqual(solution.promoTuples.count, 1)
            XCTAssertEqual(solution.promoTuples[0].dcOrderLine.itemNid, wine.recNid)
            XCTAssertEqual(solution.promoTuples[0].qtyDiscounted, 1)
        }
        
        // in this case for each 10 beers bought, the logic will provide a free wine. Thus you'll get 2 free wines when you buy 20 beers.
        // if you choose to give free beer instead, then you'll only get 1 free beer and that's it: buy 10 beers, get 1
        // beer free. But, now there are only 9 beers left to trigger the next free good and that's not
        // enough. So the algorithm will prefer to produce free goods that are not part of the trigger requirements as well.
        if true {
            let solution = getPromoTestSolution(promoSection, beerSale(20), wineSale(2))
            
            XCTAssertEqual(solution.promoTuples.count, 1)
            XCTAssertEqual(solution.promoTuples[0].dcOrderLine.itemNid, wine.recNid)
            XCTAssertEqual(solution.promoTuples[0].qtyDiscounted, 2)
        }
    }
    
    func testBuyXGetYMixAndMatchButMustBuyBeerToGetFreeWine() throws {
        mobileDownload = MobileDownload()
        
        let promoSection = mobileDownload.testPromoSection()
        promoSection.isBuyXGetY = true
        promoSection.isMixAndMatch = true
        promoSection.qtyX = 10
        promoSection.qtyY = 1
        
        let beer = mobileDownload.testItem()
        let wine = mobileDownload.testItem()
        
        let freeBeer = PromoItem(beer, percentOff: 0)
        freeBeer.isExplicitTriggerItem = true
        let freeWine = PromoItem(wine, percentOff: 100)
        promoSection.setPromoItems([freeBeer, freeWine])
        
        func beerSale(_ qtyOrdered: Int) -> MockOrderLine {
            MockOrderLine(itemNid: beer.recNid, qtyOrdered: qtyOrdered, unitPrice: 10.00)
        }
        func wineSale(_ qtyOrdered: Int) -> MockOrderLine {
            MockOrderLine(itemNid: wine.recNid, qtyOrdered: qtyOrdered, unitPrice: 10.00)
        }
        
        // not enough beer to get free wine
        if true {
            let solution = getPromoTestSolution(promoSection, beerSale(8), wineSale(1))
            
            XCTAssertEqual(solution.promoTuples.count, 0)
        }
        
        // still not enough beer to get free wine
        if true {
            let solution = getPromoTestSolution(promoSection, beerSale(8), wineSale(2))
            
            XCTAssertEqual(solution.promoTuples.count, 0)
        }
        
        // buy 10 beers, get 1 wine free
        if true {
            let solution = getPromoTestSolution(promoSection, beerSale(10), wineSale(1))
            
            XCTAssertEqual(solution.promoTuples.count, 1)
            XCTAssertEqual(solution.promoTuples[0].dcOrderLine.itemNid, wine.recNid)
            XCTAssertEqual(solution.promoTuples[0].qtyDiscounted, 1)
        }
        
        // buy 10 beers, get 1 wine free (but there's no wine on the order)
        if true {
            let solution = getPromoTestSolution(promoSection, beerSale(10))
            
            XCTAssertEqual(solution.promoTuples.count, 0)
            XCTAssertEqual(solution.unusedFreebies.count, 1)
            XCTAssertEqual(solution.unusedFreebies[0].qtyFree, 1)
            XCTAssertEqual(solution.unusedFreebies[0].itemNids, [wine.recNid])
        }
    }
    
}


