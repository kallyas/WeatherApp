import SwiftUI

struct DailyForecastView: View {
    let dailyData: [DailyForecast]
    let viewModel: WeatherViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("7-Day Forecast")
                .font(.headline)
                .padding(.leading)
            
            ForEach(dailyData) { day in
                if let condition = day.weather.first {
                    DailyForecastRow(
                        day: day,
                        iconName: viewModel.getWeatherIcon(from: condition.icon)
                    )
                    
                    if day.id != dailyData.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground).opacity(0.8))
        .cornerRadius(20)
    }
}

struct DailyForecastRow: View {
    let day: DailyForecast
    let iconName: String
    
    var body: some View {
        HStack {
            Text(DateFormatters.dayFormatter.string(from: day.date))
                .font(.system(size: 16))
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            Image(systemName: iconName)
                .renderingMode(.original)
                .font(.system(size: 22))
            
            Spacer()
            
            Text("☔️ \(Int(day.pop * 100))%")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .trailing)
            
            HStack(spacing: 5) {
                Text("\(Int(day.temp.min))°")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                
                Text("\(Int(day.temp.max))°")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 8)
    }
}
