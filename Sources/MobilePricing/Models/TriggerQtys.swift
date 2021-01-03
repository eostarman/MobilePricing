//
//  TriggerQtys.swift
//  MobileBench
//
//  Created by Michael Rutherford on 7/21/20.
//

import Foundation
import MobileDownload

public class TriggerQtys {
    public var quantitiesByItem: [Int: Int] = [:]

    func addItemAndQty(itemNid: Int, qty: Int) {
        let priorQty = quantitiesByItem[itemNid]

        if priorQty == nil {
            quantitiesByItem[itemNid] = qty
        } else {
            quantitiesByItem[itemNid] = priorQty! + qty
        }
    }
}
