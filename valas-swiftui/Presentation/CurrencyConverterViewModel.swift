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
        Task { @MainActor in
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
                Task { @MainActor in
                    await self?.fetchRates()
                }
            }
            .store(in: &cancellables)
        
        // React to currency changes
        Publishers.CombineLatest($baseCurrency, $targetCurrency)
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _, _ in
                Task { @MainActor in
                    await self?.fetchRates()
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    private func loadCurrencies() async {
        do {
            currencies = try await getCurrencies.execute()
            
            // Set default currencies if available
            if let eur = currencies.first(where: { $0.code == "EUR" }) {
                baseCurrency = eur
            }
            if let usd = currencies.first(where: { $0.code == "USD" }) {
                targetCurrency = usd
            }
        } catch {
            // Fallback to default currencies
            currencies = Currency.defaultCurrencies
        }
    }
    
    @MainActor
    func fetchRates() async {
        guard baseCurrency.code != targetCurrency.code else {
            currentRate = 1.0
            updateConvertedAmount()
            rateHistory = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch current rate
            let rate = try await getExchangeRate.execute(
                base: baseCurrency.code,
                target: targetCurrency.code
            )
            currentRate = rate.rate
            updateConvertedAmount()
            
            // Fetch 7-day history
            rateHistory = try await getRateHistory.execute(
                base: baseCurrency.code,
                target: targetCurrency.code,
                days: 7
            )
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to fetch exchange rates. Please try again."
            currentRate = nil
            convertedAmount = ""
            rateHistory = []
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
