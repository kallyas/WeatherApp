import SwiftUI

struct WelcomeView: View {
    let action: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Weather App")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : -20)
            
            Image(systemName: "cloud.sun.fill")
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .opacity(isAnimating ? 1 : 0)
            
            Text("Get the latest weather information for your location")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
            
            Button(action: action) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 250, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue)
                    )
                    .shadow(radius: 5)
            }
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 40)
        }
        .padding(.horizontal)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
}
