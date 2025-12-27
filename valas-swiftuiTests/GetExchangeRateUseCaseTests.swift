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
    
    func testLeak() {
        let sut = GetExchangeRateUseCase(fetchLatestRate: { _, _ in nil })
        testMemoryLeak(sut)
    }
}
