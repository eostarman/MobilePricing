//  Created by Michael Rutherford on 2/9/21.

import Foundation
import MobileDownload
import MoneyAndExchangeRates

// this is based on the code in OrderCalculatorCache.cs:GetItemDepositsAndCRV()
public struct DepositService {
    
    let depositService: FrontlinePriceService
    let customer: CustomerRecord
    let transactionCurrency: Currency
    
    /// when shipping from the warehouse to a customer on a given date, and the transaction currency is the customer's default transaction currency. Also, the number of decimals is the default for the transaction currency (e.g. for dollars, this would be 2)
    init(shipFrom: WarehouseRecord, sellTo: CustomerRecord, pricingDate: Date) {
        self.init(shipFrom: shipFrom, sellTo: sellTo, pricingDate: pricingDate, transactionCurrency: sellTo.transactionCurrency, numberOfDecimals: sellTo.transactionCurrency.numberOfDecimals)
    }
    
    public init(shipFrom: WarehouseRecord, sellTo: CustomerRecord, pricingDate: Date, transactionCurrency: Currency, numberOfDecimals: Int) {
        // this is a FrontlinePriceService, but I'm using it to get deposits
        depositService = FrontlinePriceService(shipFrom: shipFrom, sellTo: sellTo, pricingDate: pricingDate, transactionCurrency: transactionCurrency, numberOfDecimals: numberOfDecimals)
        self.customer = sellTo
        self.transactionCurrency = transactionCurrency
    }
    
    public func applyDeposits(orderLines: [DCOrderLine]) {
        for orderLine in orderLines {
            let itemDeposits = getitemDepositsAndCRV(item: mobileDownload.items[orderLine.itemNid])
            
            for charge in itemDeposits.lineItemCharges() {
                orderLine.addCharge(charge)
            }
            
            for credit in itemDeposits.lineItemCredits() {
                orderLine.addCredit(credit)
            }         
        }
    }
    
    func getitemDepositsAndCRV(item: ItemRecord, orderTypeNid: Int? = nil) -> ItemDeposits {
        
        if customer.doNotChargeDunnageDeposits && item.isDunnage { // this is a Dunnage item and this customer doesn't pay deposits on dunnage (kegs, pallets)
            return ItemDeposits()
        }
        
        var bottleOrCanDeposit: Money? = nil
        var kegDeposit: Money? = nil
        var carrierDeposit: Money? = nil
        var bagCredit: Money? = nil
        var statePickupCredit: Money? = nil
        var unitCRV: Money? = nil
        var crvContainerTypeNid: Int? = nil
        
        let mobileDownloadCurrency = mobileDownload.handheld.defaultCurrency
        
        func getCustomerBagCredit(containerNid: Int) -> Money? {
            let container = mobileDownload.containers[containerNid]
            let bagCredit = customer.useSecondaryContainerDeposits ? container.bagCredit2 : container.bagCredit
            return bagCredit?.withCurrency(customer.transactionCurrency)
        }
        
        func getCustomerStatePickupCredit(containerNid: Int) -> Money? {
            let container = mobileDownload.containers[containerNid]
            let statePickupCredit = customer.useSecondaryContainerDeposits ? container.statePickupCredit2 : container.statePickupCredit
            return statePickupCredit?.withCurrency(customer.transactionCurrency)
        }
        
        func getCustomerCarrierDeposit(containerNid: Int) -> Money? {
            if customer.doNotChargeCarrierDeposits {
                return nil
            }
            let container = mobileDownload.containers[containerNid]
            let carrierDeposit = customer.useSecondaryContainerDeposits ? container.carrierDeposit2 : container.carrierDeposit
            return carrierDeposit?.withCurrency(customer.transactionCurrency)
        }
        
        // An empty is a "carrier" ("shell", "hull")
        if (item.isEmpty || item.isDunnage) && !item.isKeg { // kegs can be marked as empties, but we don't want to treat them that way here
            
            // The Coke bottlers (HighCountry e.g.) may want to enter deposits that vary by customer. If they actually do this, then use the customer-specific price as a deposit.
            if let depositFromDepositSchedule = depositService.getDeposit(item, isEmptyOrDunnage: true) {
                bottleOrCanDeposit = depositFromDepositSchedule
                
                if let containerNid = item.containerNid {
                    bagCredit = getCustomerBagCredit(containerNid: containerNid)
                    statePickupCredit = getCustomerStatePickupCredit(containerNid: containerNid)
                }
            } else {
                if customer.chargeOnlySupplierDeposits {
                    bottleOrCanDeposit = item.supplierDeposit?.withCurrency(mobileDownloadCurrency)
                } else {
                    if let containerNid = item.containerNid {
                        carrierDeposit = getCustomerCarrierDeposit(containerNid: containerNid)
                        bagCredit = getCustomerBagCredit(containerNid: containerNid)
                        statePickupCredit = getCustomerStatePickupCredit(containerNid: containerNid)
                        
                        bottleOrCanDeposit = BottleAndCanDepositService.getBottleOrCanDeposit(customer: customer, item: item)
                    } else {
                        bottleOrCanDeposit = item.deposit?.withCurrency(mobileDownloadCurrency)
                    }
                }
            }
        } else {
            if let containerNid = item.containerNid {
                bagCredit = getCustomerBagCredit(containerNid: containerNid)
                statePickupCredit = getCustomerStatePickupCredit(containerNid: containerNid)
                
                // If this item's container has an assigned empty (IsEmpty item), then the pricing logic will automatically produce
                // an OrderLine for this IsEmpty item (which will then get its own Carrier deposit)
                // But only for customers that can be charged carrier deposits
                carrierDeposit = getCustomerCarrierDeposit(containerNid: containerNid)
            }
            
            // passing false to GetCustomerSpecificUnitPrice because in the case of an item that isn't an empty we don't want to count customer specific pricing as a deposit
            if let depositFromDepositSchedule = depositService.getDeposit(item, isEmptyOrDunnage: false) {
                bottleOrCanDeposit = depositFromDepositSchedule
            } else {
                bottleOrCanDeposit = BottleAndCanDepositService.getBottleOrCanDeposit(customer: customer, item: item)
            }
            
            if let (unitCRVx, crvContainerTypeNidx) = CRVService.GetItemCRV(customer: customer, item: item, orderTypeNid: orderTypeNid) {
                unitCRV = unitCRVx
                crvContainerTypeNid = crvContainerTypeNidx
            }
            
            if item.isKeg {
                let warehouse = mobileDownload.warehouses[customer.whseNid]
                
                if warehouse.hasKegDeposit, let warehouseKegDeposit = warehouse.kegDeposit?.withCurrency(mobileDownloadCurrency) {
                    // KJQ 4/1/10 ... per Thu request: Previously, if there was a KegDeposit on the customer's warehouse, then that
                    // deposit was used only if there was not a deposit on the IsKeg item itself. Now if there is a KegDeposit on the
                    // customer's warehouse then that value will override any item specific deposit.
                    kegDeposit = warehouseKegDeposit //A keg is just a giant can
                }
            }
        }
        
        let deposits: ItemDeposits
        
        if customer.doNotChargeDeposits {                                 // this customer pays no deposits whatsoever (except for CRV)
            deposits = ItemDeposits(transactionCurrency: transactionCurrency, bottleOrCanDeposit: nil, kegDeposit: kegDeposit, carrierDeposit: nil, bagCredit: nil, statePickupCredit: nil, unitCRV: unitCRV, crvContainerTypeNid: crvContainerTypeNid)
        } else if customer.isWholesaler, !mobileDownload.handheld.supplierCostIsNotWholesalerPrice {
            deposits = ItemDeposits(transactionCurrency: transactionCurrency, bottleOrCanDeposit: nil, kegDeposit: kegDeposit, carrierDeposit: nil, bagCredit: nil, statePickupCredit: nil, unitCRV: nil, crvContainerTypeNid: nil)
        } else {
            deposits = ItemDeposits(transactionCurrency: transactionCurrency, bottleOrCanDeposit: bottleOrCanDeposit, kegDeposit: kegDeposit, carrierDeposit: carrierDeposit, bagCredit: bagCredit, statePickupCredit: statePickupCredit, unitCRV: unitCRV, crvContainerTypeNid: crvContainerTypeNid)
        }
        
        return deposits
    }
}
