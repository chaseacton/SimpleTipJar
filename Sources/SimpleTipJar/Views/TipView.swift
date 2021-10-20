//
//  TipView.swift
//  TipJarComponent
//
//  Created by Dolar, Ziga on 07/23/2019.
//  Copyright (c) 2019 Dolar, Ziga. All rights reserved.
//

import UIKit
import StoreKit

protocol TipViewDelegate: AnyObject {
    func tipView(_ view: UIView, didSelect product: SKProduct)
}

class TipView: UIView {
    weak var delegate: TipViewDelegate?

    @IBOutlet private var containerView: UIView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private(set) var descriptionLabel: UILabel!
    @IBOutlet private var purchasedLabel: UILabel!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet var purchaseButton: UIButton!

    private var product: SKProduct?

    init() {
        super.init(frame: .zero)
        self.loadFromNib()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadFromNib()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadFromNib()
    }

    func configure(with product: SKProduct, title: String? = nil, didPurchaseSubscription: Bool) {
        self.product = product
        self.setupView(with: product, title: title, didPurchaseSubscription: didPurchaseSubscription)
    }

    func setEnabled(_ enabled: Bool) {
        self.purchaseButton.isEnabled = enabled
    }

    func setActive(_ active: Bool) {
        self.purchaseButton.titleLabel?.alpha = active ? 0 : 1
        active ? self.activityIndicator.startAnimating() : self.activityIndicator.stopAnimating()
    }

    // MARK: - Actions

    @IBAction private func purchaseButtonTapped(_ sender: UIButton) {
        guard let product = self.product else {
            return
        }

        self.delegate?.tipView(self, didSelect: product)
    }

    // MARK: - Private Functions

    private func setupView(with product: SKProduct, title: String?, didPurchaseSubscription: Bool) {
        self.descriptionLabel.text = product.localizedTitle
        self.titleLabel.text = title

        let formatter: NumberFormatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale

        self.purchaseButton.setTitle(formatter.string(from: product.price), for: .normal)
        self.purchaseButton.isHidden = didPurchaseSubscription
        self.purchasedLabel.isHidden = !didPurchaseSubscription
    }
}
