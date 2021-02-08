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
    let unusedFreebies: [UnusedFreebie]
    let sale: MockOrderLine
    let sales: [MockOrderLine]
    
    init(promoSolution: PromoSolution, orderLines: [MockOrderLine]) {
        unusedFreebies = promoSolution.unusedFreebies
        sale = orderLines.first!
        sales = orderLines
    }
}

@discardableResult
func getPromoTestSolution(transactionCurrency: Currency = .USD, _ promoSection: PromoSectionRecord, _ orderLines: MockOrderLine ...) -> PromoTestSolution {
    getPromoTestSolution(transactionCurrency: transactionCurrency, [promoSection], orderLines)
}

func getPromoTestSolution(transactionCurrency: Currency = .USD, _ promoSections: [PromoSectionRecord], _ orderLines: [MockOrderLine]) -> PromoTestSolution {

    let promoService = PromoService(transactionCurrency: transactionCurrency, promoSections: promoSections, promoDate: christmasDay)
    
    let promoSolution = promoService.computeDiscounts(dcOrderLines: orderLines)
    
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

        if true {
            let beerSale = MockOrderLine(beer, 9)
            
            getPromoTestSolution(promoSection, beerSale)
            
            XCTAssertEqual(beerSale.qtyFree, 0)
        }
        
        if true {
            let beerSale = MockOrderLine(beer, 10)
            
            let promoSolution = getPromoTestSolution(promoSection, beerSale)
            
            XCTAssertEqual(beerSale.qtyFree, 0)
            XCTAssertEqual(promoSolution.unusedFreebies.count, 1)
            XCTAssertEqual(promoSolution.unusedFreebies.first?.qtyFree, 1)
        }
        
        if true {
            let beerSale = MockOrderLine(beer, 11)
            
            let promoSolution = getPromoTestSolution(promoSection, beerSale)
            
            XCTAssertEqual(beerSale.qtyFree, 1)
            XCTAssertEqual(promoSolution.unusedFreebies.count, 0)
        }
        
        if true {
            let beerSale = MockOrderLine(beer, 21)
            
            let promoSolution = getPromoTestSolution(promoSection, beerSale)
            
            XCTAssertEqual(beerSale.qtyFree, 1)
            XCTAssertEqual(promoSolution.unusedFreebies.count, 1)
            XCTAssertEqual(promoSolution.unusedFreebies.first?.qtyFree, 1)
        }
        
        if true {
            let beerSale = MockOrderLine(beer, 32)
            
            let promoSolution = getPromoTestSolution(promoSection, beerSale)
            
            XCTAssertEqual(beerSale.qtyFree, 2)
            XCTAssertEqual(promoSolution.unusedFreebies.count, 1)
            XCTAssertEqual(promoSolution.unusedFreebies.first?.qtyFree, 1)
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

        
        if true {
            let beerSale = MockOrderLine(beer, 21)
            let wineSale = MockOrderLine(wine, 1)
            getPromoTestSolution(promoSection, wineSale, beerSale)
            
            XCTAssertEqual(beerSale.qtyFree, 1)
            XCTAssertEqual(wineSale.qtyFree, 1)
            
        }
        
        if true {
            let beerSale = MockOrderLine(beer, 8)
            let wineSale = MockOrderLine(wine, 1)
            
            getPromoTestSolution(promoSection, wineSale, beerSale)
            
            XCTAssertEqual(beerSale.qtyFree, 0)
            XCTAssertEqual(wineSale.qtyFree, 0)
        }
        
        if true {
            let beerSale = MockOrderLine(beer, 8)
            let wineSale = MockOrderLine(wine, 2)
            
            let solution = getPromoTestSolution(promoSection, wineSale, beerSale)
            
            XCTAssertEqual(beerSale.qtyFree, 0)
            XCTAssertEqual(wineSale.qtyFree, 0)
            
            //XCTAssertEqual(solution.unusedFreebies.count, 1)
        }
        
        if true {
            let beerSale = MockOrderLine(beer, 10)
            let wineSale = MockOrderLine(wine, 1)
            
            getPromoTestSolution(promoSection, wineSale, beerSale)
            
            XCTAssertEqual(beerSale.qtyFree, 0)
            XCTAssertEqual(wineSale.qtyFree, 1)
            
            getPromoTestSolution(promoSection, beerSale, wineSale)
            
            XCTAssertEqual(beerSale.qtyFree, 0)
            XCTAssertEqual(wineSale.qtyFree, 1)
        }

        if true {
            let beerSale = MockOrderLine(beer, 21)
            let wineSale = MockOrderLine(wine, 1)
            
            beerSale.isPreferredFreeGoodLine = true
            
            getPromoTestSolution(promoSection, wineSale, beerSale)
            
            XCTAssertEqual(beerSale.qtyFree, 2)
            XCTAssertEqual(wineSale.qtyFree, 0)
        }
        
        if true {
            let beerSale = MockOrderLine(beer, 21)
            let wineSale = MockOrderLine(wine, 1)
            
            wineSale.isPreferredFreeGoodLine = true
            
            getPromoTestSolution(promoSection, wineSale, beerSale)
            
            XCTAssertEqual(beerSale.qtyFree, 1)
            XCTAssertEqual(wineSale.qtyFree, 1)
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
        let freeWine = PromoItem(wine, percentOff: 100)
        
        freeBeer.isExplicitTriggerItem = true
        promoSection.setPromoItems([freeBeer, freeWine])

        if true {
            let beerSale = MockOrderLine(beer, 8)
            let wineSale = MockOrderLine(wine, 1)
            getPromoTestSolution(promoSection, beerSale, wineSale)
            
            XCTAssertEqual(beerSale.qtyFree, 0)
            XCTAssertEqual(wineSale.qtyFree, 0)
        }
        
        if true {
            let beerSale = MockOrderLine(beer, 8)
            let wineSale = MockOrderLine(wine, 2)
            getPromoTestSolution(promoSection, beerSale, wineSale)
            
            XCTAssertEqual(beerSale.qtyFree, 0)
            XCTAssertEqual(wineSale.qtyFree, 0)
        }
        
        if true {
            let beerSale = MockOrderLine(beer, 10)
            let wineSale = MockOrderLine(wine, 1)
            getPromoTestSolution(promoSection, beerSale, wineSale)
            
            XCTAssertEqual(beerSale.qtyFree, 0)
            XCTAssertEqual(wineSale.qtyFree, 1)
        }
        
        // in this case for each 10 beers bought, the logic will provide a free wine. Thus you'll get 2 free wines when you buy 20 beers.
        // if you choose to give free beer instead, then you'll only get 1 free beer and that's it: buy 10 beers, get 1
        // beer free. But, now there are only 9 beers left to trigger the next free good and that's not
        // enough. So the algorithm will prefer to produce free goods that are not part of the trigger requirements as well.
        if true {
            let beerSale = MockOrderLine(beer, 20)
            let wineSale = MockOrderLine(wine, 2)
            getPromoTestSolution(promoSection, beerSale, wineSale)
            
            XCTAssertEqual(beerSale.qtyFree, 0)
            XCTAssertEqual(wineSale.qtyFree, 2)
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

        // not enough beer to get free wine
        if true {
            let beerSale = MockOrderLine(beer, 8)
            let wineSale = MockOrderLine(wine, 1)
            getPromoTestSolution(promoSection, beerSale, wineSale)
            
            XCTAssertEqual(beerSale.qtyFree, 0)
            XCTAssertEqual(wineSale.qtyFree, 0)
        }
        
        // still not enough beer to get free wine
        if true {
            let beerSale = MockOrderLine(beer, 8)
            let wineSale = MockOrderLine(wine, 2)
            getPromoTestSolution(promoSection, beerSale, wineSale)
            
            XCTAssertEqual(beerSale.qtyFree, 0)
            XCTAssertEqual(wineSale.qtyFree, 0)
        }
        
        // buy 10 beers, get 1 wine free
        if true {
            let beerSale = MockOrderLine(beer, 10)
            let wineSale = MockOrderLine(wine, 1)
            getPromoTestSolution(promoSection, beerSale, wineSale)
            
            XCTAssertEqual(beerSale.qtyFree, 0)
            XCTAssertEqual(wineSale.qtyFree, 1)
        }
        
        // buy 10 beers, get 1 wine free (but there's no wine on the order)
        if true {
            let beerSale = MockOrderLine(beer, 10)
            let promoSolution = getPromoTestSolution(promoSection, beerSale)
            
            XCTAssertEqual(beerSale.qtyFree, 0)
            
            XCTAssertEqual(promoSolution.unusedFreebies.count, 1)
        }
    }
    
}


