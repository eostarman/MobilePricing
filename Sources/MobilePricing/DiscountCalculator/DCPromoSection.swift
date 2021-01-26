//  Created by Michael Rutherford on 1/23/21.

import Foundation
import MobileDownload
import MoneyAndExchangeRates

class DCPromoSection {
    let promoSection: PromoSection
    let promoSectionRecord: PromoSectionRecord
    let transactionCurrency: Currency
    let promoPlan: ePromoPlanForMobileInvoice
    
    var isContractPromo: Bool { promoSectionRecord.isContractPromo }
    var isAdditionalFee: Bool { promoSectionRecord.promoPlan == .AdditionalFee }
    
    let hasExplicitTriggerItems: Bool
    
    let promoItemsByItemNid: [Int: PromoItem]
    
    /// if an item is a target, then it will get a discount when this promoSection is actually triggered (doesn't look at other alt-packs for this item)
    func isTarget(itemNid: Int) -> Bool {
        promoItemsByItemNid[itemNid]?.hasDiscount ?? false
    }
    
    func isTarget(forAnyItemNid itemNids: [Int]) -> Bool {
        for itemNid in itemNids {
            if isTarget(itemNid: itemNid) {
                return true
            }
        }
        return false
    }
    
    /// If an item can trigger this promo section (doesn't look at alt-packs)
    func isTrigger(itemNid: Int) -> Bool {
        guard let promoItem = promoItemsByItemNid[itemNid] else {
            return false
        }
        
        if hasExplicitTriggerItems {
            return promoItem.isExplicitTriggerItem
        } else {
            return true
        }
    }
    
    init(promoSection: PromoSection, transactionCurrency: Currency)
    {
        self.promoSection = promoSection
        self.promoSectionRecord = promoSection.promoSectionRecord
        self.transactionCurrency = transactionCurrency
        promoPlan = ePromoPlanForMobileInvoice(promoSection.promoSectionRecord.promoPlan)
        
        let promoItems = promoSection.promoSectionRecord.getPromoItems()
        hasExplicitTriggerItems = promoItems.contains { $0.isExplicitTriggerItem }
        
        promoItemsByItemNid = Dictionary(uniqueKeysWithValues: promoSection.promoSectionRecord.getPromoItems().map{ ($0.itemNid, $0) })
      
//        this.promoSection = promoSection;
//        this.currencyConversionDate = currencyConversionDate;
//
//        this.databaseCache = databaseCache;
//        this.transactionCurrencyNid = transactionCurrencyNid;
//        this.promoCurrencyNid = databaseCache.GetCurrencyNidForPromoCode(promoSection.PromoCodeNid);
    }
    
    func resetTriggerQtys(_ triggerQtys: TriggerQtys) {
//        this.triggerQtys = triggerQtys;
//                    this.qtyOnOrderByItem = GetQtyOnOrderByItem();
//                    this.qtyOnOrderInTotal = qtyOnOrderByItem.Values.Sum();
    }
    
}
