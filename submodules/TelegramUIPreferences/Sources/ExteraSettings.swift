import Foundation
import SwiftSignalKit
import TelegramCore

/// Settings of the exteraGram additions, stored in the account manager's shared data.
///
/// Every field has a default and is decoded with `decodeIfPresent`, so settings saved by an
/// older build keep loading after new fields are added.
public struct ExteraSettings: Codable, Equatable {
    /// Hides the phone number in the header of the Settings screen.
    public var hidePhoneNumber: Bool
    /// Shows exact counts (1234) instead of rounded ones (1.2K).
    public var disableNumberRounding: Bool

    public static var defaultSettings: ExteraSettings {
        return ExteraSettings(
            hidePhoneNumber: false,
            disableNumberRounding: false
        )
    }

    public init(
        hidePhoneNumber: Bool,
        disableNumberRounding: Bool
    ) {
        self.hidePhoneNumber = hidePhoneNumber
        self.disableNumberRounding = disableNumberRounding
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        let defaults = ExteraSettings.defaultSettings

        self.hidePhoneNumber = try container.decodeIfPresent(Bool.self, forKey: "hidePhoneNumber") ?? defaults.hidePhoneNumber
        self.disableNumberRounding = try container.decodeIfPresent(Bool.self, forKey: "disableNumberRounding") ?? defaults.disableNumberRounding
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)

        try container.encode(self.hidePhoneNumber, forKey: "hidePhoneNumber")
        try container.encode(self.disableNumberRounding, forKey: "disableNumberRounding")
    }
}

public func updateExteraSettingsInteractively(accountManager: AccountManager<TelegramAccountManagerTypes>, _ f: @escaping (ExteraSettings) -> ExteraSettings) -> Signal<Void, NoError> {
    return accountManager.transaction { transaction -> Void in
        transaction.updateSharedData(ApplicationSpecificSharedDataKeys.exteraSettings, { entry in
            let currentSettings: ExteraSettings
            if let entry = entry?.get(ExteraSettings.self) {
                currentSettings = entry
            } else {
                currentSettings = .defaultSettings
            }
            return SharedPreferencesEntry(f(currentSettings))
        })
    }
}

private let currentExteraSettings = Atomic<ExteraSettings>(value: .defaultSettings)

/// Synchronous access to the latest settings for code that has no `AccountContext`, such as
/// pure formatting functions. The value is kept up to date by `SharedAccountContextImpl`.
public enum ExteraSettingsCache {
    public static var current: ExteraSettings {
        return currentExteraSettings.with { $0 }
    }

    public static func update(_ settings: ExteraSettings) {
        let _ = currentExteraSettings.swap(settings)
    }
}
