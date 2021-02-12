//
//  FrontlinePriceService.swift
//  MobileBench (iOS)
//
//  Created by Michael Rutherford on 7/29/20.
//
// compute frontline prices

import Foundation
import MobileDownload
import MoneyAndExchangeRates

/// Get a customer's front-line price (before any discounts, deposits or taxes). This ties together the DefaultPriceService, the PriceSheetService and the SpecialPriceService
public struct FrontlinePriceService {
    let shipFrom: WarehouseRecord
    let sellToCustomer: CustomerRecord
    let pricingParent: CustomerRecord
    let pricingDate: Date
    let transactionCurrency: Currency
    let numberOfDecimals: Int
    
    var priceSheetService: PriceSheetService
    var priceSheetServiceForDeposits: PriceSheetService
    
    /// The front-line price is a function of which warehouse ships the product (potentially), which customer is buying the product, when they are getting the product (deliveer-date rather than order-date). It will be converted to
    /// the transaction currency (the currency of the order) and the number of decimals (e.g. dairies and bakeries in the U.S. sell to schools and hospitals in fractions of a penny)
    public init(shipFrom: WarehouseRecord, sellTo: CustomerRecord, pricingDate: Date, transactionCurrency: Currency, numberOfDecimals: Int) {
        self.shipFrom = shipFrom
        self.sellToCustomer = sellTo
        self.pricingParent = mobileDownload.customers[sellTo.pricingParentNid ?? sellTo.recNid]
        self.pricingDate = pricingDate
        self.transactionCurrency = transactionCurrency
        self.numberOfDecimals = numberOfDecimals
        
        priceSheetService = PriceSheetService(shipFrom, sellTo, pricingDate, isDepositSchedule: false)
        priceSheetServiceForDeposits = PriceSheetService(shipFrom, sellTo, pricingDate, isDepositSchedule: true)
    }
    
    enum FrontlinePrice {
        case specialPriceForCustomer(price: Money)
        case fromPriceSheet(priceSheetPrice: PriceSheetService.PriceSheetPrice)
        case itemDefaultPrice(price: Money)
        
        var price: Money {
            switch self {
            case .specialPriceForCustomer(let price):
                return price
            case .itemDefaultPrice(let price):
                return price
            case .fromPriceSheet(let priceSheetPrice):
                return priceSheetPrice.price
            }
        }
    }
    
    /// Get the price of an item on an order (in the context of the entire order - the trigger quantities)
    /// - Parameters:
    ///   - itemNid: the item being priced
    ///   - triggerQuantities: Quantities being sold on the order (excluding any pickups - those are different from a sale)
    /// - Returns: front-line price (either from the customer's special price for the item, from a price sheet or from the item's default price)
    func getPrice(_ priceSheetOrDepositService: PriceSheetService, _ item: ItemRecord, triggerQuantities: TriggerQtys) -> FrontlinePrice? {
        if let specialPrice = SpecialPriceService.getCustomerSpecialPrice(sellToCustomer, item, pricingDate) {
            return .specialPriceForCustomer(price: specialPrice)
        }
        
        if let priceSheetPrice = priceSheetOrDepositService.getPrice(item, triggerQuantities: triggerQuantities, transactionCurrency: transactionCurrency) {
            return .fromPriceSheet(priceSheetPrice: priceSheetPrice)
        }
        
        if let itemDefaultPrice = DefaultPriceService.getDefaultPrice(item, pricingDate) {
            return .itemDefaultPrice(price: itemDefaultPrice.withCurrency(.USD))
        }
        
        return nil
    }
    
    /// Get the lowest (best for the customer) frontline price for an item that's being sold to a customer on a date (based on the delivery date). If there's a special price for the customer then that'll be used. If not, then the price books will be checked. Otherwise, the default prices on the item record will be used.
    /// - Parameter itemNid: the item (or alt pack) to get the price for. Note that split-case charges are not handled here
    /// - Returns: the price (with the currency set to the current transaction currency based on the exchange rates) or nil if there is *no* frontline price
    public func getPrice(_ item: ItemRecord) -> Money? {
        guard let frontlinePrice = getPrice(priceSheetService, item, triggerQuantities: [:]) else {
            return nil
        }
        
        let price = frontlinePrice.price.converted(to: transactionCurrency, withDecimals: numberOfDecimals)

        return price
    }
    
    /// Return the deposit from the customer's special price information, or from the deposit "schedules" or by using the item's default price.
    /// - Parameters:
    ///   - item: The item or empty
    ///   - isEmptyOrDunnage: (item.isEmpty || item.isDunnage) && !item.isKeg (kegs can be sold, so don't use the customer's special price or the item's default price as a deposit
    /// - Returns: nil or the deposit (converted to the transactionCurrency)
    public func getDeposit(_ item: ItemRecord, isEmptyOrDunnage: Bool) -> Money? {
        
        // note: if the item is an empty or dunnage then the bottler never sells these - so, we can use the "price" of the item as its deposit
        // For kegs, the bottler *may* sell them directly to the retailer, so we can't trust that their price is a deposit - it may be what you sell the (empty) keg for
        if isEmptyOrDunnage {
            if let specialPriceInterpretedAsTheDeposit = SpecialPriceService.getCustomerSpecialPrice(sellToCustomer, item, pricingDate) {
                return specialPriceInterpretedAsTheDeposit.converted(to: transactionCurrency, withDecimals: numberOfDecimals)
            }
        }
        
        if let depositFromTheDepositSchedules = priceSheetServiceForDeposits.getPrice(item, triggerQuantities: [:], transactionCurrency: transactionCurrency) {
            return depositFromTheDepositSchedules.price.converted(to: transactionCurrency, withDecimals: numberOfDecimals)
        }
        
        if isEmptyOrDunnage {
            if let itemDefaultPriceInterpretedAsTheDeposit = DefaultPriceService.getDefaultPrice(item, pricingDate) {
                return itemDefaultPriceInterpretedAsTheDeposit.withCurrency(mobileDownload.handheld.defaultCurrency).converted(to: transactionCurrency, withDecimals: numberOfDecimals)
            }
        }
        
        return nil
    }
}
