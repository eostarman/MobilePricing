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

func testRecord<T: Record>(recNid: Int) -> T {
    var record = T()
    record.recNid = recNid
    record.recKey = "\(recNid)"
    record.recName = "\(T.self) #\(recNid)"
    return record
}

func testWarehouse(whseNid: Int) -> WarehouseRecord { mobileDownload.warehouses.add(testRecord(recNid: whseNid)) }
func testItem(itemNid: Int) -> ItemRecord { mobileDownload.items.add(testRecord(recNid: itemNid)) }
func testCustomer(cusNid: Int) -> CustomerRecord { mobileDownload.customers.add(testRecord(recNid: cusNid)) }
func testPriceSheet(priceSheetNid: Int) -> PriceSheetRecord { mobileDownload.priceSheets.add(testRecord(recNid: priceSheetNid)) }

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

enum TestError : Error {
    case badAmount(String)
}

func USD(_ amount: Double) -> Money {
    let amountAsString = "\(amount)"

    guard let money = MoneyWithoutCurrency("\(amount)") else {
        fatalError("ERROR: Bad amount: '\(amountAsString)'")
    }
    return money.withCurrency(.USD)
}
