//
//  RecordHelpers.swift
//  MobilePricingTests
//
//  Created by Michael Rutherford on 1/3/21.
//

import XCTest
import MobileDownload
import MobilePricing
import MoneyAndExchangeRates

let christmasEve: Date = "12-24-2020"
let christmasDay: Date = "12-25-2020"
let dayAfterChristmas: Date = "12-26-2020"

fileprivate var numberOfTestRecordsCreated = 0

fileprivate func testRecord<T: Record>() -> T {
    numberOfTestRecordsCreated += 1
    let recNid = numberOfTestRecordsCreated
    
    var record = T()
    record.recNid = recNid
    record.recKey = "\(recNid)"
    record.recName = "\(T.self) #\(recNid)"
    return record
}

extension MobileDownload {
    func testWarehouse() -> WarehouseRecord { warehouses.add(testRecord()) }
    func testItem() -> ItemRecord {
        let item = items.add(testRecord())
        item.altPackCasecount = 1
        item.altPackFamilyNid = item.recNid
        return item        
    }
    func testCustomer() -> CustomerRecord { customers.add(testRecord()) }
    func testPriceSheet() -> PriceSheetRecord { priceSheets.add(testRecord()) }
    func testPriceRule() -> PriceRuleRecord { priceRules.add(testRecord())}
    func testPromoCode() -> PromoCodeRecord { promoCodes.add(testRecord())}
    func testPromoSection() -> PromoSectionRecord { promoSections.add(testRecord())}
}

// https://www.avanderlee.com/swift/expressible-literals/
extension Date: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        self = formatter.date(from: value)!
    }
}

extension MoneyWithoutCurrency: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        let amountAsString = "\(value)"
        guard let money = MoneyWithoutCurrency(amountAsString) else {
            fatalError("ERROR: Bad amount: '\(amountAsString)'")
        }
        self = money
    }
}
