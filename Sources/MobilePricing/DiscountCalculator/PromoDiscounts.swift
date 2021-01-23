//  Created by Michael Rutherford on 1/23/21.

import Foundation
import MoneyAndExchangeRates

struct PromoDiscounts {
    let promoSection: PromoSection
    
    let totalDisc: MoneyWithoutCurrency
    
    let discounts: [PromoDiscount]
    let unusedFreebies: [UnusedFreebie]
    let freebieBundles: [FreebieBundle]
    
    var nbrUnusedFreebies: Int { unusedFreebies.count }
    
    var totalQtyDiscounted: Int {
        discounts.map { $0.qtyDiscounted }.reduce(0, +)        
    }
}
