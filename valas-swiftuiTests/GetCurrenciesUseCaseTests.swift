//
//  GetCurrenciesUseCaseTests.swift
//  valas-swiftuiTests
//
//  Created by deni zakya on 27.12.25.
//

import XCTest
@testable import valas_swiftui

final class GetCurrenciesUseCaseTests: XCTestCase {
    
    func testExecute_onSuccess() async throws {
        // Given
        let expectedCurrencies = [
            Currency(code: "EUR", name: "Euro"),
            Currency(code: "USD", name: "US Dollar"),
            Currency(code: "GBP", name: "British Pound")
        ]
        let sut = GetCurrenciesUseCase(fetchCurrencies: {
            expectedCurrencies
        })
        
        // When
        let result = try await sut.execute()
        
        // Then
        XCTAssertEqual(result, expectedCurrencies)
    }
    
    func testExecute_onEmptyResult() async throws {
        // Given
        let sut = GetCurrenciesUseCase(fetchCurrencies: {
            []
        })
        
        // When
        let result = try await sut.execute()
        
        // Then
        XCTAssertTrue(result.isEmpty)
    }
    
    func testLeak() {
        let sut = GetCurrenciesUseCase(fetchCurrencies: { [] })
        testMemoryLeak(sut)
    }
}
