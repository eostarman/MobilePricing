//
//  PriceSheetService.swift
//  MobileBench
//
//  Created by Michael Rutherford on 7/16/20.
//

import Foundation
import MobileDownload
import MoneyAndExchangeRates

public struct PriceSheetService {
    public let shipFromWhseNid: Int
    public let cusNid: Int
    public let date: Date
    let isDepositSchedule: Bool

    public var links: [PriceSheetLink] = []

    public init(shipFromWhseNid: Int, cusNid: Int, date: Date, isDepositSchedule: Bool) {
        self.shipFromWhseNid = shipFromWhseNid
        self.cusNid = cusNid
        self.date = date
        self.isDepositSchedule = isDepositSchedule

        links = getAllPriceSheetLinks().sorted(by: { $0.linkSource.rawValue < $1.linkSource.rawValue })
    }

    enum LinkSource: Int {
        case Customer = 0 // a price book that's directly assigned to the customer - this takes precedence over the price-rules or warehouse default price books
        case PriceRule = 1
        case Warehouse = 2 // a price book that's assigned to the warehouse (used only if the item isn't listed in a customer-assigned price book, or one based on rules
    }

    // A link from a customer or warehouse to the price sheets (dbo.CustomerPriceBooks or dbo.WarehousePriceBooks)
    public struct PriceSheetLink {
        let linkSource: LinkSource
        let priceSheet: PriceSheetRecord
        let currency: Currency

        let priceLevel: Int
        let canUseAutomaticColumns: Bool

        public mutating func getPrice(itemNid: Int) -> Money? {
            let pricesByItemNid = priceSheet.getPrices(priceLevel: priceLevel)

            guard let price = pricesByItemNid[itemNid] else {
                return nil
            }

            return price.withCurrency(currency)
        }
    }

    func getPrices(itemNid: Int) -> [(PriceSheetLink, Money)] {
        var allPrices = [(PriceSheetLink, Money)]()

        for var link in links {
            if let price = link.getPrice(itemNid: itemNid) {
                allPrices.append((link, price))
            }
        }

        return allPrices
    }

    private func getAllPriceSheetLinks() -> [PriceSheetLink] {
        let customer = mobileDownload.customers[cusNid]
        let pricingParent = customer.pricingParentNid > 0 ? mobileDownload.customers[customer.pricingParentNid] : customer
        let priceRuleNids = pricingParent.priceRuleNids

        var links: [PriceSheetLink] = []

        for priceRuleNid in priceRuleNids {
            let priceRule = mobileDownload.priceRules[priceRuleNid]

            // this price rule only applies when we're shipping from a specific warehouse
            if priceRule.shipFromWhseNid != nil, priceRule.shipFromWhseNid != shipFromWhseNid {
                continue
            }

            for priceSheet in mobileDownload.priceSheets.getAll() {
                if priceSheet.priceBookNid != priceRule.priceBookNid || !priceSheet.isActive(on: date) || priceSheet.isDepositSchedule != isDepositSchedule {
                    continue
                }

                let priceBook = mobileDownload.priceBooks[priceSheet.priceBookNid]

                let link = PriceSheetLink(linkSource: .PriceRule, priceSheet: priceSheet, currency: priceBook.currency, priceLevel: priceRule.priceLevel, canUseAutomaticColumns: priceRule.canUseAutomaticColumns)

                links.append(link)
            }
        }

        for priceSheet in mobileDownload.priceSheets.getAll() {
            if !priceSheet.isActive(on: date) || priceSheet.isDepositSchedule != isDepositSchedule {
                continue
            }

            let priceBook = mobileDownload.priceBooks[priceSheet.priceBookNid]

            if let warehouse = priceSheet.warehouses[shipFromWhseNid] {
                let link = PriceSheetLink(linkSource: .Warehouse, priceSheet: priceSheet, currency: priceBook.currency, priceLevel: warehouse.priceLevel, canUseAutomaticColumns: warehouse.canUseAutomaticColumns)
                links.append(link)
            }

            if let customer = priceSheet.customers[cusNid] {
                let link = PriceSheetLink(linkSource: .Customer, priceSheet: priceSheet, currency: priceBook.currency, priceLevel: customer.priceLevel, canUseAutomaticColumns: customer.canUseAutomaticColumns)
                links.append(link)
            }
        }

        return links
    }
}
