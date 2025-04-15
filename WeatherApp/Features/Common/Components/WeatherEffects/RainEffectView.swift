import SwiftUI

struct RainEffectView: View {
    let isDarkMode: Bool
    var intensity: RainIntensity = .moderate
    
    enum RainIntensity {
        case light, moderate, heavy
        
        var dropCount: Int {
            switch self {
            case .light: return 30
            case .moderate: return 60
            case .heavy: return 100
            }
        }
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<intensity.dropCount, id: \.self) { i in
                RainDrop(isDarkMode: isDarkMode)
            }
        }
    }
}

struct RainDrop: View {
    let isDarkMode: Bool
    
    @State private var isAnimating = false
    private let startPosition = CGPoint(
        x: CGFloat.random(in: -UIScreen.main.bounds.width/2...UIScreen.main.bounds.width/2),
        y: -20
    )
    private let endPosition = CGPoint(
        x: CGFloat.random(in: -UIScreen.main.bounds.width/2...UIScreen.main.bounds.width/2),
        y: UIScreen.main.bounds.height + 20
    )
    private let duration = Double.random(in: 0.3...0.8)
    private let delay = Double.random(in: 0...3)
    private let width: CGFloat = CGFloat.random(in: 1...2)
    private let height: CGFloat = CGFloat.random(in: 7...15)
    
    var body: some View {
        Rectangle()
            .fill(isDarkMode ? Color.white.opacity(0.2) : Color.blue.opacity(0.2))
            .frame(width: width, height: height)
            .offset(
                x: isAnimating ? endPosition.x : startPosition.x,
                y: isAnimating ? endPosition.y : startPosition.y
            )
            .onAppear {
                withAnimation(
                    Animation
                        .linear(duration: duration)
                        .repeatForever(autoreverses: false)
                        .delay(delay)
                ) {
                    isAnimating = true
                }
            }
    }
}
