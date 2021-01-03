//
//  File.swift
//  
//
//  Created by Michael Rutherford on 1/2/21.
//

import Foundation
import MoneyAndExchangeRates

/// When the customer gets a front-line price (a price before discounting), then it's nice to know where that came from. So, this is the price and the description of the source of the price
public struct PriceWithDescription {
    var price: Money
    var description: () -> String
}
