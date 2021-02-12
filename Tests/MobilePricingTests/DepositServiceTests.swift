//
//  DepositServiceTests.swift
//  MobilePricingTests
//
//  Created by Michael Rutherford on 2/10/21.
//

import XCTest
import MobileDownload
@testable import MobilePricing
import MoneyAndExchangeRates

class DepositServiceTests: XCTestCase {
    
    func testBottleOrCanDeposit() throws {
        mobileDownload = MobileDownload()
        
        let hollandWarehouse = mobileDownload.testWarehouse()
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
        
        let depositService = DepositService(shipFrom: hollandWarehouse, sellTo: walgreens, pricingDate: christmasDay, transactionCurrency: .USD, numberOfDecimals: 2)
        
        if true {
            let itemDeposits = depositService.getitemDepositsAndCRV(item: coke24Pack)
            
            XCTAssertEqual(itemDeposits.bottleOrCanDeposit, 2.40)
        }
    }
    
    func testCarrierDeposit() throws {
        mobileDownload = MobileDownload()
        
        let hollandWarehouse = mobileDownload.testWarehouse()
        let walgreens = mobileDownload.testCustomer()
        let coke2Liter = mobileDownload.testItem()
        let carrierFor2Liters = mobileDownload.testContainer()
        
        coke2Liter.containerNid = carrierFor2Liters.recNid
        
        carrierFor2Liters.carrierDeposit = 3.25
        carrierFor2Liters.carrierDeposit2 = 2.55
        
        coke2Liter.containerNid = carrierFor2Liters.recNid
        
        let depositService = DepositService(shipFrom: hollandWarehouse, sellTo: walgreens, pricingDate: christmasDay)
        
        if true {
            let itemDeposits = depositService.getitemDepositsAndCRV(item: coke2Liter)
            
            XCTAssertEqual(itemDeposits.carrierDeposit, 3.25)
        }
        
        if true {
            walgreens.useSecondaryContainerDeposits = true
            let itemDeposits = depositService.getitemDepositsAndCRV(item: coke2Liter)
            walgreens.useSecondaryContainerDeposits = false
            
            XCTAssertEqual(itemDeposits.carrierDeposit, 2.55)
        }
        
        if true {
            walgreens.doNotChargeCarrierDeposits = true
            let itemDeposits = depositService.getitemDepositsAndCRV(item: coke2Liter)
            walgreens.doNotChargeCarrierDeposits = false
            
            XCTAssertEqual(itemDeposits.carrierDeposit, .zero)
        }
    }
    
    /// in Michigan (e.g.) the distributor picks up "bags of empties" and gets a credit for doing this (to cover the cost of actually picking them up and storing them in the warehouse before shipping them to recycling)
    func testBagCredit() throws {
        mobileDownload = MobileDownload()
        
        let hollandWarehouse = mobileDownload.testWarehouse()
        let walgreens = mobileDownload.testCustomer()
        let container = mobileDownload.testContainer()
        let bagOfEmpties = mobileDownload.testItem()
        
        bagOfEmpties.containerNid = container.recNid
        container.bagCredit = 1.11
        container.bagCredit2 = 7.53
        
        let depositService = DepositService(shipFrom: hollandWarehouse, sellTo: walgreens, pricingDate: christmasDay)
        
        if true {
            let itemDeposits = depositService.getitemDepositsAndCRV(item: bagOfEmpties)
            
            XCTAssertEqual(itemDeposits.bagCredit, 1.11)
        }
        
        if true {
            walgreens.useSecondaryContainerDeposits = true
            let itemDeposits = depositService.getitemDepositsAndCRV(item: bagOfEmpties)
            walgreens.useSecondaryContainerDeposits = false
            
            XCTAssertEqual(itemDeposits.bagCredit, 7.53)
        }
    }
    
    func testStatePickupCredit() throws {
        mobileDownload = MobileDownload()
        
        let hollandWarehouse = mobileDownload.testWarehouse()
        let walgreens = mobileDownload.testCustomer()
        let container = mobileDownload.testContainer()
        let bagOfEmpties = mobileDownload.testItem()
        
        bagOfEmpties.containerNid = container.recNid
        container.statePickupCredit = 1.23
        container.statePickupCredit2 = 2.34
        
        let depositService = DepositService(shipFrom: hollandWarehouse, sellTo: walgreens, pricingDate: christmasDay)
        
        if true {
            let itemDeposits = depositService.getitemDepositsAndCRV(item: bagOfEmpties)
            
            XCTAssertEqual(itemDeposits.statePickupCredit, 1.23)
        }
        
        if true {
            walgreens.useSecondaryContainerDeposits = true
            let itemDeposits = depositService.getitemDepositsAndCRV(item: bagOfEmpties)
            walgreens.useSecondaryContainerDeposits = false
            
            XCTAssertEqual(itemDeposits.statePickupCredit, 2.34)
        }
    }
    
    func testUnitCRV() throws {
        mobileDownload = MobileDownload()
        
        let hollandWarehouse = mobileDownload.testWarehouse()
        let walgreens = mobileDownload.testCustomer()
        let coke24Pack = mobileDownload.testItem()
        let crvContainerType = mobileDownload.testCRVcontainerType()
        
        crvContainerType.taxRate = 0.05
        
        coke24Pack.crvContainerTypeNid = crvContainerType.recNid
        coke24Pack.unitsPerPack = 6
        coke24Pack.packsPerCase = 4
        
        walgreens.shipState = "Ca"
        
        let depositService = DepositService(shipFrom: hollandWarehouse, sellTo: walgreens, pricingDate: christmasDay)
        
        if true {
            let itemDeposits = depositService.getitemDepositsAndCRV(item: coke24Pack)
            
            XCTAssertEqual(itemDeposits.crvContainerTypeNid, crvContainerType.recNid)
            XCTAssertEqual(itemDeposits.unitCRV, 1.20)
        }
    }
    
    func testDunnageDeposits() throws {
        mobileDownload = MobileDownload()
        
        let hollandWarehouse = mobileDownload.testWarehouse()
        let pallet = mobileDownload.testItem()
        let walgreens = mobileDownload.testCustomer()
        let walgreensCorporate = mobileDownload.testCustomer()
        
        walgreens.pricingParentNid = walgreensCorporate.recNid
        pallet.isDunnage = true
        pallet.deposit = 1.75
        
        let depositService = DepositService(shipFrom: hollandWarehouse, sellTo: walgreens, pricingDate: christmasDay, transactionCurrency: .USD, numberOfDecimals: 2)
        
        if true {
            let itemDeposits = depositService.getitemDepositsAndCRV(item: pallet)
            
            XCTAssertEqual(itemDeposits.bottleOrCanDeposit, 1.75)
        }
        
        if true {
            walgreens.doNotChargeDunnageDeposits = true
            let itemDeposits = depositService.getitemDepositsAndCRV(item: pallet)
            
            XCTAssertEqual(itemDeposits.bottleOrCanDeposit, .zero)
            walgreens.doNotChargeDunnageDeposits = false
        }
        
        // here we use the customer's "special price" for the pallet as its deposit
        if true {
            walgreensCorporate.specialPrices = [SpecialPrice(itemNid: pallet.recNid, price: 1.53, startDate: christmasDay, endDate: nil)]
            let itemDeposits = depositService.getitemDepositsAndCRV(item: pallet)
            
            XCTAssertEqual(itemDeposits.bottleOrCanDeposit, 1.53)
            walgreensCorporate.specialPrices = nil
        }
    }
    
    // use deposit schedules to set the deposit and change it on the day after christmas
    func testDunnageDepositsFromDepositSchedule() throws {
        mobileDownload = MobileDownload()
        
        let priceSheetForDeposits = mobileDownload.testPriceSheet()
        let priceSheetForDepositsAfterChristmas = mobileDownload.testPriceSheet()
        
        let hollandWarehouse = mobileDownload.testWarehouse()
        let pallet = mobileDownload.testItem()
        let walgreens = mobileDownload.testCustomer()
        
        priceSheetForDeposits.isDepositSchedule = true
        priceSheetForDeposits.setPrice(pallet, priceLevel: 0, price: 1.33)
        priceSheetForDeposits.endDate = dayAfterChristmas
        priceSheetForDeposits.endDateIsSupercededDate = true
        
        priceSheetForDepositsAfterChristmas.startDate = dayAfterChristmas
        priceSheetForDepositsAfterChristmas.isDepositSchedule = true
        priceSheetForDepositsAfterChristmas.setPrice(pallet, priceLevel: 0, price: 5.25)
        
        
        if true {
            let depositService = DepositService(shipFrom: hollandWarehouse, sellTo: walgreens, pricingDate: christmasDay, transactionCurrency: .USD, numberOfDecimals: 2)
            
            let itemDeposits = depositService.getitemDepositsAndCRV(item: pallet)
            
            XCTAssertEqual(itemDeposits.bottleOrCanDeposit, 1.33)
        }
        
        if true {
            let depositService = DepositService(shipFrom: hollandWarehouse, sellTo: walgreens, pricingDate: dayAfterChristmas, transactionCurrency: .USD, numberOfDecimals: 2)
            
            let itemDeposits = depositService.getitemDepositsAndCRV(item: pallet)
            
            XCTAssertEqual(itemDeposits.bottleOrCanDeposit, 5.25)
        }
    }
    
    func testDunnageDepositsWithMultipleCurrencies() throws {
        mobileDownload = MobileDownload()
        
        let zambianKwacha = Currency.ZMW
        let botswananPula = Currency.BWP
        
        // 1 Botswanan pula == 2 Zambian kwachas
        
        mobileDownload.handheld.exchangeRates = ExchangeRatesService(ExchangeRate(from: botswananPula, to: zambianKwacha, date: christmasDay, rate: 2))
        
        XCTAssertEqual(mobileDownload.exchange(Money(1.00, .BWP), to: .ZMW), Money(2.00, .ZMW))
        
        let zambiaDepositSchedule = mobileDownload.testPriceSheet()
        let botswanaDepositSchedule = mobileDownload.testPriceSheet()
        let zambiaWarehouse = mobileDownload.testWarehouse()
        let botswanaWarehouse = mobileDownload.testWarehouse()
        let zambiaWalgreens = mobileDownload.testCustomer()
        let botswanaWalgreens = mobileDownload.testCustomer()
        
        let pallet = mobileDownload.testItem()
        
        zambiaDepositSchedule.warehouses = [zambiaWarehouse.recNid: .init(priceLevel: 0, canUseAutomaticColumns: false)]
        zambiaDepositSchedule.currency = zambianKwacha
        zambiaDepositSchedule.isDepositSchedule = true
        zambiaDepositSchedule.setPrice(pallet, priceLevel: 0, price: 5.12)
        
        zambiaWalgreens.transactionCurrencyNid = zambianKwacha.currencyNid
        botswanaWalgreens.transactionCurrencyNid = botswananPula.currencyNid
        
        botswanaDepositSchedule.warehouses = [botswanaWarehouse.recNid: .init(priceLevel: 0, canUseAutomaticColumns: false)]
        botswanaDepositSchedule.currency = botswananPula
        botswanaDepositSchedule.isDepositSchedule = true
        botswanaDepositSchedule.setPrice(pallet, priceLevel: 0, price: 1.11)
        
        // deliver to the Botswana walgreens from the Botswana warehouse - the deposit is 1.11 pula
        if true {
            let depositService = DepositService(shipFrom: botswanaWarehouse, sellTo: botswanaWalgreens, pricingDate: christmasDay)
            
            let itemDeposits = depositService.getitemDepositsAndCRV(item: pallet)
            
            XCTAssertEqual(itemDeposits.bottleOrCanDeposit, 1.11)
        }
        
        // deliver to the Botswana walgreens from the Botswana warehouse - the deposit is 1.11 pula (but use a transaction currency of kwacha)
        if true {
            let depositService = DepositService(shipFrom: botswanaWarehouse, sellTo: botswanaWalgreens, pricingDate: christmasDay, transactionCurrency: zambianKwacha, numberOfDecimals: zambianKwacha.numberOfDecimals)
            
            let itemDeposits = depositService.getitemDepositsAndCRV(item: pallet)
            
            XCTAssertEqual(itemDeposits.bottleOrCanDeposit, 2.22)
        }
        
        // deliver to the Zambia walgreens from the Botswana warehouse - the deposit is 1.11 pula converted to the transaction currency (kwacha)
        if true {
            let depositService = DepositService(shipFrom: botswanaWarehouse, sellTo: zambiaWalgreens, pricingDate: christmasDay)
            
            let itemDeposits = depositService.getitemDepositsAndCRV(item: pallet)
            
            XCTAssertEqual(itemDeposits.bottleOrCanDeposit, 2.22)
        }
        
        // deliver to the Zambia walgreens from the Zambia warehouse - the deposit is in kwacha as is the sale (the transaction currency)
        if true {
            let depositService = DepositService(shipFrom: zambiaWarehouse, sellTo: zambiaWalgreens, pricingDate: christmasDay)
            
            let itemDeposits = depositService.getitemDepositsAndCRV(item: pallet)
            
            XCTAssertEqual(itemDeposits.bottleOrCanDeposit, 5.12)
        }
        
        // deliver to the Botswana walgreens from the Zambia warehouse - the deposit is 5.12 kwacha which converts to 2.56 pula
        if true {
            let depositService = DepositService(shipFrom: zambiaWarehouse, sellTo: botswanaWalgreens, pricingDate: christmasDay)
            
            let itemDeposits = depositService.getitemDepositsAndCRV(item: pallet)
            
            XCTAssertEqual(itemDeposits.bottleOrCanDeposit, 2.56)
        }
    }
}
