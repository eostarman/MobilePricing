//
//  File.swift
//  
//
//  Created by Michael Rutherford on 5/23/21.
//

import Foundation
import MoneyAndExchangeRates

public struct LineItemFreeGoods: Equatable {
    public init(promoSectionNid: Int?, qtyFree: Int, rebateAmount: MoneyWithoutCurrency) {
        self.promoSectionNid = promoSectionNid
        self.qtyFree = qtyFree
        self.rebateAmount = rebateAmount
    }
    
    public let promoSectionNid: Int?
    public let qtyFree: Int
    public let rebateAmount: MoneyWithoutCurrency
}
