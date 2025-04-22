//
//  SettingsView.swift
//  WeatherApp
//
//  Created by Tumuhirwe Iden on 22/04/2025.
//


import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("useMetric") private var useMetric = true
    @AppStorage("hourFormat") private var hourFormat = "12h"
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("refreshFrequency") private var refreshFrequency = 30
    
    @State private var showingColorPicker = false
    @State private var selectedColor: Color = .blue
    
    private let refreshOptions = [15, 30, 60, 120]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Appearance")) {
                    // Theme
                    Picker("Theme", selection: $themeManager.selectedTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            HStack {
                                Image(systemName: theme.icon)
                                Text(theme.displayName)
                            }
                            .tag(theme)
                        }
                    }
                    .pickerStyle(NavigationLinkPickerStyle())
                    
                    // Accent Color
                    Button(action: {
                        showingColorPicker = true
                        selectedColor = themeManager.accentColor
                    }) {
                        HStack {
                            Text("Accent Color")
                            Spacer()
                            Circle()
                                .fill(themeManager.accentColor)
                                .frame(width: 24, height: 24)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                Section(header: Text("Units")) {
                    // Temperature
                    Picker("Temperature", selection: $useMetric) {
                        Text("Celsius (°C)").tag(true)
                        Text("Fahrenheit (°F)").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // Hour Format
                    Picker("Time Format", selection: $hourFormat) {
                        Text("12h").tag("12h")
                        Text("24h").tag("24h")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Notifications")) {
                    Toggle("Weather Alerts", isOn: $notificationsEnabled)
                        .tint(themeManager.accentColor)
                    
                    if notificationsEnabled {
                        // Toggle for different notification types
                        NavigationLink(destination: NotificationSettingsView()) {
                            Text("Notification Settings")
                        }
                    }
                }
                
                Section(header: Text("Data")) {
                    Picker("Auto-Refresh", selection: $refreshFrequency) {
                        ForEach(refreshOptions, id: \.self) { minutes in
                            Text("\(minutes) minutes").tag(minutes)
                        }
                    }
                    .pickerStyle(NavigationLinkPickerStyle())
                    
                    Button(action: clearCacheAction) {
                        Text("Clear Cache")
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("About")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weather App")
                            .font(.headline)
                        Text("Version 1.1.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Text("Privacy Policy")
                    }
                    
                    Button(action: rateAppAction) {
                        Text("Rate the App")
                    }
                    
                    Button(action: shareAppAction) {
                        Text("Share with Friends")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPickerView(selectedColor: $selectedColor, onColorSelected: { color in
                    themeManager.accentColor = color
                    showingColorPicker = false
                })
            }
        }
    }
    
    private func clearCacheAction() {
        // Clear the weather data cache
        // This is a placeholder - implement actual cache clearing logic
        print("Cache cleared")
    }
    
    private func rateAppAction() {
        // Open app in App Store for rating
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id123456789?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
    
    private func shareAppAction() {
        // Show share sheet for the app
        let appURL = "https://apps.apple.com/app/id123456789"
        let activityVC = UIActivityViewController(
            activityItems: ["Check out this amazing Weather App: \(appURL)"],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

struct NotificationSettingsView: View {
    @AppStorage("severeWeatherAlerts") private var severeWeatherAlerts = true
    @AppStorage("dailyForecastAlerts") private var dailyForecastAlerts = true
    @AppStorage("rainAlerts") private var rainAlerts = true
    @AppStorage("notificationTimeDaily") private var notificationTimeDaily = 8 // 8 AM
    
    var body: some View {
        List {
            Section(header: Text("Alert Types")) {
                Toggle("Severe Weather", isOn: $severeWeatherAlerts)
                Toggle("Daily Forecast", isOn: $dailyForecastAlerts)
                Toggle("Rain Alerts", isOn: $rainAlerts)
            }
            
            if dailyForecastAlerts {
                Section(header: Text("Daily Forecast Time")) {
                    Picker("Time", selection: $notificationTimeDaily) {
                        ForEach(5..<23) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }
            }
            
            Section(footer: Text("Weather alerts require location permission.")) {
                Button("Request Notifications") {
                    requestNotificationPermission()
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Notification Settings")
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:00 a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("Notification permission granted: \(granted)")
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Effective Date: April 22, 2025")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("1. Information We Collect")
                        .font(.headline)
                    
                    Text("We collect your location data to provide accurate weather information for your area. This data is only used to fetch weather information and is not stored on our servers.")
                    
                    Text("2. How We Use Your Information")
                        .font(.headline)
                    
                    Text("Your location data is only used to provide you with relevant weather information. We do not share this data with third parties except to the extent necessary to provide the weather service (i.e., making API calls to weather data providers).")
                                        
                                        Text("3. Data Storage")
                                            .font(.headline)
                                        
                                        Text("We store your preferences (such as your preferred units and theme) locally on your device. Your last searched locations are also stored locally to improve your experience.")
                                        
                                        Text("4. Permissions")
                                            .font(.headline)
                                        
                                        Text("The app requires the following permissions:")
                                            .padding(.bottom, 5)
                                        
                                        Text("• Location access: To provide weather data for your current location")
                                        Text("• Notification access: To send you weather alerts (optional)")
                                        
                                        Text("5. Contact Us")
                                            .font(.headline)
                                        
                                        Text("If you have any questions about this Privacy Policy, please contact us at support@weatherapp.com")
                                    }
                                }
                                .padding()
                            }
                            .navigationTitle("Privacy Policy")
                            .navigationBarTitleDisplayMode(.inline)
                        }
                    }

                    struct ColorPickerView: View {
                        @Binding var selectedColor: Color
                        let onColorSelected: (Color) -> Void
                        
                        let colors: [Color] = [
                            .blue, .indigo, .purple, .pink, .red, .orange, .yellow, .green, .mint, .teal
                        ]
                        
                        @State private var customColor: Color = .blue
                        
                        var body: some View {
                            NavigationView {
                                VStack(spacing: 20) {
                                    // Color preview
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedColor)
                                        .frame(height: 100)
                                        .shadow(color: selectedColor.opacity(0.5), radius: 10)
                                        .padding()
                                    
                                    // Preset colors
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 15) {
                                        ForEach(colors, id: \.self) { color in
                                            Circle()
                                                .fill(color)
                                                .frame(width: 50, height: 50)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                                )
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                                                        .padding(2)
                                                )
                                                .shadow(color: color.opacity(0.5), radius: 5)
                                                .onTapGesture {
                                                    selectedColor = color
                                                }
                                        }
                                    }
                                    .padding()
                                    
                                    // Custom color picker
                                    ColorPicker("Custom Color", selection: $customColor)
                                        .padding()
                                        .onChange(of: customColor) { newValue in
                                            selectedColor = newValue
                                        }
                                    
                                    Spacer()
                                }
                                .navigationTitle("Choose Color")
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Button("Done") {
                                            onColorSelected(selectedColor)
                                        }
                                    }
                                    
                                    ToolbarItem(placement: .navigationBarLeading) {
                                        Button("Cancel") {
                                            onColorSelected(selectedColor)
                                        }
                                    }
                                }
                            }
                        }
                    }
