//
//  File.swift
//  
//
//  Created by Michael Rutherford on 1/24/21.
//

import Foundation

/// allow quick access to promoSections by itemNid (to find those sections that are triggered by an item or that provide a discount for an item - i.e. are targets for an item)
class ItemPromoSections {
    private let activePromoSections: [DCPromoSection]
    private var discountPromoSectionsForItem: [Int: [DCPromoSection]] = [:]
    private var triggerPromoSectionsForItem: [Int: [DCPromoSection]] = [:]
    
    init(activePromoSections: [DCPromoSection]) {
        self.activePromoSections = activePromoSections
    }
    
    func getAllPromoSectionsWithDiscountsForTheseItems(itemNids: [Int]) -> [DCPromoSection] {
        activePromoSections.filter { $0.isTarget(forAnyItemNid: itemNids) }
        
    }
    /// get the promoSections for which this item is a trigger
    func getTriggerPromoSectionsForItem(itemNid: Int) -> [DCPromoSection] {
        
        if let sections = triggerPromoSectionsForItem[itemNid] {
            return sections
        } else {
            let sections = activePromoSections.filter { $0.isTrigger(itemNid: itemNid) }
            triggerPromoSectionsForItem[itemNid] = sections
            return sections
        }
    }
    
    /// get the promoSections that can provide a discount for the item
    func getDiscountPromoSectionsForItem(itemNid: Int) -> [DCPromoSection] {
        
        if let sections = discountPromoSectionsForItem[itemNid] {
            return sections
        } else {
            let sections = activePromoSections.filter { $0.isTarget(itemNid: itemNid) }
            discountPromoSectionsForItem[itemNid] = sections
            return sections
        }
    }
    
    /// If there are contract promotions for this item then we'll keep the contract promos plus any additional fees/taxes only (discarding non-contract promotions). Contract promotions trump any other promotions (discounts)
    /// and are usually negotiated for a chain (i.e. even if there's temporarily a better discount for an item it won't be taken)
    private func getPromoSectionsAfterAccountingForContractPromos(dcPromoSectionsForOneItem: [DCPromoSection]) -> [DCPromoSection]
    {
        var contractPromoSections: [DCPromoSection] = []
        var additionalFees: [DCPromoSection] = []

        for dcPromoSection in dcPromoSectionsForOneItem {
            let promoSection = dcPromoSection.promoSection
            
            if promoSection.promoSectionRecord.promoPlan == .AdditionalFee {
                additionalFees.append(dcPromoSection)
                continue
            }
            
            if promoSection.promoSectionRecord.isContractPromo {
                contractPromoSections.append(dcPromoSection)
            }
        }
        
        if contractPromoSections.isEmpty {
            return dcPromoSectionsForOneItem
        }
        
        contractPromoSections.append(contentsOf: additionalFees)

        return contractPromoSections
    }
    
}
