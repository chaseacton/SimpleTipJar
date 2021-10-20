//
//  UIView.swift
//  TipJarComponent
//
//  Created by Dolar, Ziga on 07/23/2019.
//  Copyright (c) 2019 Dolar, Ziga. All rights reserved.
//

import UIKit

extension UIView {
    func loadFromNib() {
        let nibName = String(describing: type(of: self))
        
        guard
            let views = Bundle.module.loadNibNamed(nibName, owner: self, options: nil),
            let firstView = views.first as? UIView
        else {
            return
        }
        
        firstView.translatesAutoresizingMaskIntoConstraints = true
        firstView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        firstView.frame = bounds
        
        self.addSubview(firstView)
        self.backgroundColor = .clear
    }
    
    func roundCorners(_ radius: CGFloat) {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = radius
    }
    
    func dropShadow(offset: CGSize = CGSize(width: 1, height: 1), color: UIColor = .black,
                    radius: CGFloat = 1, opacity: Float = 0.25)
    {
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOffset = offset
        self.layer.shadowRadius = radius
        self.layer.shadowOpacity = opacity
    }
    
    func addBorder(width: CGFloat = 1, color: UIColor = .white) {
        self.layer.borderColor = color.cgColor
        self.layer.borderWidth = width
    }
}
