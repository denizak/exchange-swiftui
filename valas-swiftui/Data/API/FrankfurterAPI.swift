//
//  FrankfurterAPI.swift
//  valas-swiftui
//
//  Created by deni zakya on 27.12.25.
//

import Foundation

struct FrankfurterAPI {
    private static let baseURL = "https://api.frankfurter.dev/v1"
    
    static func makeURL(path: String, params: [String: String] = [:]) -> URL? {
        var urlComponents = URLComponents(string: "\(baseURL)\(path)")
        if !params.isEmpty {
            urlComponents?.queryItems = params.map { key, value in
                URLQueryItem(name: key, value: value)
            }
        }
        return urlComponents?.url
    }
}

// MARK: - Response Models

struct LatestRateResponse: Decodable {
    let base: String
    let date: String
    let rates: [String: Double]
}

struct TimeSeriesResponse: Decodable {
    let base: String
    let startDate: String
    let endDate: String
    let rates: [String: [String: Double]]
    
    enum CodingKeys: String, CodingKey {
        case base
        case startDate = "start_date"
        case endDate = "end_date"
        case rates
    }
}

struct CurrenciesResponse: Decodable {
    let currencies: [String: String]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        currencies = try container.decode([String: String].self)
    }
}
