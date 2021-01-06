//
//  File.swift
//  
//
//  Created by Michael Rutherford on 1/2/21.
//

import Foundation
import MobileDownload
import MoneyAndExchangeRates

struct SpecialPriceService {

    /// Customers can have special prices assigned to them (based on dates). So, if they buy that item for delivery within the given dates, then they *will* get that front-line price. The currency is based on the customer's transactionCurrency
    static func getCustomerSpecialPrice(sellTo: CustomerRecord, _ item: ItemRecord, pricingDate: Date) -> Money? {
        let itemNid = item.recNid
        let pricingParent = mobileDownload.customers[sellTo.pricingParentNid ?? sellTo.recNid]

        guard let specialPrices = pricingParent.specialPrices else {
            return nil
        }

        var mostRecentSpecialPrice: SpecialPrice?

        for special in specialPrices {
            if special.isPriceActive(date: pricingDate), special.itemNid == itemNid {
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
        let currency = pricingParent.transactionCurrency
        let price = s.price.withCurrency(currency)

        return price
    }
}
