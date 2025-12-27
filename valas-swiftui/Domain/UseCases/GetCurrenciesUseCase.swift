//
//  GetCurrenciesUseCase.swift
//  valas-swiftui
//
//  Created by deni zakya on 27.12.25.
//

import Foundation

protocol GetCurrenciesUseCaseProtocol {
    func execute() async throws -> [Currency]
}

final class GetCurrenciesUseCase: GetCurrenciesUseCaseProtocol {
    
    typealias FetchCurrencies = () async throws -> [Currency]
    
    private let fetchCurrencies: FetchCurrencies
    
    init(fetchCurrencies: @escaping FetchCurrencies) {
        self.fetchCurrencies = fetchCurrencies
    }
    
    func execute() async throws -> [Currency] {
        try await fetchCurrencies()
    }
}
