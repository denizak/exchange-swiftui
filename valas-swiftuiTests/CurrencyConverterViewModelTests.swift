//
//  CurrencyConverterViewModelTests.swift
//  valas-swiftuiTests
//
//  Created by deni zakya on 27.12.25.
//

import XCTest
import Combine
@testable import valas_swiftui

final class CurrencyConverterViewModelTests: XCTestCase {
    
    private var cancellables: Set<AnyCancellable> = []
    
    override func tearDown() {
        cancellables = []
    }
    
    // MARK: - Tests
    
    func testInitialState() {
        // Given
        let sut = makeSUT()
        
        // Then
        XCTAssertEqual(sut.amount, "1")
        XCTAssertEqual(sut.baseCurrency.code, "EUR")
        XCTAssertEqual(sut.targetCurrency.code, "USD")
        XCTAssertEqual(sut.convertedAmount, "")
        XCTAssertNil(sut.currentRate)
        XCTAssertTrue(sut.rateHistory.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testSwapCurrencies() {
        // Given
        let sut = makeSUT()
        let originalBase = sut.baseCurrency
        let originalTarget = sut.targetCurrency
        
        // When
        sut.swapCurrencies()
        
        // Then
        XCTAssertEqual(sut.baseCurrency, originalTarget)
        XCTAssertEqual(sut.targetCurrency, originalBase)
    }
    
    func testFetchRates_onSameCurrency() async {
        // Given
        let sut = makeSUT()
        sut.baseCurrency = Currency(code: "EUR", name: "Euro")
        sut.targetCurrency = Currency(code: "EUR", name: "Euro")
        
        // When
        await sut.fetchRates()
        
        // Then
        XCTAssertEqual(sut.currentRate, 1.0)
        XCTAssertTrue(sut.rateHistory.isEmpty)
    }
    
    func testFetchRates_onSuccess() async {
        // Given
        let expectedRate = ExchangeRate(base: "EUR", target: "USD", rate: 1.05, date: Date())
        let expectedHistory = [
            RateHistory(date: Date().addingTimeInterval(-86400), rate: 1.04),
            RateHistory(date: Date(), rate: 1.05)
        ]
        
        let getExchangeRate = GetExchangeRateUseCaseSpy(result: expectedRate)
        let getRateHistory = GetRateHistoryUseCaseSpy(result: expectedHistory)
        let getCurrencies = GetCurrenciesUseCaseSpy()
        
        let sut = CurrencyConverterViewModel(
            getExchangeRate: getExchangeRate,
            getRateHistory: getRateHistory,
            getCurrencies: getCurrencies
        )
        sut.amount = "100"
        
        // When
        await sut.fetchRates()
        
        // Then
        XCTAssertEqual(sut.currentRate, 1.05)
        XCTAssertEqual(sut.convertedAmount, "105.00")
        XCTAssertEqual(sut.rateHistory, expectedHistory)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testFetchRates_onError() async {
        // Given
        let getExchangeRate = GetExchangeRateUseCaseSpy(shouldThrow: true)
        let getRateHistory = GetRateHistoryUseCaseSpy()
        let getCurrencies = GetCurrenciesUseCaseSpy()
        
        let sut = CurrencyConverterViewModel(
            getExchangeRate: getExchangeRate,
            getRateHistory: getRateHistory,
            getCurrencies: getCurrencies
        )
        
        // When
        await sut.fetchRates()
        
        // Then
        XCTAssertNil(sut.currentRate)
        XCTAssertEqual(sut.convertedAmount, "")
        XCTAssertTrue(sut.rateHistory.isEmpty)
        XCTAssertNotNil(sut.errorMessage)
    }
    
    func testLeak() {
        let sut = makeSUT()
        testMemoryLeak(sut)
    }
    
    // MARK: - Helpers
    
    private func makeSUT() -> CurrencyConverterViewModel {
        CurrencyConverterViewModel(
            getExchangeRate: GetExchangeRateUseCaseSpy(),
            getRateHistory: GetRateHistoryUseCaseSpy(),
            getCurrencies: GetCurrenciesUseCaseSpy()
        )
    }
}

// MARK: - Test Doubles

private final class GetExchangeRateUseCaseSpy: GetExchangeRateUseCaseProtocol {
    var result: ExchangeRate?
    var shouldThrow: Bool
    
    init(result: ExchangeRate? = nil, shouldThrow: Bool = false) {
        self.result = result
        self.shouldThrow = shouldThrow
    }
    
    func execute(base: String, target: String) async throws -> ExchangeRate {
        if shouldThrow {
            throw ExchangeRateError.networkError
        }
        return result ?? ExchangeRate(base: base, target: target, rate: 1.0, date: Date())
    }
}

private final class GetRateHistoryUseCaseSpy: GetRateHistoryUseCaseProtocol {
    var result: [RateHistory]
    var shouldThrow: Bool
    
    init(result: [RateHistory] = [], shouldThrow: Bool = false) {
        self.result = result
        self.shouldThrow = shouldThrow
    }
    
    func execute(base: String, target: String, days: Int) async throws -> [RateHistory] {
        if shouldThrow {
            throw ExchangeRateError.networkError
        }
        return result
    }
}

private final class GetCurrenciesUseCaseSpy: GetCurrenciesUseCaseProtocol {
    var result: [Currency]
    var shouldThrow: Bool
    
    init(result: [Currency] = Currency.defaultCurrencies, shouldThrow: Bool = false) {
        self.result = result
        self.shouldThrow = shouldThrow
    }
    
    func execute() async throws -> [Currency] {
        if shouldThrow {
            throw ExchangeRateError.networkError
        }
        return result
    }
}
