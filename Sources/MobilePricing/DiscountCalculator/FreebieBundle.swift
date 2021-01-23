//  Created by Michael Rutherford on 1/23/21.

import Foundation

/// this ties together the items consumed in the "earning" of a QtyFree along with the items actually given free.
class FreebieBundle {

    let freebieTriggers: [FreebieTrigger]
    let freebieTargets: [FreebieTarget]
    let qtyFree: Int
    let unusedFreeQty: Int
    
    /// The number of times I computed one of these FreebieBundles (same items, same quantities, and same OrderLines)
    var nbrTimes: Int = 1
    
    internal init(freebieTriggers: [FreebieTrigger], freebieTargets: [FreebieTarget], qtyFree: Int, unusedFreeQty: Int) {
        self.freebieTriggers = freebieTriggers
        self.freebieTargets = freebieTargets
        self.qtyFree = qtyFree
        self.unusedFreeQty = unusedFreeQty
    }
    
    /// close to "==" but matches against the orderLines used, the triggers and targets and the quantities - used to let us bump the nbrTimes counter
    func matches(other: FreebieBundle) -> Bool {
        if qtyFree != other.qtyFree || unusedFreeQty != other.unusedFreeQty {
            return false
        }
        
        if freebieTriggers.count != other.freebieTriggers.count || freebieTargets.count != other.freebieTargets.count {
            return false
        }
        
        for i in 0 ..< freebieTriggers.count {
            let x = freebieTriggers[i]
            let y = other.freebieTriggers[i]
            
            if x.item.seq != y.item.seq || x.qtyUsedAsTrigger != y.qtyUsedAsTrigger {
                return false
            }
        }
        
        for i in 0 ..< freebieTargets.count {
            let x = freebieTargets[i]
            let y = other.freebieTargets[i]
            
            if x.item.seq != y.item.seq || x.qtyFreeHere != y.qtyFreeHere {
                return false
            }
        }
        
        // don't compare the nbrTimes counter
        return true
    }
}
