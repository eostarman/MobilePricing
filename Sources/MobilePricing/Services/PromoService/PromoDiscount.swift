//  Created by Michael Rutherford on 1/23/21.

import Foundation
import MoneyAndExchangeRates

struct PromoDiscount {
    let dcOrderLine: DCOrderLine
    let potentialPromoItem: PotentialPromoItem?
    
    let qtyDiscounted: Int
    let unitDisc: MoneyWithoutCurrency
    var rebateAmount: MoneyWithoutCurrency
    
    var totalDisc: MoneyWithoutCurrency { qtyDiscounted * unitDisc }
}
