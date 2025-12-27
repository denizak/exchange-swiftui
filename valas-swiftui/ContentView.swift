//
//  ContentView.swift
//  valas-swiftui
//
//  Created by deni zakya on 27.12.25.
//

import SwiftUI
import Charts

struct ContentView: View {
    @StateObject private var viewModel = CurrencyConverterViewModel.make()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Amount Input Section
                    amountInputSection
                    
                    // Currency Pickers Section
                    currencyPickersSection
                    
                    // Conversion Result Section
                    conversionResultSection
                    
                    // Rate History Chart Section
                    rateHistoryChartSection
                }
                .padding()
            }
            .navigationTitle("Currency Converter")
            .onAppear {
                viewModel.viewDidLoad()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
        }
    }
    
    // MARK: - Amount Input Section
    
    private var amountInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount")
                .font(.headline)
                .foregroundColor(.secondary)
            
            TextField("Enter amount", text: $viewModel.amount)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .font(.title2)
                .accessibilityIdentifier("amount_input")
        }
    }
    
    // MARK: - Currency Pickers Section
    
    private var currencyPickersSection: some View {
        VStack(spacing: 16) {
            // From Currency
            currencyPicker(
                title: "From",
                selection: $viewModel.baseCurrency,
                accessibilityId: "base_currency_picker"
            )
            
            // Swap Button
            Button(action: {
                viewModel.swapCurrencies()
            }) {
                Image(systemName: "arrow.up.arrow.down.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
            }
            .accessibilityIdentifier("swap_button")
            
            // To Currency
            currencyPicker(
                title: "To",
                selection: $viewModel.targetCurrency,
                accessibilityId: "target_currency_picker"
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func currencyPicker(title: String, selection: Binding<Currency>, accessibilityId: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)
            
            Picker(title, selection: selection) {
                ForEach(viewModel.currencies) { currency in
                    Text("\(currency.code) - \(currency.name)")
                        .tag(currency)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier(accessibilityId)
        }
    }
    
    // MARK: - Conversion Result Section
    
    private var conversionResultSection: some View {
        VStack(spacing: 8) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            } else if !viewModel.convertedAmount.isEmpty {
                VStack(spacing: 4) {
                    Text("\(viewModel.amount) \(viewModel.baseCurrency.code) =")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.convertedAmount) \(viewModel.targetCurrency.code)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                        .accessibilityIdentifier("converted_amount")
                    
                    if let rate = viewModel.currentRate {
                        Text("1 \(viewModel.baseCurrency.code) = \(String(format: "%.4f", rate)) \(viewModel.targetCurrency.code)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("current_rate")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Rate History Chart Section
    
    private var rateHistoryChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.rateHistory.isEmpty {
                Text("Last 7 Days")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Chart(viewModel.rateHistory) { item in
                    LineMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Rate", item.rate)
                    )
                    .foregroundStyle(Color.blue)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Rate", item.rate)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Rate", item.rate)
                    )
                    .foregroundStyle(Color.blue)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 1)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .accessibilityIdentifier("rate_chart")
            }
        }
    }
}

#Preview {
    ContentView()
}
