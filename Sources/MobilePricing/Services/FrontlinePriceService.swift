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

/// Get a customer's front-line price (before any discounts, deposits or taxes)
public struct FrontlinePriceService {
    let shipFrom: WarehouseRecord
    let sellTo: CustomerRecord
    let pricingParent: CustomerRecord
    let pricingDate: Date
    let transactionCurrency: Currency
    let numberOfDecimals: Int

    var priceSheetService: PriceSheetService

    /// The front-line price is a function of which warehouse ships the product (potentially), which customer is buying the product, when they are getting the product (deliveer-date rather than order-date). It will be converted to
    /// the transaction currency (the currency of the order) and the number of decimals (e.g. dairies and bakeries in the U.S. sell to schools and hospitals in fractions of a penny)
    public init(shipFrom: WarehouseRecord, sellTo: CustomerRecord, pricingDate: Date, transactionCurrency: Currency, numberOfDecimals: Int) {
        self.shipFrom = shipFrom
        self.sellTo = sellTo
        self.pricingParent = mobileDownload.customers[sellTo.pricingParentNid ?? sellTo.recNid]
        self.pricingDate = pricingDate
        self.transactionCurrency = transactionCurrency
        self.numberOfDecimals = numberOfDecimals

        priceSheetService = PriceSheetService(shipFrom: shipFrom, sellTo: sellTo, pricingDate: pricingDate, isDepositSchedule: false)
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
    func getPrice(_ item: ItemRecord, triggerQuantities: TriggerQtys) -> FrontlinePrice? {
        if let specialPrice = SpecialPriceService.getCustomerSpecialPrice(sellTo: sellTo, item, pricingDate: pricingDate) {
            return .specialPriceForCustomer(price: specialPrice)
        }

        if let priceSheetPrice = priceSheetService.getPrice(item, triggerQuantities: triggerQuantities, transactionCurrency: transactionCurrency) {
            return .fromPriceSheet(priceSheetPrice: priceSheetPrice)
        }

        if let itemDefaultPrice = DefaultPriceService.getDefaultPrice(item, pricingDate: pricingDate) {
            return .itemDefaultPrice(price: itemDefaultPrice.withCurrency(.USD))
        }

        return nil
    }

    /// Get the lowest (best for the customer) frontline price for an item that's being sold to a customer on a date (based on the delivery date). If there's a special price for the customer then that'll be used; if not, then the price books will be checked. Otherwise, the default prices on the item record will be used.
    /// - Parameter itemNid: the item (or alt pack) to get the price for. Note that split-case charges are not handled here
    /// - Returns: the price (with the currency set to the current transaction currency based on the exchange rates) or nil if there is *no* frontline price
    public func getPrice(_ item: ItemRecord) -> Money? {
        guard let frontlinePrice = getPrice(item, triggerQuantities: [:]) else {
            return nil
        }

        let price = frontlinePrice.price

        if price.currency != transactionCurrency {
            guard let convertedPrice = mobileDownload.handheld.exchangeRates.getMoney(from: price, to: transactionCurrency, date: pricingDate) else {
                return nil
            }

            let roundedPrice = convertedPrice.withDecimals(numberOfDecimals)
            return roundedPrice
        }

        return price
    }
}
