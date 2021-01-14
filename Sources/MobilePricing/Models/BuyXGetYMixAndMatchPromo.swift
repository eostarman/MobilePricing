//
//  File.swift
//  
//
//  Created by Michael Rutherford on 1/10/21.
//

import Foundation
import MobileDownload

struct BuyXGetYMixAndMatchPromo {
    let promoSection: PromoSectionRecord
    
    let triggerRequirements: TriggerRequirements
    let freeItemsThatAreTriggers: Set<Int>
    let freeItemsThatAreNotTriggers: Set<Int>
    let qtyX: Int
    let qtyY: Int
}
