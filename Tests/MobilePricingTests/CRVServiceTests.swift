//
//  CRVServiceTests.swift
//  MobilePricingTests
//
//  Created by Michael Rutherford on 2/10/21.
//

import XCTest
import MobileDownload
@testable import MobilePricing
import MoneyAndExchangeRates

class CRVServiceTests: XCTestCase {

    func testCRVForCustomer() throws {
        mobileDownload = MobileDownload()
        mobileDownload.handheld.isCaliforniaTaxPluginInstalled = true
        
        let coke24Pack = mobileDownload.testItem()
        let coke6Pack = mobileDownload.testItem()
        let cokePallet = mobileDownload.testItem()
        let walgreens = mobileDownload.testCustomer()
        let crvContainerType = mobileDownload.testCRVcontainerType()
        let orderType = mobileDownload.testOrderType()
        
        walgreens.shipState = "ca"
        
        crvContainerType.taxRate = 0.05 // 5 cents per can or bottle
        
        coke24Pack.crvContainerTypeNid = crvContainerType.recNid
        coke24Pack.packsPerCase = 4
        coke24Pack.unitsPerPack = 6
        
        coke6Pack.altPackFamilyNid = coke24Pack.recNid
        coke6Pack.altPackCasecount = 4
        coke6Pack.altPackIsFractionOfPrimaryPack = true
        
        cokePallet.altPackFamilyNid = coke24Pack.recNid
        cokePallet.altPackCasecount = 20
        cokePallet.altPackIsFractionOfPrimaryPack = false
        
        func getItemCRV(customer: CustomerRecord, item: ItemRecord, orderTypeNid: Int?) -> MoneyWithoutCurrency {
            if let (crv, _) = CRVService.GetItemCRV(customer: walgreens, item: item, orderTypeNid: orderTypeNid) {
                return crv.withoutCurrency()
            } else {
                return .zero
            }
        }
        
        // on the alt-pack
        if true {
            let crv = getItemCRV(customer: walgreens, item: coke6Pack, orderTypeNid: nil)
            XCTAssertEqual(crv, 0.30)
        }
        
        // on the primary-pack
        if true {
            let crv = getItemCRV(customer: walgreens, item: coke24Pack, orderTypeNid: nil)
            XCTAssertEqual(crv, 1.20)
        }
        
        // on the pallet
        if true {
            let crv = getItemCRV(customer: walgreens, item: cokePallet, orderTypeNid: nil)
            XCTAssertEqual(crv, 24.00)
        }
        
        // CRV calculation does not depend on the flag indicating that the California Tax plugin is installed (if the data is there, it's used)
        if true {
            mobileDownload.handheld.isCaliforniaTaxPluginInstalled = false
            let crv = getItemCRV(customer: walgreens, item: coke6Pack, orderTypeNid: nil)
            XCTAssertEqual(crv, 0.30)
            mobileDownload.handheld.isCaliforniaTaxPluginInstalled = true
        }
        
        // no CRV for sales to a customer who is somehow immune to the CRV charges
        if true {
            walgreens.exemptFromCRVCharges = true
            let crv = getItemCRV(customer: walgreens, item: coke6Pack, orderTypeNid: nil)
            XCTAssertEqual(crv, 0.00)
            walgreens.exemptFromCRVCharges = false
        }
        
        // no CRV for an item that has no assigned crvContainerTypeNid
        if true {
            coke24Pack.crvContainerTypeNid = nil
            let crv = getItemCRV(customer: walgreens, item: coke6Pack, orderTypeNid: nil)
            XCTAssertEqual(crv, 0.00)
            coke24Pack.crvContainerTypeNid = crvContainerType.recNid
        }
        
        // no CRV for an item that has an assigned crvContainerTypeNid where that CRV container has no tax rate set
        if true {
            crvContainerType.taxRate = nil
            let crv = getItemCRV(customer: walgreens, item: coke6Pack, orderTypeNid: nil)
            XCTAssertEqual(crv, 0.00)
            crvContainerType.taxRate = 0.05
        }
        
        // no CRV for an item that is on a "special type of order" that suppresses the CRV
        if true {
            orderType.doNotChargeCrv = true
            let crv = getItemCRV(customer: walgreens, item: coke6Pack, orderTypeNid: orderType.recNid)
            XCTAssertEqual(crv, 0.00)
            orderType.doNotChargeCrv = false
        }
        
        // do charge CRV for an item that is on a "special type of order" that does not the CRV
        if true {
            let crv = getItemCRV(customer: walgreens, item: coke6Pack, orderTypeNid: orderType.recNid)
            XCTAssertEqual(crv, 0.30)
        }
        
        // on the 6-pack again - just to make sure the prior tests were correctly resetting the flags
        if true {
            let crv = getItemCRV(customer: walgreens, item: coke6Pack, orderTypeNid: nil)
            XCTAssertEqual(crv, 0.30)
        }
    }

}
