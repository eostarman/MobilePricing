//
//  BuyXGetYFreeService.swift
//  MobileBench (iOS)
//
//  Created by Michael Rutherford on 8/5/20.
//
// First ask each promoSection to compute the discounts for this order.
// Do the BuyXGetY promos first so that we can prevent applying discounts to the "free goods bundles"
// for BuyX, it's important to put the largest (X) first (so, Buy5get3 and Buy2Get1 will work)
// for standard promos it doesn't matter ... I'll compute all the ones that are triggered, then pick the deepest discount for each item

// Frank Liquor had buy 50 get 1, but also a buy 50 get 3. So, prefer the (3).
// var sortedBuyXGetY = allPromoSections.Where(x => x.IsBuyXGetY).OrderByDescending(x => x.QtyX).ThenByDescending(x => x.QtyY).ThenByDescending(x => x.StartDate).ThenBy(x => x.PromoSectionNid).ToArray();

import Foundation
import MobileDownload
import MoneyAndExchangeRates

public class BuyXGetYMixAndMatchService {
    
    var sales: [Sale] = []
    
    init() {}
    
    func add(itemNid: Int, qtySold: Int, unitPrice: Money) {
        sales.append(Sale(itemNid: itemNid, qtySold: qtySold, unitPrice: unitPrice))
    }
}

extension BuyXGetYMixAndMatchService {
    struct Sale {
        let itemNid: Int
        let qtySold: Int
        let unitPrice: Money
    }
}

extension BuyXGetYMixAndMatchPromoSection {
    struct Solution {
        
    }
    
    func compute(qtys: TriggerQtys) -> Solution {
        return Solution()
    }
}
