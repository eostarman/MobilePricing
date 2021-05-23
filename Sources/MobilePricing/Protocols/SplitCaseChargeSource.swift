//
//  File.swift
//  
//
//  Created by Michael Rutherford on 5/22/21.
//

import Foundation
import MoneyAndExchangeRates

public protocol SplitCaseChargeSource {
    var id: UUID { get }
    var itemNid: Int { get }
    var qtyShippedOrExpectedToBeShipped: Int { get }
    var qtyFree: Int { get }
    var unitPrice: MoneyWithoutCurrency? { get }
    
    var charges: [LineItemCharge] { get set }
}
