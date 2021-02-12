//
//  File.swift
//  
//
//  Created by Michael Rutherford on 2/10/21.
//

import MobileDownload
import MoneyAndExchangeRates

struct CRVService {
    
    static func GetItemCRV(customer: CustomerRecord, item: ItemRecord, orderTypeNid: Int?) -> (Money, Int)? {
        
//        if !mobileDownload.handheld.isCaliforniaTaxPluginInstalled { - not needed
//            return nil
//        }
        
        if customer.isWholesaler {
            return nil
        }
        
        if customer.exemptFromCRVCharges {
            return nil
        }
        
        let primaryPack = mobileDownload.items[item.altPackFamilyNid]
        
        // BUG: in MobileCache.cs:GetItemCRV() the item is used to get unitsPerPack and packsPerCase rather than the primary pack
        
        guard let crvContainerTypeNid = primaryPack.crvContainerTypeNid, let crvAmountPerBottleOrCan = mobileDownload.crvContainerTypes[crvContainerTypeNid].taxRate else {
            return nil
        }
        
        if let recNid = orderTypeNid, mobileDownload.orderTypes[recNid].doNotChargeCrv {
            return nil
        }
 
        if customer.shipState.caseInsensitiveCompare("CA") != .orderedSame {
            return nil
        }
        
        let primaryPackCRVAmount = crvAmountPerBottleOrCan * (primaryPack.unitsPerPack * primaryPack.packsPerCase)
        let crvAmount: MoneyWithoutCurrency
        
        if item.altPackCasecount == 1 {
            crvAmount = primaryPackCRVAmount
        } else if item.altPackIsFractionOfPrimaryPack {
            crvAmount = primaryPackCRVAmount.divided(by: item.altPackCasecount, numberOfDecimals: 2)
        } else {
            crvAmount = primaryPackCRVAmount * item.altPackCasecount
        }
        
        let pair = (crvAmount.withCurrency(.USD), crvContainerTypeNid)
        return pair
    }
}
