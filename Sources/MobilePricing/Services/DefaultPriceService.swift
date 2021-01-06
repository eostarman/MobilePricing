//
//  File.swift
//  
//
//  Created by Michael Rutherford on 1/2/21.
//

import Foundation
import MobileDownload
import MoneyAndExchangeRates

/// Each item can have a default price. This price is used unless a price sheet or customer special price is found.
struct DefaultPriceService {

    /// This gets the default price from the item record, if there is one
    static func getDefaultPrice(_ item: ItemRecord, date: Date) -> MoneyWithoutCurrency? {

        // see FrontlinePriceCalculator.cs
        if let defaultPrice2EffectiveDate = item.defaultPrice2EffectiveDate, let defaultPrice2 = item.defaultPrice2, date >= defaultPrice2EffectiveDate {
           return defaultPrice2
        } else if let defaultPriceEffectiveDate = item.defaultPriceEffectiveDate, let defaultPrice = item.defaultPrice, date >= defaultPriceEffectiveDate {
            return defaultPrice
        } else if let defaultPricePrior = item.defaultPricePrior {
            return defaultPricePrior
        } else {
            return item.defaultPrice
        }
    }
}
