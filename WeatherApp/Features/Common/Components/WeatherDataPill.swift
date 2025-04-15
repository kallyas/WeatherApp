import SwiftUI

struct WeatherDataPill: View {
    let icon: String
    let title: String
    let value: String
    let isDarkMode: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(isDarkMode ? .white : .blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
        }
    }
}
