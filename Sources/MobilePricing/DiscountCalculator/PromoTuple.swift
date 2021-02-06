//  Created by Michael Rutherford on 1/24/21.

import Foundation
import MoneyAndExchangeRates

/// track the DCPromoSection and the PromoDiscount it produced
struct PromoTuple {
    let dcPromoSection: DCPromoSection
    
    let dcOrderLine: IDCOrderLine
    
    let qtyDiscounted: Int
    let unitDisc: MoneyWithoutCurrency
    let rebateAmount: MoneyWithoutCurrency
    
    var isFromBuyXGetYFreePromo: Bool {
        dcPromoSection.promoSectionRecord.isBuyXGetY
    }
    
    init(dcPromoSection: DCPromoSection, promoDiscount: PromoDiscount) {
        self.dcPromoSection = dcPromoSection
        self.dcOrderLine = promoDiscount.dcOrderLine
        self.qtyDiscounted = promoDiscount.qtyDiscounted
        self.unitDisc = promoDiscount.unitDisc
        self.rebateAmount = promoDiscount.rebateAmount
    }
}
