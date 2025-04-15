import SwiftUI

struct HourlyForecastView: View {
    let hourlyData: [HourlyForecast]
    let viewModel: WeatherViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hourly Forecast")
                .font(.headline)
                .padding(.leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(hourlyData) { hour in
                        if let condition = hour.weather.first {
                            HourlyForecastCell(
                                hour: hour,
                                iconName: viewModel.getWeatherIcon(from: condition.icon)
                            )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
        }
        .background(Color(UIColor.systemBackground).opacity(0.8))
        .cornerRadius(20)
    }
}

struct HourlyForecastCell: View {
    let hour: HourlyForecast
    let iconName: String
    
    var body: some View {
        VStack(spacing: 10) {
            Text(DateFormatters.hourFormatter.string(from: hour.date))
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Image(systemName: iconName)
                .renderingMode(.original)
                .font(.system(size: 22))
            
            Text("\(Int(hour.temp))°")
                .font(.system(size: 16, weight: .semibold))
        }
        .frame(height: 100)
    }
}
