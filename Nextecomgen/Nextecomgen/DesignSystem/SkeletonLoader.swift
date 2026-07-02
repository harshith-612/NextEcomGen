import SwiftUI

struct SkeletonLoader: View {
    @State private var shimmer = false
    private let cardBackground = Color(red: 0.12, green: 0.12, blue: 0.12)
    private let placeholderColor = Color(.secondarySystemBackground).opacity(0.1)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RoundedRectangle(cornerRadius: 16)
                .fill(placeholderColor)
                .frame(height: 150)
                .skeletonShimmer(shape: RoundedRectangle(cornerRadius: 16), isAnimating: shimmer)
            RoundedRectangle(cornerRadius: 4)
                .fill(placeholderColor)
                .frame(width: 220, height: 18)
                .skeletonShimmer(shape: RoundedRectangle(cornerRadius: 4), isAnimating: shimmer)
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(placeholderColor)
                    .frame(width: 80, height: 24)
                    .skeletonShimmer(shape: RoundedRectangle(cornerRadius: 4), isAnimating: shimmer)
                
                Spacer()
                
                Circle()
                    .fill(placeholderColor)
                    .frame(width: 36, height: 36)
                    .skeletonShimmer(shape: Circle(), isAnimating: shimmer)
            }
            RoundedRectangle(cornerRadius: 12)
                .fill(placeholderColor)
                .frame(height: 48)
                .skeletonShimmer(shape: RoundedRectangle(cornerRadius: 12), isAnimating: shimmer)
        }
        .padding(20)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
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
extension View {
    func skeletonShimmer<S: Shape>(shape: S, isAnimating: Bool) -> some View {
        self.overlay(
            LinearGradient(
                colors: [.clear, .white.opacity(0.15), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .offset(x: isAnimating ? 400 : -400)
            .mask(shape)
        )
    }
}
