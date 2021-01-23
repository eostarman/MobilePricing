//
//  File.swift
//  
//
//  Created by Michael Rutherford on 1/23/21.
//

import MobileDownload

/// A stand-in (wrapper) for the PromoSectionRecord that adds some functionality
protocol PromoSection {
    var promoSectionRecord: PromoSectionRecord { get }
    
    func isTriggerItemOrRelatedAltPack(itemNid: Int) -> Bool
    func hasDiscount(itemNid: Int) -> Bool
    func getTriggerGroup(itemNid: Int) -> Int?
}
