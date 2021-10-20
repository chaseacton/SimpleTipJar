//
//  TipButton.swift
//  TipJarComponent
//
//  Created by Dolar, Ziga on 07/23/2019.
//  Copyright (c) 2019 Dolar, Ziga. All rights reserved.
//

import UIKit

class TipButton: UIButton {
    override var isEnabled: Bool {
        didSet {
            self.updateColor()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.updateColor()
    }

    override func tintColorDidChange() {
        self.updateColor()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.adjustCornerRadius()
    }

    private func updateColor() {
        setTitleColor(tintColor, for: .normal)
        setTitleColor(.lightGray, for: .disabled)

        setTitleColor(.white, for: .highlighted)
        setBackgroundColor(color: tintColor, forState: .highlighted)

        setTitleColor(.white, for: .selected)
        setBackgroundColor(color: tintColor, forState: .selected)

        layer.borderColor = isEnabled ? tintColor.cgColor : UIColor.lightGray.cgColor
        layer.borderWidth = 1
    }

    private func adjustCornerRadius() {
        clipsToBounds = true

        let smallerSide = min(bounds.size.width, bounds.size.height)
        layer.cornerRadius = smallerSide/4
    }
}
