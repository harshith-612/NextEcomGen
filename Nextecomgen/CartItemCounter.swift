import SwiftUI

struct CartItemCounter: View {
    let product: Product
    @Binding var shoppingCart: [Product]
    
    var currentItemCount: Int {
        shoppingCart.filter { $0.name == product.name }.count
    }
    
    var body: some View {
        HStack(spacing: 15) {
            Spacer()
            if currentItemCount > 0 {
                Button(action: {
                    if let indexToRemove = shoppingCart.firstIndex(where: { $0.name == product.name }) {
                        withAnimation { _ = shoppingCart.remove(at: indexToRemove) }
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                Text("\(currentItemCount)")
                    .font(.headline)
                    .frame(minWidth: 25)
            }
            
            Button(action: {
                withAnimation { shoppingCart.append(product) }
            }) {
                Image(systemName: "cart.badge.plus")
                    .font(.title2)
                    .foregroundColor(.freshMint)
            }
        }
    }
}
