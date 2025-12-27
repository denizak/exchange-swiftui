//
//  UseCaseFactory.swift
//  valas-swiftui
//
//  Created by deni zakya on 27.12.25.
//

import Foundation

enum UseCaseFactory {
    static func makeGetExchangeRateUseCase() -> GetExchangeRateUseCase {
        let requester = ExchangeRateRequester()
        return GetExchangeRateUseCase(fetchLatestRate: { base, target in
            try await requester.getLatestRate(base: base, target: target)
        })
    }
    
    static func makeGetRateHistoryUseCase() -> GetRateHistoryUseCase {
        let requester = ExchangeRateRequester()
        return GetRateHistoryUseCase(fetchRateHistory: { base, target, startDate, endDate in
            try await requester.getRateHistory(base: base, target: target, startDate: startDate, endDate: endDate)
        })
    }
    
    static func makeGetCurrenciesUseCase() -> GetCurrenciesUseCase {
        let requester = ExchangeRateRequester()
        return GetCurrenciesUseCase(fetchCurrencies: {
            try await requester.getCurrencies()
        })
    }
}
