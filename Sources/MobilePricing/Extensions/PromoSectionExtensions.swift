//
//  File.swift
//  
//
//  Created by Michael Rutherford on 1/10/21.
//

import Foundation
import MobileDownload

//MARK: getTriggerRequirements
extension PromoSectionRecord {
    
    func getFreeItemNids(promoDate: Date) -> Set<Int> {
          var freeItems: Set<Int> = []
          
          for item in getPromoItems(promoDate: promoDate) {
              if item.is100PercentOff {
                  freeItems.insert(item.itemNid)
              }
          }
          
          return freeItems
      }
    
    /// In a non-mix-and-match promotion each item "stands by itself" - e.g. buy 10 of item 12 and get 5% off
    /// - Parameter itemNid: The item that is being ordered
    /// - Returns: nil if there's no minimum requirement
    func getNonMixAndMatchTriggerRequirements(itemNid: Int) -> TriggerRequirements? {
        if caseMinimum == 0 {
            return nil
        }
  
        // this is a special case. If all you have to order is (1) then there is no
        // real trigger requirement. Note that this won't work for a "case-rollup" promotion.
        if caseMinimum == 1, !isCaseRollupPromo {
            return nil
        }
        
        let requirements = TriggerRequirements(basis: isCaseRollupPromo ? .caseRollup : .qty, minimum: caseMinimum, triggerItemNids: [itemNid], groupRequirements: [])
        
        return requirements
    }
    
    /// Get the trigger requirements for a mix-and-match promotion to get applied to an order (i.e. certain items *must* be on an order before this promo section is triggered)
    func getMixAndMatchTriggerRequirements(promoDate: Date) -> TriggerRequirements {

        let triggerItemNids = getTriggerItemNids(promoDate: promoDate)

        
//        // this is a special case. If all items are trigger items and the minimum quantity you have to order is (1) then there is no
//        // real trigger requirement. Note that this won't work for a "case-rollup" promotion. Also, it doesn't apply to a
//        // situation where you must buy some *specific* items to get a discount on any of the other items
//        if caseMinimum == 1, !isCaseRollupPromo, triggerItemNids.count == getPromoItems().count {
//            return nil
//        }
        
        let groupRequirements = getTriggerGroupRequirements(promoDate: promoDate)
        
        let requirements = TriggerRequirements(basis: isCaseRollupPromo ? .caseRollup : .qty, minimum: caseMinimum, triggerItemNids: triggerItemNids, groupRequirements: groupRequirements)
        
        return requirements
    }
    
    private func getTriggerGroupRequirements(promoDate: Date) -> [TriggerRequirements] {
        var groupRequirements: [TriggerRequirements] = []
        
        for triggerGroup in triggerGroupsWithNonZeroMinimums {
            let minimum = getTriggerGroupMinimum(triggerGroup: triggerGroup)
            let itemNids = getTriggerGroupItemNids(triggerGroup: triggerGroup, promoDate: promoDate)
            
            let requirement = TriggerRequirements(triggerGroup: triggerGroup, basis: isCaseRollupPromo ? .caseRollup : .qty, minimum: minimum, triggerItemNids: itemNids, groupRequirements: [])
            
            groupRequirements.append(requirement)
        }

        return groupRequirements
    }
    
    /// Get the additional trigger groups that have a non-zero minimum requirement
    var triggerGroupsWithNonZeroMinimums: [Int] {
        var groups: [Int] = []
        
        if triggerGroup1Minimum > 0 { groups.append(1) }
        if triggerGroup2Minimum > 0 { groups.append(2) }
        if triggerGroup3Minimum > 0 { groups.append(3) }
        if triggerGroup4Minimum > 0 { groups.append(4) }
        if triggerGroup5Minimum > 0 { groups.append(5) }
        
        return groups
    }
    
    /// Get the minimum requirement for a given trigger group
    func getTriggerGroupMinimum(triggerGroup: Int) -> Int {
        switch triggerGroup {
        case 1: return triggerGroup1Minimum
        case 2: return triggerGroup2Minimum
        case 3: return triggerGroup3Minimum
        case 4: return triggerGroup4Minimum
        case 5: return triggerGroup5Minimum
        default:
            return 0
        }
    }
    
    private func getTriggerGroupItemNids(triggerGroup: Int, promoDate: Date) -> Set<Int> {
        Set(getPromoItems(promoDate: promoDate).filter { $0.triggerGroup == triggerGroup }.map { $0.itemNid })
    }
    
    /// For a mix-and-match promotion return the trigger items. A promotion can be "triggered" by buying enough of certain items. If the trigger is based on
    /// certain explicit itemNids, then those are returned. Otherwise, all itemNids (discounted or not) are returned
    /// - Returns: itemNids
    func getTriggerItemNids(promoDate: Date) -> Set<Int> {
        let explicitItemNids = Set(getPromoItems(promoDate: promoDate).filter { $0.isExplicitTriggerItem }.map {$0.itemNid })
        if !explicitItemNids.isEmpty {
            return explicitItemNids
        } else {
            return Set(getPromoItems(promoDate: promoDate).map {$0.itemNid })
        }
    }
    
    func getTargetItemNids(promoDate: Date) -> Set<Int> {
        Set(getPromoItems(promoDate: promoDate).filter({ $0.hasDiscount }).map({ $0.itemNid }))
    }
}


