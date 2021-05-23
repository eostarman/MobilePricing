//  Created by Michael Rutherford on 2/12/21.

import Foundation
import MobileDownload
import MoneyAndExchangeRates

// mpr: note SplitCaseChargeCalculator.cs may be charging split case charges for pallets (although that is unlikely? to come up)
public struct SplitCaseChargeService {
    
    /// calculate split-case charges for an order-line. If an item is priced per-case (typically inexpensive wine), but a customer would like to buy 2 single bottles, the distributor will charge the customer for "splitting the case". This is
    /// called after computing free goods and discounts since it's suppressed for free-goods
    public static func computeSplitCaseCharges(deliveryDate: Date, transactionCurrency: Currency, orderLines: [SplitCaseChargeSource]) {
        // sort them so that the most recent effective date is found first for an item
        let allSplitCaseChargeRecords = mobileDownload.splitCaseCharges.getAll().sorted { $0.effectiveDate ?? .distantPast > $1.effectiveDate ?? .distantPast}
        
        if allSplitCaseChargeRecords.isEmpty {
            return
        }
        
        for var orderLine in orderLines {
            
            let item = mobileDownload.items[orderLine.itemNid]
            var splitCaseCharge: MoneyWithoutCurrency = .zero
            
            // we don't compute the split-case charge on samples (with a zero-price) or on product returns
            if orderLine.qtyShippedOrExpectedToBeShipped > 0,
               orderLine.qtyShippedOrExpectedToBeShipped != orderLine.qtyFree,
               let unitPrice = orderLine.unitPrice,
               unitPrice > .zero {
                
                for record in allSplitCaseChargeRecords {
                    
                    if let charge = record.getCharge(item: item, altPackUnitPrice: unitPrice, deliveryDate: deliveryDate, transactionCurrency: transactionCurrency) {
                        splitCaseCharge = charge
                        break
                    }
                }
            }
            
            if getCurrentSplitCaseCharge(orderLine: orderLine) != splitCaseCharge {
                orderLine.charges = chargesWithNewSplitCaseCharge(orderLine: orderLine, splitCaseCharge: splitCaseCharge)
            }
        }
    }
}

fileprivate func getCurrentSplitCaseCharge(orderLine: SplitCaseChargeSource) -> MoneyWithoutCurrency {
    var splitCaseCharge: MoneyWithoutCurrency = .zero
    for charge in orderLine.charges {
        switch charge {
        case .splitCaseCharge(let amount):
            splitCaseCharge += amount
        default:
            break
        }
    }
    
    return splitCaseCharge
}

fileprivate func chargesWithNewSplitCaseCharge(orderLine: SplitCaseChargeSource, splitCaseCharge: MoneyWithoutCurrency) -> [LineItemCharge] {
    
    var newCharges: [LineItemCharge] = []
    
    for charge in orderLine.charges {
        switch charge {
        case .splitCaseCharge(amount: ):
            break
        default:
            newCharges.append(charge)
        }
    }
    
    if splitCaseCharge > .zero {
        newCharges.append(.splitCaseCharge(amount: splitCaseCharge))
    }
    
    return newCharges
}

fileprivate extension SplitCaseChargeRecord {
    /// return true if the item should get a split-case charge
    /// 1. the split case charge is applicable on the deliveryDate (the salesHistoryDate in c#)
    /// 2. the frontLine price does not exceed the cutoffPrice (if any) - i.e. if the wine is expensive, it's okay to split the case and buy 1 bottl
    /// 3. the item is a fraction of the primary pack (e.g. buying the case or a pallet is okay)
    /// 4. the item's primary pack is covered by this rule
    func getCharge(item: ItemRecord, altPackUnitPrice: MoneyWithoutCurrency, deliveryDate: Date, transactionCurrency: Currency) -> MoneyWithoutCurrency? {
        if let effectiveDate = effectiveDate, deliveryDate < effectiveDate {
            return nil
        }
        
        if let cutoffPrice = cutoffPrice, !cutoffPrice.isZero, altPackUnitPrice > cutoffPrice {
            return nil
        }
        
        if item.altPackFamilyNid == item.recNid || !item.altPackIsFractionOfPrimaryPack || item.altPackCasecount <= 1 {
            return nil
        }
        
        guard let productSetNid = productSetNid else {
            return nil
        }
        
        let productSet = mobileDownload.productSets[productSetNid]
        if !productSet.altPackFamilyNids.contains(item.altPackFamilyNid) {
            return nil
        }
        
        let rawCharge: MoneyWithoutCurrency
        
        if isPerAltPackCharge {
            rawCharge = amount
        } else {
            rawCharge = amount.divided(by: item.altPackCasecount, numberOfDecimals: transactionCurrency.numberOfDecimals)
        }
        
        let charge = rawCharge.converted(to: transactionCurrency, numberOfDecimals: transactionCurrency.numberOfDecimals, from: mobileDownload.handheld.defaultCurrency)
        
        return charge
    }
}
