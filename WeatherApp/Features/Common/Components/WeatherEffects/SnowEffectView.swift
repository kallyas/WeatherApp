import SwiftUI

struct SnowEffectView: View {
    let isDarkMode: Bool
    
    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { i in
                SnowFlake(isDarkMode: isDarkMode)
            }
        }
    }
}

struct SnowFlake: View {
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
    private let duration = Double.random(in: 5...10)
    private let delay = Double.random(in: 0...5)
    private let size = CGFloat.random(in: 3...8)
    private let rotation = Double.random(in: 0...360)
    
    var body: some View {
        Image(systemName: "snowflake")
            .font(.system(size: size))
            .foregroundColor(isDarkMode ? .white.opacity(0.7) : .white.opacity(0.9))
            .rotationEffect(.degrees(rotation))
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
