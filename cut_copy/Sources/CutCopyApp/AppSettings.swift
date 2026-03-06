import Foundation

final class AppSettings {
    private enum Keys {
        static let autoCopyEnabled = "cutcopy.autoCopyEnabled"
        static let launchAtLoginEnabled = "cutcopy.launchAtLoginEnabled"
        static let locationConfigured = "cutcopy.locationConfigured"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var autoCopyEnabled: Bool {
        get { defaultsObject(forKey: Keys.autoCopyEnabled, defaultValue: true) }
        set { defaults.set(newValue, forKey: Keys.autoCopyEnabled) }
    }

    var launchAtLoginEnabled: Bool {
        get { defaultsObject(forKey: Keys.launchAtLoginEnabled, defaultValue: true) }
        set { defaults.set(newValue, forKey: Keys.launchAtLoginEnabled) }
    }

    var didConfigureLocation: Bool {
        get { defaults.bool(forKey: Keys.locationConfigured) }
        set { defaults.set(newValue, forKey: Keys.locationConfigured) }
    }

    private func defaultsObject(forKey key: String, defaultValue: Bool) -> Bool {
        guard defaults.object(forKey: key) != nil else {
            return defaultValue
        }
        return defaults.bool(forKey: key)
    }
}
