//
//  ExchangeRateRequesterTests.swift
//  valas-swiftuiIntegrationTests
//
//  Created by deni zakya on 27.12.25.
//

import XCTest
@testable import valas_swiftui

final class ExchangeRateRequesterIntegrationTests: XCTestCase {
    
    func testGetLatestRate() async throws {
        let sut = ExchangeRateRequester()
        
        let result = try await sut.getLatestRate(base: "EUR", target: "USD")
        
        let unwrappedResult = try XCTUnwrap(result)
        XCTAssertEqual(unwrappedResult.base, "EUR")
        XCTAssertEqual(unwrappedResult.target, "USD")
        XCTAssertGreaterThan(unwrappedResult.rate, 0)
    }
    
    func testGetRateHistory() async throws {
        let sut = ExchangeRateRequester()
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
        
        let result = try await sut.getRateHistory(
            base: "EUR",
            target: "USD",
            startDate: startDate,
            endDate: endDate
        )
        
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.allSatisfy { $0.rate > 0 })
    }
    
    func testGetCurrencies() async throws {
        let sut = ExchangeRateRequester()
        
        let result = try await sut.getCurrencies()
        
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains(where: { $0.code == "EUR" }))
        XCTAssertTrue(result.contains(where: { $0.code == "USD" }))
    }
}
