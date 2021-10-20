//
//  TipJarWindow.swift
//  TipJarComponent
//
//  Created by Dolar, Ziga on 07/23/2019.
//  Copyright (c) 2019 Dolar, Ziga. All rights reserved.
//

import UIKit

class TipJarWindow: UIWindow {
    private var backgroundView: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = .clear
    }

    override func makeKeyAndVisible() {
        super.makeKeyAndVisible()
        addBackground(animated: true)
    }

    func dismissBackground(animated: Bool = false) {
        UIView.animate(withDuration: 0.25) {
            self.backgroundColor = .clear
            self.backgroundView?.alpha = 0
        }
    }

    private func addBackground(animated: Bool = false) {
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.frame = bounds

        insertSubview(effectView, at: 0)

        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        effectView.alpha = 0;

        backgroundView = effectView

        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25) {
                self.backgroundColor = UIColor.black.withAlphaComponent(0.5)
                self.backgroundView?.alpha = 1
            }
        }
    }
}
