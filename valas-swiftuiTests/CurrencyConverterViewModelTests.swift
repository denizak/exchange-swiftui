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
    
    func testViewDidLoad_loadsAndSetsCurrencies() async {
        // Given
        let expectedCurrencies = [
            Currency(code: "EUR", name: "Euro"),
            Currency(code: "USD", name: "US Dollar"),
            Currency(code: "GBP", name: "British Pound")
        ]
        let getCurrencies = GetCurrenciesUseCaseSpy(result: expectedCurrencies)
        let sut = CurrencyConverterViewModel(
            getExchangeRate: GetExchangeRateUseCaseSpy(),
            getRateHistory: GetRateHistoryUseCaseSpy(),
            getCurrencies: getCurrencies
        )
        
        // When
        sut.viewDidLoad()
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertEqual(sut.currencies.count, 3)
        XCTAssertEqual(sut.baseCurrency.code, "EUR")
        XCTAssertEqual(sut.targetCurrency.code, "USD")
    }
    
    func testViewDidLoad_onCurrencyLoadError_usesDefaults() async {
        // Given
        let getCurrencies = GetCurrenciesUseCaseSpy(shouldThrow: true)
        let sut = CurrencyConverterViewModel(
            getExchangeRate: GetExchangeRateUseCaseSpy(),
            getRateHistory: GetRateHistoryUseCaseSpy(),
            getCurrencies: getCurrencies
        )
        
        // When
        sut.viewDidLoad()
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(sut.currencies, Currency.defaultCurrencies)
    }
    
    func testAmountUpdate_withDecimalSeparator() async {
        // Given
        let expectedRate = ExchangeRate(base: "EUR", target: "USD", rate: 1.05, date: Date())
        let sut = CurrencyConverterViewModel(
            getExchangeRate: GetExchangeRateUseCaseSpy(result: expectedRate),
            getRateHistory: GetRateHistoryUseCaseSpy(),
            getCurrencies: GetCurrenciesUseCaseSpy()
        )
        sut.amount = "100,50" // European decimal format
        
        // When
        await sut.fetchRates()
        
        // Then
        XCTAssertEqual(sut.convertedAmount, "105.53") // 100.50 * 1.05
    }
    
    func testAmountUpdate_withInvalidValue() async {
        // Given
        let expectedRate = ExchangeRate(base: "EUR", target: "USD", rate: 1.05, date: Date())
        let sut = CurrencyConverterViewModel(
            getExchangeRate: GetExchangeRateUseCaseSpy(result: expectedRate),
            getRateHistory: GetRateHistoryUseCaseSpy(),
            getCurrencies: GetCurrenciesUseCaseSpy()
        )
        sut.amount = "invalid"
        
        // When
        await sut.fetchRates()
        
        // Then
        XCTAssertEqual(sut.convertedAmount, "")
    }
    
    func testFetchRates_setsLoadingState() async {
        // Given
        let expectation = expectation(description: "Loading state observed")
        var loadingStates: [Bool] = []
        
        let sut = CurrencyConverterViewModel(
            getExchangeRate: GetExchangeRateUseCaseSpy(),
            getRateHistory: GetRateHistoryUseCaseSpy(),
            getCurrencies: GetCurrenciesUseCaseSpy()
        )
        
        sut.$isLoading
            .dropFirst() // Skip initial value
            .sink { isLoading in
                loadingStates.append(isLoading)
                if loadingStates.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await sut.fetchRates()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(loadingStates, [true, false])
    }
    
    func testFetchRates_clearsErrorOnSuccess() async {
        // Given
        let sut = CurrencyConverterViewModel(
            getExchangeRate: GetExchangeRateUseCaseSpy(),
            getRateHistory: GetRateHistoryUseCaseSpy(),
            getCurrencies: GetCurrenciesUseCaseSpy()
        )
        sut.errorMessage = "Previous error"
        
        // When
        await sut.fetchRates()
        
        // Then
        XCTAssertNil(sut.errorMessage)
    }
    
    func testFetchRates_bothRequestsFail() async {
        // Given
        let sut = CurrencyConverterViewModel(
            getExchangeRate: GetExchangeRateUseCaseSpy(shouldThrow: true),
            getRateHistory: GetRateHistoryUseCaseSpy(shouldThrow: true),
            getCurrencies: GetCurrenciesUseCaseSpy()
        )
        
        // When
        await sut.fetchRates()
        
        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertNil(sut.currentRate)
        XCTAssertTrue(sut.rateHistory.isEmpty)
        XCTAssertEqual(sut.convertedAmount, "")
        XCTAssertFalse(sut.isLoading)
    }
    
    func testSwapCurrencies_triggersNewFetch() async {
        // Given
        let expectation = expectation(description: "Fetch triggered")
        var fetchCount = 0
        
        let getExchangeRate = GetExchangeRateUseCaseSpy()
        let sut = CurrencyConverterViewModel(
            getExchangeRate: getExchangeRate,
            getRateHistory: GetRateHistoryUseCaseSpy(),
            getCurrencies: GetCurrenciesUseCaseSpy()
        )
        
        sut.$currentRate
            .dropFirst()
            .sink { _ in
                fetchCount += 1
                if fetchCount >= 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        sut.swapCurrencies()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertGreaterThan(fetchCount, 0)
    }
    
    func testConvertedAmount_formatsCorrectly() async {
        // Given
        let expectedRate = ExchangeRate(base: "EUR", target: "USD", rate: 1.23456789, date: Date())
        let sut = CurrencyConverterViewModel(
            getExchangeRate: GetExchangeRateUseCaseSpy(result: expectedRate),
            getRateHistory: GetRateHistoryUseCaseSpy(),
            getCurrencies: GetCurrenciesUseCaseSpy()
        )
        sut.amount = "10"
        
        // When
        await sut.fetchRates()
        
        // Then
        XCTAssertEqual(sut.convertedAmount, "12.35") // Formatted to 2 decimals
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
