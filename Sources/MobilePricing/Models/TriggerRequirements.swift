//
//  File.swift
//  
//
//  Created by Michael Rutherford on 1/10/21.
//

import Foundation
import MobileDownload

/// The discounts on promotions (and the front-line price levels) can be "triggered" based on the items on the order (and on how many of each are bought).
/// Triggers can be based on a total of which a certain amount must be bought from sub-groups. They only make sense in mix-and-match promotions and
/// price sheets.
struct TriggerRequirements {

    var triggerGroup: Int? = nil
    var basis: Basis = .qty
    var minimum: Int = 0
    var triggerItemNids: Set<Int> = []
    
    /// When there are *additional* requirements on the items that must be bought, then those requirements are listed here (for example, the promo could
    /// apply when you buy 10 cases of diet soda, but at least 2 cases have to be the grape diet soda
    var groupRequirements: [TriggerRequirements]
}

extension TriggerRequirements {
    enum Basis {
        case qty
        case caseRollup
        case itemWeight
    }
    
    /// this is a mix-and-match trigger based on quantity bought, and the minimum quantity to buy is (1) with no group requirements
    var isQuantityOne: Bool {
        basis == .qty && minimum <= 1 && groupRequirements.isEmpty
    }
    
    var numberOfItems: Int {
        triggerItemNids.count
    }
    
    func contains(itemNid: Int) -> Bool {
        triggerItemNids.contains(itemNid)
    }
    
    func isTriggered(_ triggerQtys: TriggerQtys) -> Bool {
        for groupRequirement in groupRequirements {
            if !groupRequirement.isTriggered(triggerQtys) {
                return false
            }
        }
        
        switch basis {
        case .itemWeight:
            let totalQty = triggerItemNids.map { triggerQtys.getWeight(itemNid: $0) }.reduce(0, +)
            let qtyRoundedUp = totalQty + 0.1 // add a small amount so that 3 x .3333 >= 1.0 (when it's really .9999)
            return qtyRoundedUp >= Double(minimum)
        case .caseRollup:
            let totalQty = triggerItemNids.map { triggerQtys.getRollupQty(itemNid: $0) }.reduce(0, +)
            return totalQty >= Double(minimum)
        case .qty:
            let totalQty = triggerItemNids.map { triggerQtys.getQty(itemNid: $0) }.reduce(0, +)
            return totalQty >= minimum
        }
    }
}
