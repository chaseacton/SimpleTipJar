//
//  TipJarViewModel.swift
//  
//
//  Created by Chase Acton on 10/18/21.
//

import Foundation

public struct TipJarViewModel {
    public let products: [String: String]
    public var topText: String?
    public var subtitleText: String?
    public var termsOfServiceURL: URL?
    public var privacyPolicyURL: URL?
    
    public init(products: [String: String],
                topText: String? = nil,
                subtitleText: String? = nil,
                termsOfServiceURL: URL?,
                privacyPolicyURL: URL?)
    {
        self.topText = topText
        self.subtitleText = subtitleText
        self.products = products
        self.termsOfServiceURL = termsOfServiceURL
        self.privacyPolicyURL = privacyPolicyURL
    }
}
