import Foundation

public enum HaloSize: String, Codable, CaseIterable, Sendable {
    case small, medium, large

    /// Radius in points.
    public var radius: Double {
        switch self {
        case .small: 20
        case .medium: 32
        case .large: 48
        }
    }

    public var title: String {
        switch self {
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        }
    }
}

public struct RGB: Equatable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

public enum HaloColor: String, Codable, CaseIterable, Sendable {
    case yellow, red, blue, green, pink

    public var title: String { rawValue.capitalized }

    public var rgb: RGB {
        switch self {
        case .yellow: RGB(red: 1.0, green: 0.85, blue: 0.0)
        case .red: RGB(red: 0.95, green: 0.15, blue: 0.15)
        case .blue: RGB(red: 0.15, green: 0.45, blue: 0.95)
        case .green: RGB(red: 0.15, green: 0.8, blue: 0.3)
        case .pink: RGB(red: 1.0, green: 0.4, blue: 0.7)
        }
    }

    public var red: Double { rgb.red }
    public var green: Double { rgb.green }
    public var blue: Double { rgb.blue }

    /// Left-click ripple uses the chosen color.
    public var leftClickRGB: RGB { rgb }

    /// Right-click ripple uses the inverted color so the two buttons are always distinguishable.
    public var rightClickRGB: RGB {
        RGB(red: 1 - rgb.red, green: 1 - rgb.green, blue: 1 - rgb.blue)
    }
}

public struct Settings: Codable, Equatable, Sendable {
    /// Fill alpha of the highlight circle.
    public static let highlightAlpha = 0.35

    public var highlightEnabled = true
    public var rippleEnabled = true
    public var size = HaloSize.medium
    public var color = HaloColor.yellow
    public var toggleHotKey = HotKey.toggle

    public init() {}

    // Missing keys fall back to defaults and unknown keys (like the removed master flag) are ignored,
    // so older saved data keeps loading.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Settings()
        highlightEnabled = try c.decodeIfPresent(Bool.self, forKey: .highlightEnabled) ?? d.highlightEnabled
        rippleEnabled = try c.decodeIfPresent(Bool.self, forKey: .rippleEnabled) ?? d.rippleEnabled
        size = try c.decodeIfPresent(HaloSize.self, forKey: .size) ?? d.size
        color = try c.decodeIfPresent(HaloColor.self, forKey: .color) ?? d.color
        toggleHotKey = try c.decodeIfPresent(HotKey.self, forKey: .toggleHotKey) ?? d.toggleHotKey
    }

    public mutating func toggleHighlight() {
        highlightEnabled.toggle()
    }
}

/// Minimal key-value storage so tests can run without touching real preferences.
public protocol SettingsBacking {
    func data(forKey defaultName: String) -> Data?
    func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: SettingsBacking {}

public final class InMemoryBacking: SettingsBacking {
    private var storage: [String: Data] = [:]

    public init() {}

    public func data(forKey defaultName: String) -> Data? {
        storage[defaultName]
    }

    public func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value as? Data
    }
}

public struct SettingsStore {
    public static let key = "cursorhalo.settings.v1"

    private let backing: SettingsBacking

    public init(backing: SettingsBacking) {
        self.backing = backing
    }

    /// Returns saved settings, or defaults when nothing is saved or the data is unreadable.
    public func load() -> Settings {
        guard let data = backing.data(forKey: Self.key),
              let settings = try? JSONDecoder().decode(Settings.self, from: data)
        else { return Settings() }
        return settings
    }

    public func save(_ settings: Settings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        backing.set(data, forKey: Self.key)
    }
}
