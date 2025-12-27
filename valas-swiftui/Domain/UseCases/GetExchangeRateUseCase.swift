//
//  GetExchangeRateUseCase.swift
//  valas-swiftui
//
//  Created by deni zakya on 27.12.25.
//

import Foundation

protocol GetExchangeRateUseCaseProtocol {
    func execute(base: String, target: String) async throws -> ExchangeRate
}

final class GetExchangeRateUseCase: GetExchangeRateUseCaseProtocol {
    
    typealias FetchLatestRate = (String, String) async throws -> ExchangeRate?
    
    private let fetchLatestRate: FetchLatestRate
    
    init(fetchLatestRate: @escaping FetchLatestRate) {
        self.fetchLatestRate = fetchLatestRate
    }
    
    func execute(base: String, target: String) async throws -> ExchangeRate {
        guard let rate = try await fetchLatestRate(base, target) else {
            throw ExchangeRateError.rateNotFound
        }
        return rate
    }
}

enum ExchangeRateError: Error, Equatable {
    case rateNotFound
    case networkError
    case invalidData
}
