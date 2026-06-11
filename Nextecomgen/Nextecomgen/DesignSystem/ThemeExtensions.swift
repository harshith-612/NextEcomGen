import SwiftUI

extension Color {
    static let deepEmerald=Color(red:15/255,green:81/255,blue:50/255)
    static let freshMint=Color(red:25/255,green:135/255,blue:84/255)
    static let lightSageBg=Color(red:244/255,green:247/255,blue:245/255)
    static let accentBlue=Color(red:89/255,green:102/255,blue:241/255)
}

struct AppBackground: ViewModifier{func body(content: Content)->some View{ZStack{LinearGradient(colors:[.deepEmerald,.accentBlue],startPoint:.topLeading,endPoint:.bottomTrailing).ignoresSafeArea(); content}}}
extension View{func appBackground()->some View{modifier(AppBackground())}}
