import SwiftUI

struct CurrentWeatherCard: View {
    let current: CurrentWeather
    let condition: WeatherCondition
    let cityName: String
    let isDarkMode: Bool
    let viewModel: WeatherViewModel
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text(cityName)
                    .font(.title)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(Date(), style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .center, spacing: 20) {
                Image(systemName: viewModel.getWeatherIcon(from: condition.icon))
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 10)
                            .repeatForever(autoreverses: false)
                            .delay(1),
                        value: isAnimating
                    )
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(Int(current.temp))°C")
                        .font(.system(size: 50, weight: .bold))
                    
                    Text(condition.description.capitalized)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical)
            
            HStack(spacing: 30) {
                WeatherDataPill(
                    icon: "thermometer",
                    title: "Feels Like",
                    value: "\(Int(current.feelsLike))°C",
                    isDarkMode: isDarkMode
                )
                
                WeatherDataPill(
                    icon: "wind",
                    title: "Wind",
                    value: "\(Int(current.windSpeed)) m/s",
                    isDarkMode: isDarkMode
                )
                
                WeatherDataPill(
                    icon: "humidity",
                    title: "Humidity",
                    value: "\(current.humidity)%",
                    isDarkMode: isDarkMode
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isDarkMode ? 
                      Color(UIColor.systemGray6).opacity(0.8) :
                      Color.white.opacity(0.8))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .onAppear {
            isAnimating = true
        }
    }
}
