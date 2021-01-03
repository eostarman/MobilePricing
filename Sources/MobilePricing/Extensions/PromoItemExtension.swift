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

    public func getUnitDisc(promoCode: PromoCodeRecord, unitPrice: Money, nbrPriceDecimals: Int, unitSplitCaseCharge: Money? = nil) -> Money? {
        if promoRateType == .percentOff {
            // KJQ 2/26/12 ... if a split case charge is involved it has already been rolled into the unitPrice
            // it seems unreasonable for a customer to get a %off a split case charge, so unless it is really a FREE good (e.g. from freebies promo)
            // then the customer gets charged for the split case charge

            let percentOff = getPercentOff()

            if percentOff == 100 { // if it is a true freebie, then no split case charge
                return unitPrice
            }

            var unitPriceLessSplitCaseCharge = unitPrice.withDecimals(nbrPriceDecimals)
            if let unitSplitCaseCharge = unitSplitCaseCharge {
                unitPriceLessSplitCaseCharge -= unitSplitCaseCharge
            }

            let discount = unitPriceLessSplitCaseCharge * (percentOff / 100)

            return discount
        } else if promoRateType == .promoPrice {
            // NOTE: if it really is a promoPrice of $0.00, then it was decided that no split case charge
            // should be applied ... i.e. the item will be absolutely "free".

            if promoRate == 0 {
                return unitPrice
            }

            var unitPriceLessSplitCaseCharge = unitPrice.withDecimals(nbrPriceDecimals)
            if let unitSplitCaseCharge = unitSplitCaseCharge {
                unitPriceLessSplitCaseCharge -= unitSplitCaseCharge
            }

            let promoPrice = getPromoPrice(currency: promoCode.currency)

            if promoPrice > unitPriceLessSplitCaseCharge {
                return nil
            }

            let discount = unitPriceLessSplitCaseCharge - promoPrice

            return discount
        } else if promoRateType == .amountOff {
            let amountOff = getAmountOff(currency: promoCode.currency)
            return amountOff
        } else {
            return nil
        }
    }
}