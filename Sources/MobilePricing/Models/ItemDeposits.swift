//  Created by Michael Rutherford on 2/9/21.

import Foundation
import MoneyAndExchangeRates

/// all item deposits converted to the transactionCurrency (bottle or can, carrier, bag-credit, state-pickup credit and CRV)
struct ItemDeposits
{
    var unitDeposit: MoneyWithoutCurrency {
        bottleOrCanDeposit + kegDeposit + carrierDeposit + bagCredit + statePickupCredit
    }
    
    // in c#, we roll the keg deposit into the bottleOrCanDeposit - but, it makes more sense to separated them (we still need to add them for SQL storage). We can repopulate it from a dbo.OrderLine with an IsKeg item with a bottleOrCanDeposit
    var bottleOrCanDeposit: MoneyWithoutCurrency = .zero
    var kegDeposit: MoneyWithoutCurrency = .zero
    
    var carrierDeposit: MoneyWithoutCurrency = .zero
    var bagCredit: MoneyWithoutCurrency = .zero
    var statePickupCredit: MoneyWithoutCurrency = .zero
    var unitCRV: MoneyWithoutCurrency = .zero
    var crvContainerTypeNid: Int? = nil
    
    internal init(transactionCurrency: Currency, bottleOrCanDeposit: Money?, kegDeposit: Money?, carrierDeposit: Money?, bagCredit: Money?, statePickupCredit: Money?, unitCRV: Money?, crvContainerTypeNid: Int?) {
        func converted(_ amount: Money?) -> MoneyWithoutCurrency {
            amount?.converted(to: transactionCurrency)?.withoutCurrency() ?? .zero
        }
        
        self.bottleOrCanDeposit = converted(bottleOrCanDeposit)
        self.kegDeposit = converted(kegDeposit)
        self.carrierDeposit = converted(carrierDeposit)
        self.bagCredit = converted(bagCredit)
        self.statePickupCredit = converted(statePickupCredit)
        
        // mpr: it's odd to convert the CRV (California Redemption Value) to anything other than .USD, but it's okay
        self.unitCRV = converted(unitCRV)
        self.crvContainerTypeNid = crvContainerTypeNid
    }
    
    internal init() {
    }
    
    func lineItemCharges() -> [LineItemCharge] {
        var charges: [LineItemCharge] = []
        
        if bottleOrCanDeposit.isPositive {
            charges.append(.bottleOrCanDeposit(amount: bottleOrCanDeposit))
        }
        
        if kegDeposit.isPositive {
            charges.append(.kegDeposit(amount: kegDeposit))
        }
        
        if carrierDeposit.isPositive {
            charges.append(.carrierDeposit(amount: carrierDeposit))
        }
        
        if let crvContainerTypeNid = crvContainerTypeNid, unitCRV.isPositive {
            charges.append(.CRV(amount: unitCRV, crvContainerTypeNid: crvContainerTypeNid))
        }
        
        return charges
    }
    
    func lineItemCredits() -> [LineItemCredit] {
        var credits: [LineItemCredit] = []
        
        if bagCredit.isPositive {
            credits.append(.bagCredit(amount: bagCredit))
        }
        
        if statePickupCredit.isPositive {
            credits.append(.statePickupCredit(amount: statePickupCredit))
        }
        
        return credits
    }
}

