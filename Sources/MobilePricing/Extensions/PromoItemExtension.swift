//
//  File.swift
//  
//
//  Created by Michael Rutherford on 1/2/21.
//

import Foundation
import MobileDownload
import MoneyAndExchangeRates

extension PromoItem {

    public func getAmountOff(unitPrice: Money) -> Money {
        
        // if the price is zero, then there can be no amount-off
        if unitPrice.isZero {
            return unitPrice
        }

        let promoSection = mobileDownload.promoSections[promoSectionNid]
        let promoCode = mobileDownload.promoCodes[promoSection.promoCodeNid]
        let promoCurrency = promoCode.currency
        let transactionCurrency = unitPrice.currency
        let priceWithoutCurrency = unitPrice.withoutCurrency()
        
        let amountOffWithoutCurrency = getUnitDisc(promoCurrency: promoCurrency, transactionCurrency: transactionCurrency, frontlinePrice: priceWithoutCurrency, nbrPriceDecimals: 4)
        
        let amountOff = amountOffWithoutCurrency.withCurrency(unitPrice.currency)
        return amountOff
    }
    
    /// get the discount amount applying this promoItem (percent-off, amount-off or fixed-price) to the unitPrice (after converting from the promoCurrency to the transactionCurrency)
    /// - Parameters:
    ///   - promoCurrency: the currency for the promotion (this promoItem is assigned to a promoSection, and a promoCode contains one or more promoSections - the currency is defined for the entire promoCode for all promoSections)
    ///   - transactionCurrency: the currency for the transaction (order)
    ///   - frontlinePrice: the price to be discounted. Typically the frontLine price on the order, but for tiered promotions this can be reduced by a lower-tier promotion. This is an amount in the transactionCurrency
    ///   - nbrPriceDecimals: the result is rounded to this number of decimal places (typically 2 or 4 decimals)
    /// - Returns: the discount amount converted to the transactionCurrency using the mobileDownload.exchange service
    public func getUnitDisc(promoCurrency: Currency, transactionCurrency: Currency, frontlinePrice: MoneyWithoutCurrency, nbrPriceDecimals: Int) -> MoneyWithoutCurrency {
        guard frontlinePrice.isPositive else {
            return .zero
        }
        
        if promoRateType == .percentOff {
            // KJQ 2/26/12 ... if a split case charge is involved it has already been rolled into the unitPrice
            // it seems unreasonable for a customer to get a %off a split case charge, so unless it is really a FREE good (e.g. from freebies promo)
            // then the customer gets charged for the split case charge

            let percentOff = getPercentOff()

            if percentOff == 100 { // if it is a true freebie, then no split case charge
                return frontlinePrice
            }

            let discount = frontlinePrice * (percentOff / 100)

            return discount
        } else if promoRateType == .promoPrice {
            // NOTE: if it really is a promoPrice of $0.00, then it was decided that no split case charge
            // should be applied ... i.e. the item will be absolutely "free".

            if promoRate == 0 {
                return frontlinePrice
            }
            
            guard let promoPrice = getPromoPrice().converted(to: transactionCurrency, withDecimals: nbrPriceDecimals, from: promoCurrency) else {
                return .zero
            }

            // if the frontLine price is already lower than the price provided by this promotion, then ignore this promotion
            if promoPrice > frontlinePrice {
                return .zero
            }

            let discount = frontlinePrice - promoPrice

            return discount
        } else if promoRateType == .amountOff {
            guard let amountOff = getAmountOff().converted(to: transactionCurrency, withDecimals: nbrPriceDecimals, from: promoCurrency) else {
                return .zero
            }
            return amountOff
        } else {
            return .zero
        }
    }
}
