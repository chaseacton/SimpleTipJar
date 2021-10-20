//
//  TipPersistenceManager.swift
//  TipJarComponent
//
//  Created by Dolar, Ziga on 07/23/2019.
//  Copyright (c) 2019 Dolar, Ziga. All rights reserved.
//

import Foundation
import StoreKit

struct Tip: Codable, Equatable {
    let price: Double
    let priceLocaleIdentifier: String
    let productIdentifier: String
    let transactionIdentifier: String
    let transactionDate: Date
    let appVersion: String

    init(price: NSDecimalNumber,
         priceLocale: Locale,
         productIdentifier: String,
         transactionIdentifier: String,
         transactionDate: Date = Date())
    {
        self.price = price.doubleValue
        self.priceLocaleIdentifier = priceLocale.identifier
        self.productIdentifier = productIdentifier
        self.transactionIdentifier = transactionIdentifier
        self.transactionDate = transactionDate
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var priceNumber: NSDecimalNumber {
        return NSDecimalNumber(value: price)
    }

    var priceLocale: Locale {
        return Locale(identifier: priceLocaleIdentifier)
    }
}

class TipPersistenceManager {
    static let shared: TipPersistenceManager = {
        let defaults: UserDefaults = .standard

        return TipPersistenceManager(with: defaults)
    }()

    private let kTipsCollection = "kTipsCollection"
    private let defaults: UserDefaults

    var tips: [Tip] {
        guard let storedData = defaults.object(forKey: kTipsCollection) as? Data else {
            return []
        }

        let decoded = (try? JSONDecoder().decode([Tip].self, from: storedData)) ?? []

        return decoded
    }

    var tipsForCurrentVersion: [Tip] {
        guard let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return tips
        }

        return tips(for: currentAppVersion)
    }

    func persist(tip: Tip) {
        add(tip)
    }

    // MARK: - Private

    private init(with defaults: UserDefaults = .standard) {
        self.defaults = defaults
        syncWithICloud()
    }

    private func add(_ tip: Tip) {
        var tips = self.tips

        guard !tips.contains(tip) else {
            return
        }

        tips.append(tip)

        persist(tips)
    }

    private func persist(_ tips: [Tip]) {
        guard let data = try? JSONEncoder().encode(tips) else { return }

        storeLocally(data)
        storeToICloud(data)
    }

    private func storeLocally(_ data: Data?) {
        defaults.set(data, forKey: kTipsCollection)
    }

    private func tips(for version: String) -> [Tip] {
        return tips.filter { $0.appVersion == version }
    }
}

extension TipPersistenceManager {
    var totalTipsAmount: String {
        var string = ""

        let filtered = tips.reduce([:]) { result, tip -> [String: [Tip]] in
            var mutableResult = result

            guard let currencyCode = tip.priceLocale.currencyCode else {
                return result
            }

            var mutableArray = mutableResult[currencyCode] ?? []
            mutableArray.append(tip)

            if !mutableArray.isEmpty {
                mutableResult[currencyCode] = mutableArray
            }

            return mutableResult
        }

        let formatter: NumberFormatter = NumberFormatter()
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .currency

        filtered.forEach {
            let totalAmount = $0.value.reduce(0) { total, tip -> Double in
                return total + tip.price
            }

            if let priceLocale = $0.value.first?.priceLocale {
                formatter.locale = priceLocale


                let formattedPrice = formatter.string(from: NSDecimalNumber(value: totalAmount))

                if !string.isEmpty && formattedPrice != nil {
                    string += " + "
                }

                string += formattedPrice ?? ""
            }
        }

        return string
    }
}

// MARK - iCloud Key-Value storage sync

extension TipPersistenceManager {
    private var cloudTipsCollectionKey: String {
        return kTipsCollection + "CloudTipJar"
    }

    private func syncWithICloud() {
        let store = NSUbiquitousKeyValueStore.default
        store.synchronize()

        var cloudTipsDecoded: [Tip] = []
        if let cloudTipsData = store.object(forKey: cloudTipsCollectionKey) as? Data {
            cloudTipsDecoded = (try? JSONDecoder().decode([Tip].self, from: cloudTipsData)) ?? []
        }

        var localTips = tips

        cloudTipsDecoded.forEach { tip in
            if !localTips.contains(tip) {
                localTips.append(tip)
            }
        }

        persist(localTips)
    }

    private func storeToICloud(_ data: Data?) {
        let store = NSUbiquitousKeyValueStore.default

        store.set(data, forKey: cloudTipsCollectionKey)
        store.synchronize()
    }
}
