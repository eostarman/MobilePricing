//  Created by Michael Rutherford on 2/11/21.

import MoneyAndExchangeRates

/// charges (deposits, taxes and additional fees) added to an order line
public enum LineItemCharge: Equatable {
    case bottleOrCanDeposit(amount: MoneyWithoutCurrency)
    case kegDeposit(amount: MoneyWithoutCurrency)
    case carrierDeposit(amount: MoneyWithoutCurrency)
    case CRV(amount: MoneyWithoutCurrency, crvContainerTypeNid: Int?)
    case tax(amount: MoneyWithoutCurrency, promoSectionNid: Int)
    case fee(amount: MoneyWithoutCurrency, promoSectionNid: Int)
    case splitCaseCharge(amount: MoneyWithoutCurrency)
    
    public var amount: MoneyWithoutCurrency {
        switch self {
        
        case .CRV(let amount, _): return amount
        case .bottleOrCanDeposit(let amount): return amount
        case .carrierDeposit(let amount): return amount
        case .fee(let amount, _): return amount
        case .kegDeposit(let amount): return amount
        case .tax(let amount, _): return amount
        case .splitCaseCharge(let amount): return amount
        }
    }
    
}
