//  Created by Michael Rutherford on 1/23/21.

import Foundation
import MobileDownload

struct UnusedFreebie {
    let promoSection: PromoSectionRecord
    let qtyFree: Int
    
    /// The items in the get-y list (the potential free items) - items can be returned where the Order.GetSellStatus(itemNid) is not AuthorizedItemStatus.OK - so, the UI is responsible for filtering these
    /// out, or for displaying an error message when they're selected.
    let itemNids: Set<Int>
}
