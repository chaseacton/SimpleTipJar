//
//  StoreManager.swift
//  TipJarComponent
//
//  Created by Dolar, Ziga on 07/23/2019.
//  Copyright (c) 2019 Dolar, Ziga. All rights reserved.
//

import Foundation
import StoreKit

typealias StoreFetchProductsHandler = ([SKProduct]) -> Void
typealias StorePaymentTransactionHandler = (Bool) -> Void
typealias SubscriptionStatusUpdateHandler = () -> Void

class StoreManager: NSObject {
    static var productIdentifiers: [String] = [] {
        didSet {
            shared.productIdentifiers = Set(productIdentifiers)
        }
    }
    
    static let shared: StoreManager = StoreManager(productIds: StoreManager.productIdentifiers)
    
    var productIdentifiers: Set<String>
    var purchasedSubscriptionIdentifiers: Set<String> = []
    private var productRequest: SKProductsRequest?
    var productRequestHandler: StoreFetchProductsHandler?
    var subscriptionStatusUpdateHandler: SubscriptionStatusUpdateHandler?
    
    private var products: [SKProduct] = []
    
    var sortedProducts: [SKProduct] {
        self.products.sorted(by: { $0.price.doubleValue < $1.price.doubleValue })
    }
    
    var sortedNonSubscriptions: [SKProduct] {
        self.products
            .filter { !$0.isSubscription }
            .sorted(by: { $0.price.doubleValue < $1.price.doubleValue })
    }
    
    var sortedSubscriptions: [SKProduct] {
        self.products
            .filter { $0.isSubscription }
            .sorted(by: { $0.price.doubleValue < $1.price.doubleValue })
    }
    
    var paymentTransactionHandlers: [String: StorePaymentTransactionHandler] = [:]
    
    lazy var persistenceManager: TipPersistenceManager = .shared
    
    private init(productIds: [String]) {
        self.productIdentifiers = Set(productIds)
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    func fetchProducts(_ handler: @escaping StoreFetchProductsHandler) {
        productRequestHandler = handler
        productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productRequest?.delegate = self
        productRequest?.start()
    }
    
    func purchase(_ product: SKProduct, handler: @escaping StorePaymentTransactionHandler) {
        paymentTransactionHandlers[product.productIdentifier] = handler
        
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func productWithIdentifier(_ identifier: String) -> SKProduct? {
        self.products
            .first(where: { product in product.productIdentifier == identifier })
    }
    
    func didPurchaseSubscription(for product: SKProduct) -> Bool {
        guard let product = self.productWithIdentifier(product.productIdentifier) else {
            return false
        }
        
        return self.purchasedSubscriptionIdentifiers.contains(product.productIdentifier)
    }
}

extension StoreManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = response.products
        productRequestHandler?(self.sortedProducts)
        resetRequest()
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        productRequestHandler?([])
        resetRequest()
    }
    
    func resetRequest() {
        productRequest = nil
        productRequestHandler = nil
    }
}

extension StoreManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach { transaction in
            var shouldFinishTransaction = false
            
            switch transaction.transactionState {
            case .purchased:
                shouldFinishTransaction = true
                self.updateSubscriptionPurchasedStatus(transaction: transaction)
                completeTransaction(transaction, with: true)
            case .failed:
                completeTransaction(transaction, with: false)
            case .restored:
                self.updateSubscriptionPurchasedStatus(transaction: transaction)
            default:
                debugPrint("other: \(transaction.payment.productIdentifier)")
            }
            
            if shouldFinishTransaction {
                queue.finishTransaction(transaction)
            }
        }
    }
    
    private func completeTransaction(_ transaction: SKPaymentTransaction, with success: Bool) {
        if success {
            self.persistSuccessfulTransaction(transaction)
        }
        
        guard let handler = self.paymentTransactionHandlers[transaction.payment.productIdentifier] else {
            return
        }
        
        handler(success)
    }
    
    private func updateSubscriptionPurchasedStatus(transaction: SKPaymentTransaction) {
        let identifier = transaction.payment.productIdentifier
        
        guard
            let product = self.productWithIdentifier(identifier),
            product.isSubscription else {
                return
            }
        
        // TODO: Check if subscription is not expired
        self.purchasedSubscriptionIdentifiers.insert(identifier)
        self.subscriptionStatusUpdateHandler?()
    }
    
    private func persistSuccessfulTransaction(_ transaction: SKPaymentTransaction) {
        if let product = products.first(where: { $0.productIdentifier == transaction.payment.productIdentifier }) {
            debugPrint(product)
            debugPrint(transaction)
            
            guard let transactionDate = transaction.transactionDate,
                  let transactionIdentifier = transaction.transactionIdentifier else {
                      return
                  }
            
            let tip = Tip(price: product.price,
                          priceLocale: product.priceLocale,
                          productIdentifier: product.productIdentifier,
                          transactionIdentifier: transactionIdentifier,
                          transactionDate: transactionDate)
            
            self.persistenceManager.persist(tip: tip)
        }
    }
}

extension SKProduct {
    /// Returns true if an `SKProduct` subscriptionPeriod is not nil
    var isSubscription: Bool { self.subscriptionPeriod != nil }
}
