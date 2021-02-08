//  Created by Michael Rutherford on 1/24/21.

import Foundation
import MoneyAndExchangeRates
import MobileDownload

/// track the DCPromoSection and the PromoDiscount it produced
public struct PromoTuple {
    let promoSectionRecord: PromoSectionRecord
    let promoDiscount: PromoDiscount
    
    var dcOrderLine: DCOrderLine { promoDiscount.dcOrderLine }
    var qtyDiscounted: Int { promoDiscount.qtyDiscounted }
    var unitDisc: MoneyWithoutCurrency { promoDiscount.unitDisc }
    var rebateAmount: MoneyWithoutCurrency { promoDiscount.rebateAmount }
    
    var isFromBuyXGetYFreePromo: Bool {
        promoSectionRecord.isBuyXGetY
    }
    
    init(promoSectionRecord: PromoSectionRecord, promoDiscount: PromoDiscount) {
        self.promoSectionRecord = promoSectionRecord
        self.promoDiscount = promoDiscount
    }
}
