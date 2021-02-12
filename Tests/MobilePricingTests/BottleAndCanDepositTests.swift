//
//  BottleAndCanDepositTests.swift
//  MobilePricingTests
//
//  Created by Michael Rutherford on 2/10/21.
//

import XCTest
import MobileDownload
@testable import MobilePricing
import MoneyAndExchangeRates

class BottleAndCanDepositServiceTests: XCTestCase {
    
    
    func testBottleOrCanDeposit() throws {
        mobileDownload = MobileDownload()
        
        let coke24Pack = mobileDownload.testItem()
        let coke6Pack = mobileDownload.testItem()
        let cokePallet = mobileDownload.testItem()
        let walgreens = mobileDownload.testCustomer()

        coke6Pack.altPackFamilyNid = coke24Pack.recNid
        coke6Pack.altPackCasecount = 4
        coke6Pack.altPackIsFractionOfPrimaryPack = true
        
        cokePallet.altPackFamilyNid = coke24Pack.recNid
        cokePallet.altPackCasecount = 20
        cokePallet.altPackIsFractionOfPrimaryPack = false
        
        // first check out the standard bottle/can deposit - note this is entered as an amount per case (not per can or bottle like we do with CRV)
        coke24Pack.deposit = 2.40
        coke24Pack.depositIsSupplierOriginated = false
        
        if true {
            let deposit = BottleAndCanDepositService.getBottleOrCanDeposit(customer: walgreens, item: coke24Pack)
            XCTAssertEqual(deposit, Currency.USD.amount(2.40))
        }
        
        if true {
            let deposit = BottleAndCanDepositService.getBottleOrCanDeposit(customer: walgreens, item: cokePallet)
            XCTAssertEqual(deposit, Currency.USD.amount(48.00))
        }
        
        if true {
            let deposit = BottleAndCanDepositService.getBottleOrCanDeposit(customer: walgreens, item: coke6Pack)
            XCTAssertEqual(deposit, Currency.USD.amount(0.60))
        }
        
        if true {
            coke6Pack.deposit = 0.75
            let deposit = BottleAndCanDepositService.getBottleOrCanDeposit(customer: walgreens, item: coke6Pack)
            XCTAssertEqual(deposit, Currency.USD.amount(0.75))
            coke6Pack.deposit = nil
        }
        
        if true {
            walgreens.chargeOnlySupplierDeposits = true
            let deposit = BottleAndCanDepositService.getBottleOrCanDeposit(customer: walgreens, item: coke6Pack)
            XCTAssertEqual(deposit, Currency.USD.zero)
            walgreens.chargeOnlySupplierDeposits = false
        }
        
        // okay - now switch to the product with a supplierDeposit (rather than a "standard" deposit)
        
        coke24Pack.supplierDeposit = 2.40
        coke24Pack.deposit = nil
        coke24Pack.depositIsSupplierOriginated = true
        walgreens.chargeOnlySupplierDeposits = true
        
        if true {
            let deposit = BottleAndCanDepositService.getBottleOrCanDeposit(customer: walgreens, item: coke24Pack)
            XCTAssertEqual(deposit, Currency.USD.amount(2.40))
        }
        
        if true {
            let deposit = BottleAndCanDepositService.getBottleOrCanDeposit(customer: walgreens, item: cokePallet)
            XCTAssertEqual(deposit, Currency.USD.amount(48.00))
        }
        
        if true {
            let deposit = BottleAndCanDepositService.getBottleOrCanDeposit(customer: walgreens, item: coke6Pack)
            XCTAssertEqual(deposit, Currency.USD.amount(0.60))
        }
        
        if true {
            coke6Pack.supplierDeposit = 0.75
            let deposit = BottleAndCanDepositService.getBottleOrCanDeposit(customer: walgreens, item: coke6Pack)
            XCTAssertEqual(deposit, Currency.USD.amount(0.75))
            coke6Pack.supplierDeposit = nil
        }
    }
}
