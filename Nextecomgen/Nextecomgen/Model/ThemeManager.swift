import UIKit

final class ThemeManager {

    static let shared = ThemeManager()
    private let key = "selectedTheme"

    var currentTheme: AppTheme {
        let raw = UserDefaults.standard.string(forKey: key) ?? AppTheme.system.rawValue
        return AppTheme(rawValue: raw) ?? .system
    }

    func setTheme(_ theme: AppTheme) {
        UserDefaults.standard.set(theme.rawValue, forKey: key)
        apply(theme)
    }

    func apply(_ theme: AppTheme) {

        let style: UIUserInterfaceStyle = {
            switch theme {
            case .light: return .light
            case .dark: return .dark
            case .system: return .unspecified
            }
        }()

        DispatchQueue.main.async {

            let scenes = UIApplication.shared.connectedScenes

            for scene in scenes {
                guard let windowScene = scene as? UIWindowScene else { continue }

                for window in windowScene.windows {
                    window.overrideUserInterfaceStyle = style
                }
            }
        }
    }

    func reapply() {
        apply(currentTheme)
    }
}
