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
    
    func testExecute_onNetworkError_throwsError() async {
        // Given
        let sut = GetCurrenciesUseCase(fetchCurrencies: {
            throw ExchangeRateError.networkError
        })
        
        // When/Then
        do {
            _ = try await sut.execute()
            XCTFail("Expected to throw networkError")
        } catch let error as ExchangeRateError {
            XCTAssertEqual(error, .networkError)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testExecute_returnsMultipleCurrencies() async throws {
        // Given
        let expectedCurrencies = [
            Currency(code: "EUR", name: "Euro"),
            Currency(code: "USD", name: "US Dollar"),
            Currency(code: "GBP", name: "British Pound"),
            Currency(code: "JPY", name: "Japanese Yen"),
            Currency(code: "CHF", name: "Swiss Franc")
        ]
        let sut = GetCurrenciesUseCase(fetchCurrencies: {
            expectedCurrencies
        })
        
        // When
        let result = try await sut.execute()
        
        // Then
        XCTAssertEqual(result.count, 5)
        XCTAssertEqual(result, expectedCurrencies)
    }
    
    func testExecute_isCalled() async throws {
        // Given
        var fetchCalled = false
        let sut = GetCurrenciesUseCase(fetchCurrencies: {
            fetchCalled = true
            return []
        })
        
        // When
        _ = try await sut.execute()
        
        // Then
        XCTAssertTrue(fetchCalled)
    }
    
    func testLeak() {
        let sut = GetCurrenciesUseCase(fetchCurrencies: { [] })
        testMemoryLeak(sut)
    }
}
