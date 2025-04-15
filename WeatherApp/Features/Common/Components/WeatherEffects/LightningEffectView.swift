import SwiftUI

struct LightningEffectView: View {
    @State private var isVisible = false
    @State private var nextFlash = Double.random(in: 3...10)
    
    var body: some View {
        Rectangle()
            .fill(Color.white)
            .ignoresSafeArea()
            .opacity(isVisible ? 0.2 : 0)
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                    if nextFlash <= 0 {
                        flashLightning()
                        nextFlash = Double.random(in: 3...10)
                    } else {
                        nextFlash -= 0.1
                    }
                }
            }
    }
    
    private func flashLightning() {
        withAnimation(.easeIn(duration: 0.1)) {
            isVisible = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.1)) {
                isVisible = false
            }
            
            // Possibility of double flash
            if Bool.random() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeIn(duration: 0.1)) {
                        isVisible = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.1)) {
                            isVisible = false
                        }
                    }
                }
            }
        }
    }
}
