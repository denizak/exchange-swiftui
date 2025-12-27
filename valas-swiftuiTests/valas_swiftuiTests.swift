//
//  valas_swiftuiTests.swift
//  valas-swiftuiTests
//
//  Created by deni zakya on 27.12.25.
//

import Testing
import Foundation
@testable import valas_swiftui

struct valas_swiftuiTests {

    @Test func currencyEquality() async throws {
        let currency1 = Currency(code: "EUR", name: "Euro")
        let currency2 = Currency(code: "EUR", name: "Euro")
        let currency3 = Currency(code: "USD", name: "US Dollar")
        
        #expect(currency1 == currency2)
        #expect(currency1 != currency3)
    }
    
    @Test func exchangeRateEquality() async throws {
        let date = Date()
        let rate1 = ExchangeRate(base: "EUR", target: "USD", rate: 1.05, date: date)
        let rate2 = ExchangeRate(base: "EUR", target: "USD", rate: 1.05, date: date)
        
        #expect(rate1 == rate2)
    }
    
    @Test func rateHistoryIdentifiable() async throws {
        let date = Date()
        let history = RateHistory(date: date, rate: 1.05)
        
        #expect(history.id == date)
    }
}
