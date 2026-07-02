import UIKit

class ThemeViewController: UIViewController {

    @IBOutlet weak var themeSwitch: UISwitch!
    @IBOutlet weak var iconButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!

    var onClose: (() -> Void)?

    private var isDarkMode: Bool = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        isDarkMode ? .lightContent : .darkContent
    }

    override func viewDidLoad() {
        view.backgroundColor = .purple
        super.viewDidLoad()
        setupInitialTheme()
    }

    private func setupInitialTheme() {
        let theme = ThemeManager.shared.currentTheme

        isDarkMode = (theme == .dark)
        themeSwitch.isOn = (theme == .dark)

        applyLocalTheme(theme)
    }

    @IBAction func switchChanged(_ sender: UISwitch) {
        
        let theme: AppTheme = sender.isOn ? .dark : .light
        ThemeManager.shared.setTheme(theme)
        applyLocalTheme(theme)
    }

    private func applyLocalTheme(_ theme: AppTheme) {

        let isDark = (theme == .dark)
        isDarkMode = isDark

        iconButton.tintColor = isDark ? .white : .black
        titleLabel.textColor = isDark ? .white : .black

        view.backgroundColor = isDark ? .black : .white
    }

    @IBAction func closeTapped(_ sender: UIButton) {
        onClose?()
        dismiss(animated: true)
    }
}
