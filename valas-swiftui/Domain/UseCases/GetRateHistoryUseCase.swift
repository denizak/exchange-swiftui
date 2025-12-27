//
//  GetRateHistoryUseCase.swift
//  valas-swiftui
//
//  Created by deni zakya on 27.12.25.
//

import Foundation

protocol GetRateHistoryUseCaseProtocol {
    func execute(base: String, target: String, days: Int) async throws -> [RateHistory]
}

final class GetRateHistoryUseCase: GetRateHistoryUseCaseProtocol {
    
    typealias FetchRateHistory = (String, String, Date, Date) async throws -> [RateHistory]
    
    private let fetchRateHistory: FetchRateHistory
    private let calendar: Calendar
    private let currentDate: () -> Date
    
    init(fetchRateHistory: @escaping FetchRateHistory,
         calendar: Calendar = .current,
         currentDate: @escaping () -> Date = { Date() }) {
        self.fetchRateHistory = fetchRateHistory
        self.calendar = calendar
        self.currentDate = currentDate
    }
    
    func execute(base: String, target: String, days: Int) async throws -> [RateHistory] {
        let endDate = currentDate()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            throw ExchangeRateError.invalidData
        }
        
        return try await fetchRateHistory(base, target, startDate, endDate)
    }
}
