//
//  Currency.swift
//  valas-swiftui
//
//  Created by deni zakya on 27.12.25.
//

import Foundation

struct Currency: Equatable, Hashable, Identifiable {
    let code: String
    let name: String
    
    var id: String { code }
}

extension Currency {
    static let defaultCurrencies: [Currency] = [
        Currency(code: "EUR", name: "Euro"),
        Currency(code: "USD", name: "US Dollar"),
        Currency(code: "GBP", name: "British Pound"),
        Currency(code: "JPY", name: "Japanese Yen"),
        Currency(code: "AUD", name: "Australian Dollar"),
        Currency(code: "CAD", name: "Canadian Dollar"),
        Currency(code: "CHF", name: "Swiss Franc"),
        Currency(code: "CNY", name: "Chinese Yuan"),
        Currency(code: "SEK", name: "Swedish Krona"),
        Currency(code: "NZD", name: "New Zealand Dollar")
    ]
}
