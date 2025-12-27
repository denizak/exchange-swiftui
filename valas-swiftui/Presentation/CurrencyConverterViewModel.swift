//
//  CurrencyConverterViewModel.swift
//  valas-swiftui
//
//  Created by deni zakya on 27.12.25.
//

import Foundation
import Combine

final class CurrencyConverterViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var amount: String = "1"
    @Published var baseCurrency: Currency = Currency(code: "EUR", name: "Euro")
    @Published var targetCurrency: Currency = Currency(code: "USD", name: "US Dollar")
    @Published var currencies: [Currency] = []
    @Published var convertedAmount: String = ""
    @Published var currentRate: Double?
    @Published var rateHistory: [RateHistory] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let getExchangeRate: GetExchangeRateUseCaseProtocol
    private let getRateHistory: GetRateHistoryUseCaseProtocol
    private let getCurrencies: GetCurrenciesUseCaseProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(getExchangeRate: GetExchangeRateUseCaseProtocol,
         getRateHistory: GetRateHistoryUseCaseProtocol,
         getCurrencies: GetCurrenciesUseCaseProtocol) {
        self.getExchangeRate = getExchangeRate
        self.getRateHistory = getRateHistory
        self.getCurrencies = getCurrencies
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    func viewDidLoad() {
        Task {
            await loadCurrencies()
            await fetchRates()
        }
    }
    
    func swapCurrencies() {
        let temp = baseCurrency
        baseCurrency = targetCurrency
        targetCurrency = temp
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Debounce amount changes and fetch rates
        $amount
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                Task {
                    await self?.fetchRates()
                }
            }
            .store(in: &cancellables)
        
        // React to currency changes
        Publishers.CombineLatest($baseCurrency, $targetCurrency)
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _, _ in
                Task {
                    await self?.fetchRates()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadCurrencies() async {
        do {
            // Network call happens off main thread
            let fetchedCurrencies = try await getCurrencies.execute()
            
            // Update UI properties on main thread
            await MainActor.run {
                self.currencies = fetchedCurrencies
                
                // Set default currencies if available
                if let eur = fetchedCurrencies.first(where: { $0.code == "EUR" }) {
                    self.baseCurrency = eur
                }
                if let usd = fetchedCurrencies.first(where: { $0.code == "USD" }) {
                    self.targetCurrency = usd
                }
            }
        } catch {
            // Fallback to default currencies
            await MainActor.run {
                self.currencies = Currency.defaultCurrencies
            }
        }
    }
    
    func fetchRates() async {
        let base = await MainActor.run { baseCurrency.code }
        let target = await MainActor.run { targetCurrency.code }
        
        guard base != target else {
            await MainActor.run {
                currentRate = 1.0
                updateConvertedAmount()
                rateHistory = []
            }
            return
        }
        
        await MainActor.run { 
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Network calls happen off main thread
            let rate = try await getExchangeRate.execute(base: base, target: target)
            let history = try await getRateHistory.execute(base: base, target: target, days: 7)
            
            // Update UI properties on main thread
            await MainActor.run {
                self.currentRate = rate.rate
                self.updateConvertedAmount()
                self.rateHistory = history
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                
                // Provide more specific error messages
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet:
                        self.errorMessage = "No internet connection. Please check your network."
                    case .cannotFindHost, .cannotConnectToHost:
                        self.errorMessage = "Cannot reach the server. Please check your connection or try again later."
                    case .timedOut:
                        self.errorMessage = "Request timed out. Please try again."
                    default:
                        self.errorMessage = "Network error occurred. Please try again."
                    }
                } else {
                    self.errorMessage = "Failed to fetch exchange rates. Please try again."
                }
                
                self.currentRate = nil
                self.convertedAmount = ""
                self.rateHistory = []
            }
        }
    }
    
    private func updateConvertedAmount() {
        guard let rate = currentRate,
              let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            convertedAmount = ""
            return
        }
        
        let converted = amountValue * rate
        convertedAmount = String(format: "%.2f", converted)
    }
}

// MARK: - Factory

extension CurrencyConverterViewModel {
    static func make() -> CurrencyConverterViewModel {
        CurrencyConverterViewModel(
            getExchangeRate: UseCaseFactory.makeGetExchangeRateUseCase(),
            getRateHistory: UseCaseFactory.makeGetRateHistoryUseCase(),
            getCurrencies: UseCaseFactory.makeGetCurrenciesUseCase()
        )
    }
}
