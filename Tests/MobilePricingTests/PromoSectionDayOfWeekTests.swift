//
//  PromoSectionTests.swift
//  MobilePricingTests
//
//  Created by Michael Rutherford on 1/10/21.
//

import XCTest
import MobileDownload
@testable import MobilePricing
import MoneyAndExchangeRates

class PromoSectionDayOfWeekTests: XCTestCase {

    func testDayOfWeekPromotions() {
        let mobileDownload = MobileDownload()
        
        let promoSection = mobileDownload.testPromoSection()

        promoSection.isDayOfWeekPromo = true
        
        let christmasDay: Date = "2020-12-24" // christmas eve, 2020
        var date: Date
        
        date = Calendar.current.date(byAdding: .day, value: 0, to: christmasDay)!
        XCTAssertFalse(promoSection.isAvailableOnWeekday(date))
        promoSection.thursdayPromo = true
        XCTAssertTrue(promoSection.isAvailableOnWeekday(date))
        
        date = Calendar.current.date(byAdding: .day, value: 1, to: christmasDay)!
        XCTAssertFalse(promoSection.isAvailableOnWeekday(date))
        promoSection.fridayPromo = true
        XCTAssertTrue(promoSection.isAvailableOnWeekday(date))
        
        date = Calendar.current.date(byAdding: .day, value: 2, to: christmasDay)!
        XCTAssertFalse(promoSection.isAvailableOnWeekday(date))
        promoSection.saturdayPromo = true
        XCTAssertTrue(promoSection.isAvailableOnWeekday(date))
        
        date = Calendar.current.date(byAdding: .day, value: 3, to: christmasDay)!
        XCTAssertFalse(promoSection.isAvailableOnWeekday(date))
        promoSection.sundayPromo = true
        XCTAssertTrue(promoSection.isAvailableOnWeekday(date))
        
        date = Calendar.current.date(byAdding: .day, value: 4, to: christmasDay)!
        XCTAssertFalse(promoSection.isAvailableOnWeekday(date))
        promoSection.mondayPromo = true
        XCTAssertTrue(promoSection.isAvailableOnWeekday(date))
        
        date = Calendar.current.date(byAdding: .day, value: 5, to: christmasDay)!
        XCTAssertFalse(promoSection.isAvailableOnWeekday(date))
        promoSection.tuesdayPromo = true
        XCTAssertTrue(promoSection.isAvailableOnWeekday(date))
        
        date = Calendar.current.date(byAdding: .day, value: 6, to: christmasDay)!
        XCTAssertFalse(promoSection.isAvailableOnWeekday(date))
        promoSection.wednesdayPromo = true
        XCTAssertTrue(promoSection.isAvailableOnWeekday(date))
    }
}
