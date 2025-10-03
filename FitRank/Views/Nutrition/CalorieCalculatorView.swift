//
//  CalorieCalculatorView.swift
//  FitRank
//

import SwiftUI

struct CalorieCalculatorView: View {
    @StateObject private var viewModel = CalorieCalculatorViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingResults = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Unit System Toggle
                        unitSystemSection
                        
                        // Input Form
                        inputFormSection
                        
                        // Calculate Button
                        calculateButton
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Calorie Calculator")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingResults) {
                if let calculation = viewModel.calculation {
                    CalorieResultsView(calculation: calculation) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .padding(.top, 20)
            
            Text("Calorie Calculator")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Calculate your daily calorie needs for weight loss, maintenance, or muscle gain")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var unitSystemSection: some View {
        VStack(spacing: 12) {
            Text("Unit System")
                .font(.headline)
                .foregroundColor(.primary)
            
            Picker("Unit System", selection: $viewModel.userProfile.unitSystem) {
                ForEach(UnitSystem.allCases) { system in
                    Text(system.rawValue).tag(system)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: viewModel.userProfile.unitSystem) { _ in
                viewModel.updateUnits()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var inputFormSection: some View {
        VStack(spacing: 20) {
            // Age
            VStack(alignment: .leading, spacing: 8) {
                Text("Age")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    TextField("Age", value: $viewModel.userProfile.age, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("years")
                        .foregroundColor(.secondary)
                }
            }
            
            // Gender
            VStack(alignment: .leading, spacing: 8) {
                Text("Gender")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Picker("Gender", selection: $viewModel.userProfile.gender) {
                    ForEach(Gender.allCases) { gender in
                        Text(gender.rawValue).tag(gender)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Weight (Dynamic based on unit system)
            weightInputSection
            
            // Height (Dynamic based on unit system)
            heightInputSection
            
            // Activity Level
            VStack(alignment: .leading, spacing: 8) {
                Text("Activity Level")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Picker("Activity Level", selection: $viewModel.userProfile.activityLevel) {
                    ForEach(ActivityLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 100)
            }
            
            // Goal
            VStack(alignment: .leading, spacing: 8) {
                Text("Goal")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Picker("Goal", selection: $viewModel.userProfile.goal) {
                    ForEach(Goal.allCases) { goal in
                        Text(goal.rawValue).tag(goal)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var weightInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weight")
                .font(.headline)
                .foregroundColor(.primary)
            
            if viewModel.userProfile.unitSystem == .metric {
                HStack {
                    TextField("Weight", value: $viewModel.userProfile.weight, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("kg")
                        .foregroundColor(.secondary)
                        .frame(width: 40)
                }
            } else {
                HStack {
                    TextField("Weight", value: $viewModel.weightPounds, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("lbs")
                        .foregroundColor(.secondary)
                        .frame(width: 40)
                }
            }
        }
    }
    
    private var heightInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Height")
                .font(.headline)
                .foregroundColor(.primary)
            
            if viewModel.userProfile.unitSystem == .metric {
                HStack {
                    TextField("Height", value: $viewModel.userProfile.height, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("cm")
                        .foregroundColor(.secondary)
                        .frame(width: 40)
                }
            } else {
                VStack(spacing: 8) {
                    HStack {
                        Text("Feet")
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        
                        Picker("Feet", selection: $viewModel.heightFeet) {
                            ForEach(3...8, id: \.self) { feet in
                                Text("\(feet)").tag(feet)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 80)
                        
                        Text("ft")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Inches")
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        
                        Picker("Inches", selection: $viewModel.heightInches) {
                            ForEach(0...11, id: \.self) { inches in
                                Text("\(inches)").tag(inches)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 80)
                        
                        Text("in")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var calculateButton: some View {
        Button(action: {
            viewModel.calculateCalories()
            if viewModel.calculation != nil {
                showingResults = true
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Calculate My Calories")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(viewModel.isFormValid ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .disabled(!viewModel.isFormValid || viewModel.isLoading)
    }
}

#Preview {
    CalorieCalculatorView()
}
