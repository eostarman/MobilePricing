//
//  PriceSheetService.swift
//  MobileBench
//
//  Created by Michael Rutherford on 7/16/20.
//

import Foundation
import MobileDownload
import MoneyAndExchangeRates


public final class PriceSheetService {
    public let shipFrom: WarehouseRecord
    public let shipTo: CustomerRecord
    public let pricingParent: CustomerRecord
    public let pricingDate: Date
    let isDepositSchedule: Bool

    /// price sheets that are directly assigned to the customer - these takes precedence over the price-rules or warehouse default price sheets
    public var priceSheetsForCustomer: [PriceSheetLink] = []
    public var priceSheetsFromRules: [PriceSheetLink] = []
    /// price sheets that are assigned to the warehouse (used only if the item isn't listed in a customer-assigned price book, or one based on rules
    public var priceSheetsForWarehouse: [PriceSheetLink] = []

    public var isEmpty: Bool {
        priceSheetsForCustomer.isEmpty && priceSheetsFromRules.isEmpty && priceSheetsForWarehouse.isEmpty
    }

    public init(shipFrom: WarehouseRecord, shipTo: CustomerRecord, pricingDate: Date, isDepositSchedule: Bool = false) {
        self.shipFrom = shipFrom
        self.shipTo = shipTo
        self.pricingParent = mobileDownload.customers[shipTo.pricingParentNid ?? shipTo.recNid]
        self.pricingDate = pricingDate
        self.isDepositSchedule = isDepositSchedule

        getAllPriceSheetLinks()
    }

    // A link from a customer or warehouse to the price sheets (dbo.CustomerPriceBooks or dbo.WarehousePriceBooks)
    public struct PriceSheetLink {
        let priceSheet: PriceSheetRecord

        let priceLevel: Int
        let canUseAutomaticColumns: Bool
    }

    public struct PriceSheetPrice: Equatable {
        public let priceSheetNid: Int
        public let priceLevel: Int
        public let price: Money
    }

    /// Get the best (or maybe the only) frontline price for an item (in the context of an order with quantities)
    /// - Parameters:
    ///   - itemNid: the item being priced
    ///   - triggerQuantities: the quantities on order
    ///   - transactionCurrency: the order's transaction currency
    /// - Returns: nil or the best price (including the priceSheetNid, the priceLevel and the actual price)
    public func getPrice(_ item: ItemRecord, triggerQuantities: TriggerQtys, transactionCurrency: Currency) -> PriceSheetPrice? {

        if let price = getPrice(priceSheetsForCustomer, item, triggerQuantities: triggerQuantities, transactionCurrency: transactionCurrency) {
            return price
        }

        if let price = getPrice(priceSheetsFromRules, item, triggerQuantities: triggerQuantities, transactionCurrency: transactionCurrency) {
            return price
        }

        if let price = getPrice(priceSheetsForWarehouse, item, triggerQuantities: triggerQuantities, transactionCurrency: transactionCurrency) {
            return price
        }

        return nil
    }

    private func getPrice(_ priceSheetLinks: [PriceSheetLink], _ item: ItemRecord, triggerQuantities: TriggerQtys, transactionCurrency: Currency) -> PriceSheetPrice? {

        var bestPrice: PriceSheetPrice? = nil

        for link in priceSheetLinks {
            guard let thisPrice = getPrice(link, item, triggerQuantities: triggerQuantities, transactionCurrency: transactionCurrency) else {
                continue
            }

            if bestPrice == nil {
                bestPrice = thisPrice
            } else if thisPrice.price.amount < bestPrice!.price.amount { //HACK - mpr - convert to the transactionCurrency
                bestPrice = thisPrice
            }
        }

        return bestPrice
    }

    public func getPrice(_ priceSheetLink: PriceSheetLink, _ item: ItemRecord, triggerQuantities: TriggerQtys, transactionCurrency: Currency) -> PriceSheetPrice? {
        let priceSheet = priceSheetLink.priceSheet

        var levelForBestPrice = priceSheetLink.priceLevel
        var bestPrice = priceSheet.getPrice(item, priceLevel: priceSheetLink.priceLevel)

        // I'm not allowed to look in the automatic columns for a better price
        if !priceSheetLink.canUseAutomaticColumns {
            if let price = bestPrice {
                return PriceSheetPrice(priceSheetNid: priceSheetLink.priceSheet.recNid, priceLevel: levelForBestPrice, price: price)
            } else {
                return nil
            }
        }

        // I am allowed, but there are no automatic columnss
        let automaticColumns = priceSheet.getAutomaticPriceLevels()
        if automaticColumns.isEmpty {
            if let price = bestPrice {
                return PriceSheetPrice(priceSheetNid: priceSheetLink.priceSheet.recNid, priceLevel: levelForBestPrice, price: price)
            } else {
                return nil
            }
        }

        for priceLevel in automaticColumns {
            if !priceSheet.isFrontlinePriceLevelTriggered(item, priceLevel: priceLevel, triggerQuantities: triggerQuantities) {
                continue
            }

            guard let price = priceSheet.getPrice(item, priceLevel: priceLevel) else {
                continue
            }

            if bestPrice == nil || price.amount < bestPrice!.amount { // HACK!!! use exchange service to convert to the transactionCurrency
                bestPrice = price
                levelForBestPrice = priceLevel
            }
        }

        if let price = bestPrice {
            return PriceSheetPrice(priceSheetNid: priceSheetLink.priceSheet.recNid, priceLevel: levelForBestPrice, price: price)
        } else {
            return nil
        }
    }

    private func getAllPriceSheetLinks() {
        let priceRuleNids = pricingParent.priceRuleNids

        let activePriceSheets = mobileDownload.priceSheets.getAll().filter { priceSheet in
            priceSheet.isDepositSchedule == isDepositSchedule && priceSheet.isActive(on: pricingDate)
        }

        for priceRuleNid in priceRuleNids {
            let priceRule = mobileDownload.priceRules[priceRuleNid]

            // this price rule only applies when we're shipping from a specific warehouse
            if priceRule.shipFromWhseNid != nil, priceRule.shipFromWhseNid != shipFrom.recNid {
                continue
            }

            let priceSheets = activePriceSheets.filter { priceSheet in
                priceSheet.priceBookNid == priceRule.priceBookNid
            }

            for priceSheet in priceSheets {

                let link = PriceSheetLink(priceSheet: priceSheet, priceLevel: priceRule.priceLevel, canUseAutomaticColumns: priceRule.canUseAutomaticColumns)

                priceSheetsFromRules.append(link)
            }
        }

        for priceSheet in activePriceSheets {

            if let warehouseLink = priceSheet.warehouses[shipFrom.recNid] {
                let link = PriceSheetLink(priceSheet: priceSheet, priceLevel: warehouseLink.priceLevel, canUseAutomaticColumns: warehouseLink.canUseAutomaticColumns)
                priceSheetsForWarehouse.append(link)
            }

            if let customerLink = priceSheet.customers[pricingParent.recNid] {
                let link = PriceSheetLink(priceSheet: priceSheet, priceLevel: customerLink.priceLevel, canUseAutomaticColumns: customerLink.canUseAutomaticColumns)
                priceSheetsForCustomer.append(link)
            }
        }
    }
}

extension PriceSheetRecord {

    // see IsFrontlinePriceLevelTriggered() in TriggerQtys.cs

    /// Determine if the automatic column is "triggered" by the quantities the customer is ordering. For example, a price book may have two price sheets - one at quantity 1 and
    /// another at quantity 10. The minimum can be based on the number of "cases" bought (the quantity) or on the gross weight. When it's based on the quantity bought, no conversion
    /// to the primary packs is performed.
    /// - Parameters:
    ///   - triggerQuantities: the quantities ordered, by item
    ///   - itemNid: the item (used only when the minimums are per-item)
    ///   - priceLevel: the price level (column) in the price sheet
    /// - Returns: true if the minimum is met for the price(s) in this column to take effect
    func isFrontlinePriceLevelTriggered(_ item: ItemRecord, priceLevel: Int, triggerQuantities: TriggerQtys) -> Bool {
        guard let columnInfo = columInfos[priceLevel], columnInfo.isAutoColumn, columnInfo.columnMinimum > 0 else {
            return false
        }

        if perItemMinimums {
            let qty = triggerQuantities.getCasesOrWeight(item, isCaseMinimum: columnInfo.isCaseMinimum)
            return qty >= Double(columnInfo.columnMinimum)
        }
        else {
            var totalQty = 0.0
            for itemNid in triggerQuantities.itemNids {
                if containsItem(itemNid: itemNid) {
                    let qty = triggerQuantities.getCasesOrWeight(item, isCaseMinimum: columnInfo.isCaseMinimum)
                    totalQty += qty
                }
            }
            return totalQty >= Double(columnInfo.columnMinimum)
        }
    }
}
