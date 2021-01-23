//  Created by Michael Rutherford on 1/23/21.

import Foundation
import MoneyAndExchangeRates

/// organizes all the trigger-items on the order, and all the target-items (the things we can give away free) sorted in an "appropriate" sequence
struct FreebieTriggersAndTargets {
    let triggers: [FreebieAccumulator]
    let targets: [FreebieAccumulator]
    
    init(lines: [FreebieAccumulator]) {
        // .sorted() needs a predicate that returns true if x should be ordered before y; otherwise, false.

        // Sort the targets of buy-x in the following way ... (*almost* the reverse of the triggers)
        let targets: [FreebieAccumulator] = lines.filter { $0.isTargetItem }
            .sorted { x, y in
                // choose a preferred item (chosen by the sales person) over others
                if x.isPreferredFreeGoodLine != y.isPreferredFreeGoodLine {
                    return x.isPreferredFreeGoodLine ? true : false
                }
                
                // non-shared items will be given free before the shared ones
                if x.isTriggerAndTargetItem != y.isTriggerAndTargetItem {
                    return !x.isTriggerAndTargetItem ? true : false
                }
                
                // smallest frontline price will be given free first
                if x.frontlinePrice != y.frontlinePrice {
                    return x.frontlinePrice < y.frontlinePrice ? true : false
                }
                
                // target smallest qty first
                if x.qtyUnusedInBuyXGetYPromos != y.qtyUnusedInBuyXGetYPromos {
                    return x.qtyUnusedInBuyXGetYPromos < y.qtyUnusedInBuyXGetYPromos ? true : false
                }
                
                // the sequence of this line inside the order is unique across all order lines - two lines can have the same itemNid
                return x.seq < y.seq ? true : false
            }
        
        // Sort the triggers in the following way ... (*almost* the reverse of the targets)
        let triggers: [FreebieAccumulator] = lines.filter { $0.isTriggerItem }.sorted { x, y in
            // consume the preferred free-goods *last* as trigger items
            if x.isPreferredFreeGoodLine != y.isPreferredFreeGoodLine {
                return !x.isPreferredFreeGoodLine ? true : false
            }
            
            // non-shared items first
            if x.isTriggerAndTargetItem != y.isTriggerAndTargetItem {
                return !x.isTriggerAndTargetItem ? true : false
            }
            
            // descending order by FrontlinePrice
            if x.frontlinePrice != y.frontlinePrice {
                return x.frontlinePrice > y.frontlinePrice ? true : false
            }
            
            // consume from largest Qty first
            if x.qtyUnusedInBuyXGetYPromos != y.qtyUnusedInBuyXGetYPromos {
                return x.qtyUnusedInBuyXGetYPromos > y.qtyUnusedInBuyXGetYPromos ? true : false
            }
            
            // the sequence of this line inside the order is unique across all order lines - two lines can have the same itemNid
            return x.seq > y.seq ? true : false
        }
        
        
        self.triggers = triggers
        self.targets = targets
    }

}
