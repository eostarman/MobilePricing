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
    let shipFromWhseNid: Int
    let cusNid: Int
    let pricingParentNid: Int
    let date: Date
    let transactionCurrency: Currency
    let numberOfDecimals: Int

    var priceSheetService: PriceSheetService

    /// The front-line price is a function of which warehouse ships the product (potentially), which customer is buying the product, when they are getting the product (deliveer-date rather than order-date). It will be converted to
    /// the transaction currency (the currency of the order) and the number of decimals (e.g. dairies and bakeries in the U.S. sell to schools and hospitals in fractions of a penny)
    public init(shipFromWhseNid: Int, cusNid: Int, date: Date, transactionCurrency: Currency, numberOfDecimals: Int) {
        self.shipFromWhseNid = shipFromWhseNid
        self.cusNid = cusNid
        pricingParentNid = mobileDownload.customers[cusNid].pricingParentNid ?? cusNid
        self.date = date
        self.transactionCurrency = transactionCurrency
        self.numberOfDecimals = numberOfDecimals

        priceSheetService = PriceSheetService(shipFromWhseNid: shipFromWhseNid, cusNid: cusNid, date: date, isDepositSchedule: false)
    }

    func getPriceWithDescription(itemNid: Int) -> PriceWithDescription? {
        if let specialPrice = SpecialPriceService.getCustomerSpecialPrice(cusNid: cusNid, itemNid: itemNid, date: date) {
            return PriceWithDescription(price: specialPrice) { "Special price for customer" }
        }

        if let priceBookPrice = priceSheetService.getBestPriceFromPriceSheets(itemNid: itemNid) {
            return priceBookPrice
        }

        if let itemDefaultPrice = DefaultPriceService.getDefaultPrice(itemNid: itemNid, date: date) {
            return PriceWithDescription(price: itemDefaultPrice.withCurrency(.USD)) { "default price for item" }
        }

        return nil
    }

    /// Get the lowest (best for the customer) frontline price for an item that's being sold to a customer on a date (based on the delivery date). If there's a special price for the customer then that'll be used; if not, then the price books will be checked. Otherwise, the default prices on the item record will be used.
    /// - Parameter itemNid: the item (or alt pack) to get the price for. Note that split-case charges are not handled here
    /// - Returns: the price (with the currency set to the current transaction currency based on the exchange rates) or nil if there is *no* frontline price
    public func getPrice(itemNid: Int) -> Money? {
        guard let priceWithDescription = getPriceWithDescription(itemNid: itemNid) else {
            return nil
        }

        let price = priceWithDescription.price

        if price.currency != transactionCurrency {
            guard let convertedPrice = mobileDownload.handheld.exchangeRates.getMoney(from: price, to: transactionCurrency, date: date) else {
                return nil
            }

            let roundedPrice = convertedPrice.withDecimals(numberOfDecimals)
            return roundedPrice
        }

        return price
    }
}
