//
//  TipJarManager.swift
//  TipJarComponent
//
//  Created by Dolar, Ziga on 07/23/2019.
//  Copyright (c) 2019 Dolar, Ziga. All rights reserved.
//

import UIKit

public class TipJarManager {
    private var window: TipJarWindow?

    public init() {
    }
    
    public var hasReceivedTips: Bool {
        return !TipPersistenceManager.shared.tips.isEmpty
    }

    // MARK: - Public Functions
    
    public func tipJarViewController(with model: TipJarViewModel) -> TipJarViewController? {
        let storyboard = UIStoryboard(name: "TipJar", bundle: Bundle.module)
        guard let controller = storyboard.instantiateInitialViewController() as? TipJarViewController else {
            return nil
        }

        controller.configure(with: model)
        controller.delegate = self

        return controller
    }

    public func start(with model: TipJarViewModel) {
        self.showTipJarScreen(with: model)
    }

    // MARK: - Private Functions

    private func showTipJarScreen(with model: TipJarViewModel) {
        self.presentTipJarScreen(with: model)
    }

    private func presentTipJarScreen(with model: TipJarViewModel) {
        guard let controller = tipJarViewController(with: model) else {
            return
        }

        controller.standalone = true
        controller.modalPresentationStyle = .fullScreen

        DispatchQueue.main.async {
            guard let window = UIApplication.shared.windows.first else {
                print("!! Failed to get UIApplication window")
                return
            }
            window.rootViewController?.present(controller, animated: true)
        }
    }
}

extension TipJarManager: TipJarViewControllerDelegate {
    public func tipJarViewControllerWillDismiss(_ controller: UIViewController) {
        self.window?.dismissBackground(animated: true)
    }

    public func tipJarViewControllerDidDismiss(_ controller: UIViewController) {
        self.window?.isHidden = true
        self.window = nil
    }
}
