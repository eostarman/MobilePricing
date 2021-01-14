//
//  File.swift
//  
//
//  Created by Michael Rutherford on 1/13/21.
//

import Foundation
import MobileDownload

extension PriceSheetRecord {

    // see IsFrontlinePriceLevelTriggered() in TriggerQtys.cs

    /// Determine if the automatic column is "triggered" by the quantities the customer is ordering. For example, a price book may have two price sheets - one at quantity 1 and
    /// another at quantity 10. The minimum can be based on the number of "cases" bought (the quantity) or on the gross weight. When it's based on the quantity bought, no conversion
    /// to the primary packs is performed.
    /// - Parameters:
    ///   - triggerQuantities: the quantities ordered, by item
    ///   - itemNid: the item (used only when the minimums are per-item)
    ///   - priceLevel: the price level (column) in the price sheet
    /// - Returns: true if the minimum is met for the price(s) in this column to take effect
    func isFrontlinePriceLevelTriggered(_ item: ItemRecord, priceLevel: Int, triggerQuantities: TriggerQtys) -> Bool {
        guard let columnInfo = columInfos[priceLevel], columnInfo.isAutoColumn, columnInfo.columnMinimum > 0 else {
            return false
        }

        if perItemMinimums {
            let triggerRequirements = TriggerRequirements(basis: columnInfo.isCaseMinimum ? .qty : .itemWeight, minimum: columnInfo.columnMinimum, triggerItemNids: [item.recNid], groupRequirements: [])
            
            return triggerRequirements.isTriggered(triggerQuantities)
        }
        else {
            let triggerRequirements = TriggerRequirements(basis: columnInfo.isCaseMinimum ? .qty : .itemWeight, minimum: columnInfo.columnMinimum, triggerItemNids: itemNids, groupRequirements: [])
            
            return triggerRequirements.isTriggered(triggerQuantities)
        }
    }
}
