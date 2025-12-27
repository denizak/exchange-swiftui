//
//  ExchangeRate.swift
//  valas-swiftui
//
//  Created by deni zakya on 27.12.25.
//

import Foundation

struct ExchangeRate: Equatable {
    let base: String
    let target: String
    let rate: Double
    let date: Date
}

struct RateHistory: Equatable, Identifiable {
    let date: Date
    let rate: Double
    
    var id: Date { date }
}
