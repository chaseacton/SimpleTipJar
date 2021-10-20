//
//  TipJarViewController.swift
//  TipJarComponent
//
//  Created by Dolar, Ziga on 07/23/2019.
//  Copyright (c) 2019 Dolar, Ziga. All rights reserved.
//

import UIKit
import StoreKit

public protocol TipJarViewControllerDelegate: AnyObject {
    func tipJarViewControllerWillDismiss(_ controller: UIViewController)
    func tipJarViewControllerDidDismiss(_ controller: UIViewController)
}

public final class TipJarViewController: UIViewController {    
    private var model: TipJarViewModel!
    private var didAppear: Bool = false
    
    private lazy var storeManager: StoreManager = {
        var manager = StoreManager.shared
        StoreManager.productIdentifiers = Array(model.products.keys)
        StoreManager.shared.subscriptionStatusUpdateHandler = { [weak self] in
            self?.refreshData()
        }
        return .shared
    }()
    
    private lazy var persistenceManager: TipPersistenceManager = .shared
    
    @IBOutlet private var containerView: UIView!
    
    // MARK: - Loading views
    @IBOutlet private var loadingView: UIView!
    @IBOutlet private var loadingLabel: UILabel!
    @IBOutlet private var loadingIndicator: UIActivityIndicatorView!
    
    // MARK: - Store views
    @IBOutlet private var storeView: UIStackView!
    @IBOutlet private var topLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var totalTipsLabel: UILabel!
    @IBOutlet private var tipViewsStackView: UIStackView!
    
    // MARK: - Thank You views
    @IBOutlet private var thankYouView: UIStackView!
    @IBOutlet private var thankYouEmojiLabel: UILabel!
    @IBOutlet private var thankYouLabel: UILabel!
    @IBOutlet private var thankYouTotalLabel: UILabel!
    
    @IBOutlet private var closeButton: UIButton!
    
    @IBOutlet private var standaloneConstraints: [NSLayoutConstraint]!
    @IBOutlet private var nonStandaloneConstraints: [NSLayoutConstraint]!
    
    // Legal
    @IBOutlet private var legalView: UIStackView!
    @IBOutlet private var subscriptionLegalText: UILabel!
    @IBOutlet private var termsOfServiceButton: UIButton!
    @IBOutlet private var privacyPolicyButton: UIButton!
    
    public var standalone: Bool = false
    public weak var delegate: TipJarViewControllerDelegate?
    public var textColor: UIColor? {
        didSet {
            guard let color = textColor else {
                return
            }
            
            updateTextColor(with: color)
        }
    }
    
    // MARK: - View Lifecycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.closeButton.isHidden = true
        self.containerView.roundCorners(20)
        self.configureView()
        
        if let color = self.textColor {
            self.updateTextColor(with: color)
        }
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard !didAppear else {
            return
        }
        
        self.didAppear = true
        self.refreshData()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.standalone {
            self.closeButton.alpha = 0
            self.closeButton.isHidden = false
            
            UIView.animate(withDuration: 0.25) {
                self.closeButton.alpha = 1
            }
        }
    }
    
    // MARK: - Public Functions
    
    public func configure(with model: TipJarViewModel) {
        self.model = model
    }
    
    // MARK: - Private Functions
    
    private func refreshData() {
        self.storeManager.fetchProducts { [weak self] sortedProducts in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.configureView(with: sortedProducts)
            }
        }
    }
    
    private func reloadData() {
        DispatchQueue.main.async {
            self.configureView(with: self.storeManager.sortedProducts)
        }
    }
    
    private func configureView() {
        self.loadingLabel.text = "Connecting to store…"
        
        let topText = model.topText ?? ""
        self.topLabel.text = topText
        self.topLabel.isHidden = !(topText.count > 0)
        
        let subtitleText = model.subtitleText ?? ""
        self.subtitleLabel.text = subtitleText
        self.subtitleLabel.isHidden = !(subtitleText.count > 0)
        
        let totalTipsString = persistenceManager.totalTipsAmount
        self.totalTipsLabel.text = "You have tipped \(totalTipsString) so far! 🤩"
        self.totalTipsLabel.isHidden = totalTipsString.isEmpty
        
        if self.standalone {
            view.backgroundColor = .clear
        } else {
            self.containerView.backgroundColor = .clear
        }
        
        NSLayoutConstraint.activate(self.standalone ? self.standaloneConstraints : self.nonStandaloneConstraints)
        NSLayoutConstraint.deactivate(self.standalone ? self.nonStandaloneConstraints : self.standaloneConstraints)
        
        self.storeView.isHidden = true
        self.thankYouView.isHidden = true
        self.legalView.isHidden = true
        self.privacyPolicyButton.isHidden = self.model.privacyPolicyURL == nil
        self.termsOfServiceButton.isHidden = self.model.termsOfServiceURL == nil
    }
        
    private func configureView(with products: [SKProduct]) {
        self.tipViewsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        guard !products.isEmpty else {
            self.connectingToStoreFailed()
            return
        }
        
        let sortedProducts = products.sorted { $0.subscriptionPeriod?.numberOfUnits ?? 0 < $1.subscriptionPeriod?.numberOfUnits ?? 0 }
        
        let hasSubscriptions = sortedProducts
            .filter { $0.isSubscription }
            .count > 0
        
        sortedProducts.forEach { product in
            let previousView = tipViewsStackView.arrangedSubviews.last as? TipView
            
            let view = TipView()
            let didPurchaseSubscription = self.storeManager.didPurchaseSubscription(for: product)
            view.configure(with: product, title: model.products[product.productIdentifier], didPurchaseSubscription: didPurchaseSubscription)
            view.delegate = self
            self.tipViewsStackView.addArrangedSubview(view)
            
            if let color = textColor {
                view.descriptionLabel.textColor = color
            }
            
            // TODO: Remove
            if let lastView = previousView {
                lastView.purchaseButton.widthAnchor.constraint(equalTo: view.purchaseButton.widthAnchor).isActive = true
            }
        }
        
        self.subscriptionLegalText.isHidden = !hasSubscriptions
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, animations: {
                self.loadingView.alpha = 0
            }) { _ in
                UIView.animate(withDuration: 0.25) {
                    self.loadingView.isHidden = true
                    self.storeView.isHidden = false
                    self.legalView.isHidden = false
                }
            }
        }
    }
    
    // TODO: Localize strings
    private func configureThankYouView(with product: SKProduct) {
        let emoji = model.products[product.productIdentifier]
        
        self.thankYouEmojiLabel.text = emoji
        self.thankYouEmojiLabel.isHidden = emoji == nil
        
        let formatter: NumberFormatter = NumberFormatter()
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        
        var priceString = ""
        if let price = formatter.string(from: product.price) {
            priceString = "\(price) "
        }
        
        self.thankYouLabel.text = "Thank you for the \(priceString)tip! Your generocity is greatly appreciated!"
        
        let totalTipsString = self.persistenceManager.totalTipsAmount
        self.thankYouTotalLabel.text = "You have tipped \(totalTipsString) so far! 🤩"
        self.thankYouTotalLabel.isHidden = totalTipsString.isEmpty
        
        self.subscriptionLegalText.isHidden = !product.isSubscription
    }
    
    private func connectingToStoreFailed() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else {
                return
            }
            
            self.loadingLabel.text = "Could not connect to store."
            self.loadingIndicator.stopAnimating()
        }
    }
    
    private func setPurchaseActive(for view: UIView) {
        self.tipViewsStackView.arrangedSubviews.forEach {
            guard let tipView = $0 as? TipView else {
                return
            }
            
            tipView.setEnabled(false)
            tipView.setActive(tipView == view)
        }
    }
    
    private func purchaseStopped() {
        self.tipViewsStackView.arrangedSubviews.forEach {
            guard let tipView = $0 as? TipView else {
                return
            }
            
            tipView.setEnabled(true)
            tipView.setActive(false)
        }
    }
    
    private func purchaseCompleted(for product: SKProduct) {
        configureThankYouView(with: product)
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, animations: {
                self.storeView.alpha = 0
            }) { _ in
                UIView.animate(withDuration: 0.25) {
                    self.storeView.isHidden = true
                    self.thankYouView.isHidden = false
                }
            }
        }
    }
    
    private func updateTextColor(with color: UIColor) {
        [loadingLabel, topLabel, subtitleLabel, totalTipsLabel, thankYouLabel, thankYouTotalLabel].forEach { $0?.textColor = color }
    }
    
    // MARK: - IBActions
    
    @IBAction private func didTapButton(_ sender: UIButton) {
        delegate?.tipJarViewControllerWillDismiss(self)
        
        UIView.animate(withDuration: 0.25) {
            self.closeButton.isHidden = true
        }
        
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            self.delegate?.tipJarViewControllerDidDismiss(self)
        }
    }
    
    @IBAction private func openTermsOfService() {
        guard let url = self.model.termsOfServiceURL else {
            return
        }
        
        UIApplication.shared.open(url)
    }
    
    @IBAction private func openPrivacyPolicy() {
        guard let url = self.model.privacyPolicyURL else {
            return
        }
        
        UIApplication.shared.open(url)
    }
    
    @IBAction private func restorePurchases() {
        self.storeManager.restorePurchases()
    }
}

extension TipJarViewController: TipViewDelegate {
    func tipView(_ view: UIView, didSelect product: SKProduct) {
        self.setPurchaseActive(for: view)
        
        self.storeManager.purchase(product) { [weak self] success in
            guard let self = self else {
                return
            }
            
            debugPrint("complete \(product.productIdentifier) with \(success)")
            
            self.purchaseStopped()
            if success {
                self.purchaseCompleted(for: product)
            }
        }
    }
}
