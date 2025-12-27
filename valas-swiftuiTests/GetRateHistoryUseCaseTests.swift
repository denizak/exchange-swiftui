//
//  GetRateHistoryUseCaseTests.swift
//  valas-swiftuiTests
//
//  Created by deni zakya on 27.12.25.
//

import XCTest
@testable import valas_swiftui

final class GetRateHistoryUseCaseTests: XCTestCase {
    
    func testExecute_onSuccess() async throws {
        // Given
        let expectedHistory = [
            RateHistory(date: Date().addingTimeInterval(-86400 * 2), rate: 1.04),
            RateHistory(date: Date().addingTimeInterval(-86400), rate: 1.05),
            RateHistory(date: Date(), rate: 1.06)
        ]
        let sut = GetRateHistoryUseCase(fetchRateHistory: { _, _, _, _ in
            expectedHistory
        })
        
        // When
        let result = try await sut.execute(base: "EUR", target: "USD", days: 7)
        
        // Then
        XCTAssertEqual(result, expectedHistory)
    }
    
    func testExecute_passesCorrectDateRange() async throws {
        // Given
        let fixedDate = Date()
        let calendar = Calendar.current
        var actualStartDate: Date?
        var actualEndDate: Date?
        
        let sut = GetRateHistoryUseCase(
            fetchRateHistory: { _, _, startDate, endDate in
                actualStartDate = startDate
                actualEndDate = endDate
                return []
            },
            calendar: calendar,
            currentDate: { fixedDate }
        )
        
        // When
        _ = try await sut.execute(base: "EUR", target: "USD", days: 7)
        
        // Then
        let expectedStartDate = calendar.date(byAdding: .day, value: -7, to: fixedDate)
        XCTAssertEqual(actualStartDate, expectedStartDate)
        XCTAssertEqual(actualEndDate, fixedDate)
    }
    
    func testExecute_passesCorrectCurrencies() async throws {
        // Given
        var actualBase: String?
        var actualTarget: String?
        
        let sut = GetRateHistoryUseCase(fetchRateHistory: { base, target, _, _ in
            actualBase = base
            actualTarget = target
            return []
        })
        
        // When
        _ = try await sut.execute(base: "GBP", target: "CHF", days: 7)
        
        // Then
        XCTAssertEqual(actualBase, "GBP")
        XCTAssertEqual(actualTarget, "CHF")
    }
    
    func testLeak() {
        let sut = GetRateHistoryUseCase(fetchRateHistory: { _, _, _, _ in [] })
        testMemoryLeak(sut)
    }
}
