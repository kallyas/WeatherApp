import SwiftUI

struct WeatherDashboardView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @Binding var isDarkMode: Bool
    @State private var showingSearchSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Current weather card
                if let current = viewModel.currentWeather, let condition = current.weather.first {
                    CurrentWeatherCard(
                        current: current,
                        condition: condition,
                        cityName: viewModel.selectedCity?.name ?? "Current Location",
                        isDarkMode: isDarkMode,
                        viewModel: viewModel
                    )
                    .transition(.scale)
                }
                
                // Hourly forecast
                HourlyForecastView(hourlyData: viewModel.hourlyForecast, viewModel: viewModel)
                    .transition(.move(edge: .trailing))
                
                // Daily forecast
                DailyForecastView(dailyData: viewModel.dailyForecast, viewModel: viewModel)
                    .transition(.move(edge: .bottom))
                
                // Weather details
                if let current = viewModel.currentWeather {
                    WeatherDetailsView(current: current, isDarkMode: isDarkMode)
                        .transition(.scale)
                }
            }
            .padding()
        }
        .refreshable {
            if let city = viewModel.selectedCity {
                viewModel.fetchWeather(for: city)
            } else if let location = LocationManager().location {
                viewModel.fetchWeather(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            }
        }
        .sheet(isPresented: $showingSearchSheet) {
            SearchView(weatherViewModel: viewModel)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingSearchSheet = true
                }) {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
    }
}
