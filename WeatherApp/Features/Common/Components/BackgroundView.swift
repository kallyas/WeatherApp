import SwiftUI

enum BackgroundType {
    case clear, cloudy, rainy, stormy, snowy, foggy
}

struct BackgroundView: View {
    let backgroundType: BackgroundType
    let isDarkMode: Bool
    
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            linearGradient
                .ignoresSafeArea()
                .hueRotation(.degrees(animateGradient ? 45 : 0))
                .animation(
                    Animation.easeInOut(duration: 20).repeatForever(autoreverses: true),
                    value: animateGradient
                )
            
            // Weather-specific effects
            weatherEffectsView
        }
        .onAppear {
            animateGradient = true
        }
    }
    
    private var linearGradient: LinearGradient {
        switch backgroundType {
        case .clear:
            return LinearGradient(
                colors: isDarkMode ? 
                    [Color(red: 0.1, green: 0.2, blue: 0.4), Color(red: 0, green: 0, blue: 0.2)] :
                    [Color(red: 0.4, green: 0.7, blue: 1.0), Color(red: 0.8, green: 0.9, blue: 1.0)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .cloudy:
            return LinearGradient(
                colors: isDarkMode ? 
                    [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.1, green: 0.1, blue: 0.2)] :
                    [Color(red: 0.7, green: 0.7, blue: 0.7), Color(red: 0.9, green: 0.9, blue: 0.9)

],
                startPoint: .top,
                endPoint: .bottom
            )
        case .rainy:
            return LinearGradient(
                colors: isDarkMode ? 
                    [Color(red: 0.1, green: 0.1, blue: 0.3), Color(red: 0.1, green: 0.1, blue: 0.2)] :
                    [Color(red: 0.5, green: 0.5, blue: 0.7), Color(red: 0.7, green: 0.7, blue: 0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .stormy:
            return LinearGradient(
                colors: isDarkMode ? 
                    [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0, green: 0, blue: 0.1)] :
                    [Color(red: 0.3, green: 0.3, blue: 0.5), Color(red: 0.5, green: 0.5, blue: 0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .snowy:
            return LinearGradient(
                colors: isDarkMode ? 
                    [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.1, green: 0.1, blue: 0.2)] :
                    [Color(red: 0.8, green: 0.8, blue: 0.9), Color(red: 1, green: 1, blue: 1)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .foggy:
            return LinearGradient(
                colors: isDarkMode ? 
                    [Color(red: 0.2, green: 0.2, blue: 0.2), Color(red: 0.1, green: 0.1, blue: 0.1)] :
                    [Color(red: 0.7, green: 0.7, blue: 0.7), Color(red: 0.9, green: 0.9, blue: 0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    @ViewBuilder
    private var weatherEffectsView: some View {
        switch backgroundType {
        case .clear:
            EmptyView()
            
        case .cloudy:
            CloudsEffectView(isDarkMode: isDarkMode)
            
        case .rainy:
            RainEffectView(isDarkMode: isDarkMode)
            
        case .stormy:
            ZStack {
                RainEffectView(isDarkMode: isDarkMode, intensity: .heavy)
                LightningEffectView()
            }
            
        case .snowy:
            SnowEffectView(isDarkMode: isDarkMode)
            
        case .foggy:
            FogEffectView(isDarkMode: isDarkMode)
        }
    }
}
