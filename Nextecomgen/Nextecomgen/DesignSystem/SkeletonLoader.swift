import SwiftUI
struct SkeletonLoader: View {
    @State private var shimmer = false
    private let cardBackground = Color(red: 0.12, green: 0.12, blue: 0.12)
    private let placeholderColor = Color.white.opacity(0.1)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RoundedRectangle(cornerRadius: 16)
                .fill(placeholderColor)
                .frame(height: 150)
            RoundedRectangle(cornerRadius: 4)
                .fill(placeholderColor)
                .frame(width: 220, height: 18)
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(placeholderColor)
                    .frame(width: 80, height: 24)
                
                Spacer()
                
                Circle()
                    .fill(placeholderColor)
                    .frame(width: 36, height: 36)
            }
            RoundedRectangle(cornerRadius: 12)
                .fill(placeholderColor)
                .frame(height: 48)
        }
        .padding(20)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            LinearGradient(
                colors: [.clear, .white.opacity(0.08), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .offset(x: shimmer ? 400 : -400)
        )
        .mask(RoundedRectangle(cornerRadius: 24))
        .onAppear {
            withAnimation(
                .linear(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                shimmer = true
            }
        }
    }
}

