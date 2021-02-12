//  Created by Michael Rutherford on 1/3/21.

import Foundation
import MobileDownload
import MoneyAndExchangeRates

fileprivate var numberOfTestRecordsCreated = 0

fileprivate func testRecord<T: Record>() -> T {
    numberOfTestRecordsCreated += 1
    let recNid = numberOfTestRecordsCreated
    
    var record = T()
    record.recNid = recNid
    record.recKey = "\(recNid)"
    record.recName = "\(T.self) #\(recNid)"
    return record
}

extension MobileDownload {
    func testWarehouse() -> WarehouseRecord { warehouses.add(testRecord()) }
    func testItem() -> ItemRecord {
        let item = items.add(testRecord())
        item.altPackCasecount = 1
        item.altPackFamilyNid = item.recNid
        return item
    }
    func testCustomer() -> CustomerRecord { customers.add(testRecord()) }
    func testPriceSheet() -> PriceSheetRecord { priceSheets.add(testRecord()) }
    func testPriceRule() -> PriceRuleRecord { priceRules.add(testRecord()) }
    func testOrderType() -> OrderTypeRecord { orderTypes.add(testRecord()) }
    func testCRVcontainerType() -> CrvContainerTypeRecord { crvContainerTypes.add(testRecord()) }
    func testContainer() -> ContainerRecord { containers.add(testRecord()) }
    
    func testPromoCode(customers: CustomerRecord ..., currency: Currency = .USD) -> PromoCodeRecord {
        let promoCode = promoCodes.add(testRecord())
        promoCode.currency = currency
        promoCode.promoCustomers = Set(customers.map { $0.recNid })
        return promoCode
    }
    
    func testPromoSection(promoCode: PromoCodeRecord? = nil, isMixAndMatch: Bool = true, _ promoItems: PromoItem ...) -> PromoSectionRecord {
        let promoSection = promoSections.add(testRecord())
        promoSection.isMixAndMatch = isMixAndMatch
        promoSection.setPromoItems(promoItems)
        
        if let promoCode = promoCode {
            promoSection.promoCodeNid = promoCode.recNid
        } else {
            let newPromoCode = testPromoCode(currency: .USD)
            promoSection.promoCodeNid = newPromoCode.recNid
        }
        return promoSection
    }
    
    @discardableResult
    func testPromoSection(customer: CustomerRecord, currency: Currency = .USD, _ promoItems: PromoItem ...) -> PromoSectionRecord {

        let promoCode = mobileDownload.testPromoCode(customers: customer, currency: currency)
        
        let promoSection = mobileDownload.testPromoSection()
        promoSection.promoCodeNid = promoCode.recNid
        
        promoSection.promoPlan = .Default
        promoSection.setPromoItems(promoItems)

        return promoSection
    }
}
