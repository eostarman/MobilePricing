//  Created by Michael Rutherford on 2/9/21.

import Foundation
import MoneyAndExchangeRates
import MobileDownload

// like the PotentialPromoItem, but with the computed unitDiscount
public struct PotentialDiscount {
    public let promoSection: PromoSectionRecord
    public let triggerRequirements: TriggerRequirements
    public let triggerQtys: TriggerQtys

    public let promoItem: PromoItem
    
    public let unitDiscount: MoneyWithoutCurrency
}
