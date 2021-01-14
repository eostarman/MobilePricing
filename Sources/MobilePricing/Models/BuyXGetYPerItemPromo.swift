//
//  File.swift
//  
//
//  Created by Michael Rutherford on 1/10/21.
//

import Foundation
import MobileDownload

struct BuyXGetYPerItemPromo {
    let promoSection: PromoSectionRecord
    
    let itemNid: Int
    let qtyX: Int
    let qtyY: Int
}

extension PromoSectionRecord {
    func getBuyXGetYPerItemPromos() -> [BuyXGetYPerItemPromo] {
        guard isBuyXGetY && !isMixAndMatch else {
            return []
        }
        
        var promos: [BuyXGetYPerItemPromo] = []
        
        for promoItem in getPromoItems() {
            let promo = BuyXGetYPerItemPromo(promoSection: self, itemNid: promoItem.itemNid, qtyX: qtyX, qtyY: qtyY)
            promos.append(promo)
        }
        
        return promos
    }
}
