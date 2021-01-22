//
//  File.swift
//  
//
//  Created by Michael Rutherford on 1/10/21.
//

import Foundation
import MobileDownload

struct BuyXGetYPerItemPromo {
    let qtyX: Int
    let qtyY: Int
}

extension BuyXGetYPerItemPromo {
    struct Solution {
        
        /// The number being sold to the customer at full price
        let qtyAtFullPrice: Int
        /// The number on the order that're free (including the unusedFreebies). So, buy 10 get 2 free would show 2 when the order contains 11. Of these 2 free ones, one is unused - not on the order but available for free
        let qtyFree: Int
        
        /// The number of earned free goods that are not on the order yet
        let unusedFreebies: Int
        
        /// If there are some on the order that aren't contributing to free goods, then this represents the number of additional items needed to earn more free goods.
        /// If you have a buy 10 get 2 free promo and you buy 10, then this is zero. Likewise for 11 and 12. For 13 however this would be 9
        let qtyToAddToEarnMoreFreebies: Int
    }
    
    /// Given a quantity sold, compute how many are free. If the deal is buy 10 get 1 free, then a qtySold of 10 will show that there is 1 unused freebie while a qtySold
    /// of 11 will show that 10 were at full price and 1 was free (with zero unused freebies)
    /// - Parameter qtySold: The total on the order (includes the paid ones as well as the free ones)
    /// - Returns: the breakdown showing how many of the qtySold are at full price, how many are free, and how many additional ones can be added to the order for free (the unused freebies)
    func compute(qtySold: Int) -> Solution {
        guard qtyX > 0, qtyY > 0 else {
            return Solution(qtyAtFullPrice: qtySold, qtyFree: 0, unusedFreebies: 0, qtyToAddToEarnMoreFreebies: 0)
        }
        
        let bundle = qtyX + qtyY
        let numberOfBundles = qtySold / bundle
        let residual = qtySold % bundle
        
        var qtyAtFullPrice = numberOfBundles * qtyX
        var qtyFree = numberOfBundles * qtyY
        var unusedFreebies = 0
        var qtyToAddToEarnMoreFreebies = 0
        
        if residual >= qtyX {
            qtyAtFullPrice += qtyX
            let finalFreebies = residual - qtyX
            qtyFree += finalFreebies
            unusedFreebies = qtyY - finalFreebies
        } else if residual > 0 {
            qtyAtFullPrice += residual
            qtyToAddToEarnMoreFreebies = qtyX - residual
        }
        
        return Solution(qtyAtFullPrice: qtyAtFullPrice, qtyFree: qtyFree + unusedFreebies, unusedFreebies: unusedFreebies, qtyToAddToEarnMoreFreebies: qtyToAddToEarnMoreFreebies)
    }
    
}

extension PromoSectionRecord {
    func getBuyXGetYPerItemPromo() -> BuyXGetYPerItemPromo? {
        guard isBuyXGetY && !isMixAndMatch && qtyX > 0 && qtyY > 0 else {
            return nil
        }
        
        return BuyXGetYPerItemPromo(qtyX: qtyX, qtyY: qtyY)        
    }
}
