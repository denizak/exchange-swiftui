//
//  GetExchangeRateUseCaseTests.swift
//  valas-swiftuiTests
//
//  Created by deni zakya on 27.12.25.
//

import XCTest
@testable import valas_swiftui

final class GetExchangeRateUseCaseTests: XCTestCase {
    
    func testExecute_onSuccess() async throws {
        // Given
        let expectedRate = ExchangeRate(
            base: "EUR",
            target: "USD",
            rate: 1.05,
            date: Date()
        )
        let sut = GetExchangeRateUseCase(fetchLatestRate: { _, _ in
            expectedRate
        })
        
        // When
        let result = try await sut.execute(base: "EUR", target: "USD")
        
        // Then
        XCTAssertEqual(result, expectedRate)
    }
    
    func testExecute_onNilRate_throwsError() async {
        // Given
        let sut = GetExchangeRateUseCase(fetchLatestRate: { _, _ in
            nil
        })
        
        // When/Then
        do {
            _ = try await sut.execute(base: "EUR", target: "USD")
            XCTFail("Expected to throw rateNotFound error")
        } catch let error as ExchangeRateError {
            XCTAssertEqual(error, .rateNotFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testExecute_passesCorrectParameters() async throws {
        // Given
        var actualBase: String?
        var actualTarget: String?
        let sut = GetExchangeRateUseCase(fetchLatestRate: { base, target in
            actualBase = base
            actualTarget = target
            return ExchangeRate(base: base, target: target, rate: 1.0, date: Date())
        })
        
        // When
        _ = try await sut.execute(base: "GBP", target: "JPY")
        
        // Then
        XCTAssertEqual(actualBase, "GBP")
        XCTAssertEqual(actualTarget, "JPY")
    }
    
    func testExecute_onNetworkError_throwsError() async {
        // Given
        let sut = GetExchangeRateUseCase(fetchLatestRate: { _, _ in
            throw ExchangeRateError.networkError
        })
        
        // When/Then
        do {
            _ = try await sut.execute(base: "EUR", target: "USD")
            XCTFail("Expected to throw networkError")
        } catch let error as ExchangeRateError {
            XCTAssertEqual(error, .networkError)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testExecute_withDifferentCurrencyPairs() async throws {
        // Given
        let testCases = [
            ("EUR", "USD", 1.05),
            ("GBP", "JPY", 180.50),
            ("CHF", "CAD", 1.52)
        ]
        
        for (base, target, expectedRate) in testCases {
            let sut = GetExchangeRateUseCase(fetchLatestRate: { _, _ in
                ExchangeRate(base: base, target: target, rate: expectedRate, date: Date())
            })
            
            // When
            let result = try await sut.execute(base: base, target: target)
            
            // Then
            XCTAssertEqual(result.base, base, "Base currency mismatch for \(base)/\(target)")
            XCTAssertEqual(result.target, target, "Target currency mismatch for \(base)/\(target)")
            XCTAssertEqual(result.rate, expectedRate, "Rate mismatch for \(base)/\(target)")
        }
    }
    
    func testLeak() {
        let sut = GetExchangeRateUseCase(fetchLatestRate: { _, _ in nil })
        testMemoryLeak(sut)
    }
}
