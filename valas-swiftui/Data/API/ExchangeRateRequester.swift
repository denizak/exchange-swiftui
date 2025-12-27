//
//  ExchangeRateRequester.swift
//  valas-swiftui
//
//  Created by deni zakya on 27.12.25.
//

import Foundation

struct ExchangeRateRequester {
    private let decoder = JSONDecoder()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    func getLatestRate(base: String, target: String) async throws -> ExchangeRate? {
        let params = [
            "base": base,
            "symbols": target
        ]
        
        guard let url = FrankfurterAPI.makeURL(path: "/latest", params: params) else {
            throw ExchangeRateError.invalidData
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(LatestRateResponse.self, from: data)
        
        guard let rate = response.rates[target],
              let date = dateFormatter.date(from: response.date) else {
            return nil
        }
        
        return ExchangeRate(base: response.base, target: target, rate: rate, date: date)
    }
    
    func getRateHistory(base: String, target: String, startDate: Date, endDate: Date) async throws -> [RateHistory] {
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        let path = "/\(startDateString)..\(endDateString)"
        let params = [
            "base": base,
            "symbols": target
        ]
        
        guard let url = FrankfurterAPI.makeURL(path: path, params: params) else {
            throw ExchangeRateError.invalidData
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(TimeSeriesResponse.self, from: data)
        
        return response.rates.compactMap { dateString, rates in
            guard let rate = rates[target],
                  let date = dateFormatter.date(from: dateString) else {
                return nil
            }
            return RateHistory(date: date, rate: rate)
        }.sorted { $0.date < $1.date }
    }
    
    func getCurrencies() async throws -> [Currency] {
        guard let url = FrankfurterAPI.makeURL(path: "/currencies") else {
            throw ExchangeRateError.invalidData
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(CurrenciesResponse.self, from: data)
        
        return response.currencies.map { code, name in
            Currency(code: code, name: name)
        }.sorted { $0.code < $1.code }
    }
}
