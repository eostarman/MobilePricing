//
//  File.swift
//  
//
//  Created by Michael Rutherford on 5/23/21.
//

import Foundation
import MobileDownload
import MoneyAndExchangeRates

public struct LineItemDiscount: Equatable {
    public init(promoPlan: ePromoPlan, promoSectionNid: Int?, unitDisc: MoneyWithoutCurrency, rebateAmount: MoneyWithoutCurrency) {
        self.promoPlan = promoPlan
        self.promoSectionNid = promoSectionNid
        self.unitDisc = unitDisc
        self.rebateAmount = rebateAmount
    }
    
    public let promoPlan: ePromoPlan
    public let promoSectionNid: Int?
    public let unitDisc: MoneyWithoutCurrency
    public let rebateAmount: MoneyWithoutCurrency
}
