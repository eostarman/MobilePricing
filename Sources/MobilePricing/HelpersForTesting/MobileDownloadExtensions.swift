//  Created by Michael Rutherford on 1/3/21.

import Foundation
import MobileDownload

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
    func testPriceRule() -> PriceRuleRecord { priceRules.add(testRecord())}
    func testPromoCode() -> PromoCodeRecord { promoCodes.add(testRecord())}
    func testPromoSection() -> PromoSectionRecord { promoSections.add(testRecord())}
}
