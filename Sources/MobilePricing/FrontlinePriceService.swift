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
    let specialPrices: [SpecialPrice]?

    var priceSheetService: PriceSheetService

    /// The front-line price is a function of which warehouse ships the product (potentially), which customer is buying the product, when they are getting the product (deliveer-date rather than order-date). It will be converted to
    /// the transaction currency (the currency of the order) and the number of decimals (e.g. dairies and bakeries in the U.S. sell to schools and hospitals in fractions of a penny)
    public init(shipFromWhseNid: Int, cusNid: Int, date: Date, transactionCurrency: Currency, numberOfDecimals: Int) {
        self.shipFromWhseNid = shipFromWhseNid
        self.cusNid = cusNid
        pricingParentNid = mobileDownload.customers[cusNid].pricingParentNid
        self.date = date
        self.transactionCurrency = transactionCurrency
        self.numberOfDecimals = numberOfDecimals

        specialPrices = mobileDownload.customers[pricingParentNid].specialPrices

        priceSheetService = PriceSheetService(shipFromWhseNid: shipFromWhseNid, cusNid: cusNid, date: date, isDepositSchedule: false)
    }

    /// When the customer gets a front-line price (a price before discounting), then it's nice to know where that came from. So, this is the price and the description of the source of the price
    public struct PriceWithDescription {
        var price: Money
        var description: () -> String
    }

    /// This gets the default price from the item record, if there is one
    private func getItemDefaultPrice(itemNid: Int) -> PriceWithDescription? {
        let item = mobileDownload.items[itemNid]

        // see FrontlinePriceCalculator.cs
        if let defaultPrice2EffectiveDate = item.defaultPrice2EffectiveDate {
            if date >= defaultPrice2EffectiveDate {
                if let price = item.defaultPrice2 {
                    return PriceWithDescription(price: price.withCurrency(.USD)) { "item default price effective \(defaultPrice2EffectiveDate)" }
                }
            }
        } else if let defaultPriceEffectiveDate = item.defaultPriceEffectiveDate {
            if date >= defaultPriceEffectiveDate {
                if let price = item.defaultPrice {
                    return PriceWithDescription(price: price.withCurrency(.USD)) { "item default price effective \(defaultPriceEffectiveDate)" }
                }
            }
        } else if let price = item.defaultPricePrior ?? item.defaultPrice {
            return PriceWithDescription(price: price.withCurrency(.USD)) { "item default price" }
        }

        return nil
    }

    /// Customers can have special prices assigned to them (based on dates). So, if they buy that item for delivery within the given dates, then they *will* get that front-line price
    private func getCustomerSpecialPrice(itemNid: Int) -> PriceWithDescription? {
        guard let specialPrices = specialPrices else {
            return nil
        }

        var mostRecentSpecialPrice: SpecialPrice?

        for special in specialPrices {
            if special.isPriceActive(date: date), special.itemNid == itemNid {
                if let prior = mostRecentSpecialPrice {
                    if special.startDate > prior.startDate {
                        mostRecentSpecialPrice = special
                    }
                } else {
                    mostRecentSpecialPrice = special
                }
            }
        }

        guard let s = mostRecentSpecialPrice else {
            return nil
        }
        let currency = mobileDownload.customers[pricingParentNid].transactionCurrency
        let price = s.price.withCurrency(currency)

        return PriceWithDescription(price: price) { "Special price " }
    }

    private func getPriceBookPrice(itemNid: Int) -> PriceWithDescription? {
        let allPricesFromPriceBooks = priceSheetService.getPrices(itemNid: itemNid)

        guard let tuple = allPricesFromPriceBooks.first else {
            return nil
        }

        let priceSheetLink = tuple.0
        let price = tuple.1

        let pwd = PriceWithDescription(price: price) {
            let priceSheet = priceSheetLink.priceSheet
            let priceBook = mobileDownload.priceBooks[priceSheet.priceBookNid]

            return "\(priceBook.recName)"
        }

        return pwd
    }

    public func getPriceWithDescription(itemNid: Int) -> PriceWithDescription? {
        if let specialPrice = getCustomerSpecialPrice(itemNid: itemNid) {
            return specialPrice
        }

        if let priceBookPrice = getPriceBookPrice(itemNid: itemNid) {
            return priceBookPrice
        }

        if let itemDefaultPrice = getItemDefaultPrice(itemNid: itemNid) {
            return itemDefaultPrice
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
