//
//  File.swift
//  
//
//  Created by Michael Rutherford on 1/2/21.
//

import Foundation
import MobileDownload
import MoneyAndExchangeRates

struct CustomerSpecialPriceService {

    /// Customers can have special prices assigned to them (based on dates). So, if they buy that item for delivery within the given dates, then they *will* get that front-line price. The currency is based on the customer's transactionCurrency
    static func getCustomerSpecialPrice(cusNid: Int, itemNid: Int, date: Date) -> Money? {
        var customer = mobileDownload.customers[cusNid]
        if customer.pricingParentNid != cusNid {
            customer = mobileDownload.customers[customer.pricingParentNid]
        }

        guard let specialPrices = customer.specialPrices else {
            return nil
        }

        var mostRecentSpecialPrice: SpecialPrice?

        for special in specialPrices {
            if special.isPriceActive(date: date), special.itemNid == itemNid {
                if let prior = mostRecentSpecialPrice {
                    if special.startDate > prior.startDate {
                        mostRecentSpecialPrice = special
                    }
                } else {
                    mostRecentSpecialPrice = special
                }
            }
        }

        guard let s = mostRecentSpecialPrice else {
            return nil
        }
        let currency = customer.transactionCurrency
        let price = s.price.withCurrency(currency)

        return price
    }
}
