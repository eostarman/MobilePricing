//
//  File.swift
//  
//
//  Created by Michael Rutherford on 1/12/21.
//

import Foundation
import MobileDownload

extension ItemRecord {
    func setPrimaryPack(to primaryPackItem: ItemRecord, numberOfTheseItemsInOnePrimaryPack: Int) {
        primaryPackItem.altPackNids = [recNid]
        altPackFamilyNid = primaryPackItem.recNid
        altPackIsFractionOfPrimaryPack = true
        altPackCasecount = numberOfTheseItemsInOnePrimaryPack
    }
}
