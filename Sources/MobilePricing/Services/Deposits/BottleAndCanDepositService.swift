//
//  File.swift
//  
//
//  Created by Michael Rutherford on 2/10/21.
//

import MobileDownload
import MoneyAndExchangeRates

struct BottleAndCanDepositService {
    /// get the bottle or can deposit for this item.
    static func getBottleOrCanDeposit(customer: CustomerRecord, item: ItemRecord) -> Money {
        let currency = mobileDownload.handheld.defaultCurrency
        let primaryPack = mobileDownload.items[item.altPackFamilyNid]
        
        if customer.chargeOnlySupplierDeposits && !primaryPack.depositIsSupplierOriginated { // c# uses item.depositIsSupplierOriginated
            return currency.zero
        }
        
        if let bottleOrCanDepositFromItem = (customer.chargeOnlySupplierDeposits ? item.supplierDeposit : item.deposit) {
            return bottleOrCanDepositFromItem.withCurrency(currency)
        }
        
        // c# checks the item.altPackCasecount being (1), but an alt-pack can have a casecount of (1)
        
        var bottleOrCanDeposit = (customer.chargeOnlySupplierDeposits ? primaryPack.supplierDeposit : primaryPack.deposit) ?? .zero
        
        if item.altPackIsFractionOfPrimaryPack {
            bottleOrCanDeposit = bottleOrCanDeposit.divided(by: item.altPackCasecount, numberOfDecimals: currency.numberOfDecimals)
        } else { // e.g. a pallet
            bottleOrCanDeposit = bottleOrCanDeposit * item.altPackCasecount
        }
        
        return bottleOrCanDeposit.withCurrency(currency)
    }
}

