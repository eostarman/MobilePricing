//
//  TriggerServiceTests.swift
//  MobilePricingTests
//
//  Created by Michael Rutherford on 1/10/21.
//

import XCTest
import MobileDownload
@testable import MobilePricing

class TriggerRequirementsTests: XCTestCase {
    
    func testBasicsWithOneItem() {
        mobileDownload = MobileDownload()
        let beer = mobileDownload.testItem()
        
        let requirements = TriggerRequirements(basis: .qty, minimum: 10, triggerItemNids: [beer.recNid], groupRequirements: [])
        
        XCTAssertFalse(requirements.isTriggered([beer.recNid: 1]))
        
        XCTAssertTrue(requirements.isTriggered([beer.recNid: 10]))
    }
    
    func testBasicsWithTwoItems() {
        mobileDownload = MobileDownload()
        let beer = mobileDownload.testItem()
        let darkBeer = mobileDownload.testItem()
        let wine = mobileDownload.testItem()
        
        let requirements = TriggerRequirements(basis: .qty, minimum: 10, triggerItemNids: [beer.recNid, darkBeer.recNid], groupRequirements: [])
        
        XCTAssertFalse(requirements.isTriggered([beer.recNid: 1]))
        
        XCTAssertFalse(requirements.isTriggered([wine.recNid: 10]))
        
        XCTAssertFalse(requirements.isTriggered([beer.recNid: 1, wine.recNid: 9]))
        
        XCTAssertTrue(requirements.isTriggered([beer.recNid: 10]))
        
        XCTAssertTrue(requirements.isTriggered([beer.recNid: 1, darkBeer.recNid: 9]))
    }
    
    func testCaseRollupWithOneCaseMinimum() {
        mobileDownload = MobileDownload()
        
        let caseofBeer = mobileDownload.testItem()
        let sixPackOfBeer = mobileDownload.testItem()
        
        sixPackOfBeer.setPrimaryPack(to: caseofBeer, numberOfTheseItemsInOnePrimaryPack: 4)
        
        // 1-case of beer is required
        let requirements = TriggerRequirements(basis: .caseRollup, minimum: 1, triggerItemNids: [caseofBeer.recNid], groupRequirements: [])
        
        XCTAssertTrue(requirements.isTriggered([caseofBeer.recNid: 1]))
        
        XCTAssertTrue(requirements.isTriggered([sixPackOfBeer.recNid: 4]))
    }
    
    func testCaseRollupWithTFourBottleMinimum() {
        mobileDownload = MobileDownload()
        
        let caseOfJimBeam = mobileDownload.testItem()
        let bottleOfJimBeam = mobileDownload.testItem()
        
        bottleOfJimBeam.setPrimaryPack(to: caseOfJimBeam, numberOfTheseItemsInOnePrimaryPack: 3)
        
        // 4 bottles are required
        let requirements = TriggerRequirements(basis: .caseRollup, minimum: 4, triggerItemNids: [bottleOfJimBeam.recNid], groupRequirements: [])
        
        // 2 bottles are not enough
        XCTAssertFalse(requirements.isTriggered([bottleOfJimBeam.recNid: 2]))
        
        // 2 cases == 6 bottles
        XCTAssertTrue(requirements.isTriggered([caseOfJimBeam.recNid: 2]))
        
        // 4 bottles == 1 case, 1 bottle
        XCTAssertTrue(requirements.isTriggered([bottleOfJimBeam.recNid: 4]))
        
        // 1 case, 1 bottle == 4 bottles
        XCTAssertTrue(requirements.isTriggered([caseOfJimBeam.recNid: 1, bottleOfJimBeam.recNid: 1]))
        
        // 1 case == 3 bottles (not enough)
        XCTAssertFalse(requirements.isTriggered([caseOfJimBeam.recNid: 1]))
    }
    
    func testMinimumBasedOnItemWeight() {
        mobileDownload = MobileDownload()
        
        let caseOfCoffeeBeans = mobileDownload.testItem()
        caseOfCoffeeBeans.itemWeight = 0.3333
        
        // 4 bottles are required
        let requirements = TriggerRequirements(basis: .itemWeight, minimum: 1, triggerItemNids: [caseOfCoffeeBeans.recNid], groupRequirements: [])
        
        // 3 cases are enough
        XCTAssertTrue(requirements.isTriggered([caseOfCoffeeBeans.recNid: 3]))
        
        // 2 cases are not enough
        XCTAssertFalse(requirements.isTriggered([caseOfCoffeeBeans.recNid: 2]))
    }
    
    func testTriggerGroups() {
        mobileDownload = MobileDownload()
        
        let darkBeer = mobileDownload.testItem()
        let lightBeer = mobileDownload.testItem()
        
        let lightBeerRequirement = TriggerRequirements(triggerGroup: 1, basis: .qty, minimum: 1, triggerItemNids: [lightBeer.recNid], groupRequirements: [])
        
        let requirements = TriggerRequirements(basis: .qty, minimum: 10, triggerItemNids: [darkBeer.recNid, lightBeer.recNid], groupRequirements: [lightBeerRequirement])
        
        XCTAssertFalse(requirements.isTriggered([darkBeer.recNid: 10]))
        XCTAssertTrue(requirements.isTriggered([darkBeer.recNid: 10, lightBeer.recNid: 2]))
    }
}
