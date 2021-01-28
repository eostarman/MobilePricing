//  Created by Michael Rutherford on 1/27/21.

import MoneyAndExchangeRates

struct FreebieNeedingNewOrderLine {
    let promoSectionNid: Int
    let dcOrderLine: IDCOrderLine
    let qtyDiscounted: Int
    let unitDisc: MoneyWithoutCurrency
    let rebateAmount: MoneyWithoutCurrency
    let promoSeq: Int
}
