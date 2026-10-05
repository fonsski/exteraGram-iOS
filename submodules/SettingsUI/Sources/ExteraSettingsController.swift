import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import PresentationDataUtils
import AccountContext

private final class ExteraSettingsControllerArguments {
    let updateHidePhoneNumber: (Bool) -> Void
    let updateDisableNumberRounding: (Bool) -> Void

    init(
        updateHidePhoneNumber: @escaping (Bool) -> Void,
        updateDisableNumberRounding: @escaping (Bool) -> Void
    ) {
        self.updateHidePhoneNumber = updateHidePhoneNumber
        self.updateDisableNumberRounding = updateDisableNumberRounding
    }
}

private enum ExteraSettingsSection: Int32 {
    case general
}

private enum ExteraSettingsEntry: ItemListNodeEntry {
    case generalHeader
    case hidePhoneNumber(Bool)
    case disableNumberRounding(Bool)
    case generalFooter

    var section: ItemListSectionId {
        switch self {
        case .generalHeader, .hidePhoneNumber, .disableNumberRounding, .generalFooter:
            return ExteraSettingsSection.general.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .generalHeader:
            return 0
        case .hidePhoneNumber:
            return 1
        case .disableNumberRounding:
            return 2
        case .generalFooter:
            return 3
        }
    }

    static func <(lhs: ExteraSettingsEntry, rhs: ExteraSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! ExteraSettingsControllerArguments
        switch self {
        case .generalHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "GENERAL", sectionId: self.section)
        case let .hidePhoneNumber(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Hide Phone Number", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateHidePhoneNumber(value)
            })
        case let .disableNumberRounding(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Disable Number Rounding", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateDisableNumberRounding(value)
            })
        case .generalFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Number rounding shows exact counts, such as 1234 instead of 1.2K."), sectionId: self.section)
        }
    }
}

private func exteraSettingsEntries(settings: ExteraSettings) -> [ExteraSettingsEntry] {
    var entries: [ExteraSettingsEntry] = []

    entries.append(.generalHeader)
    entries.append(.hidePhoneNumber(settings.hidePhoneNumber))
    entries.append(.disableNumberRounding(settings.disableNumberRounding))
    entries.append(.generalFooter)

    return entries
}

public func exteraSettingsController(context: AccountContext) -> ViewController {
    let accountManager = context.sharedContext.accountManager

    let arguments = ExteraSettingsControllerArguments(
        updateHidePhoneNumber: { value in
            let _ = updateExteraSettingsInteractively(accountManager: accountManager, { settings in
                var settings = settings
                settings.hidePhoneNumber = value
                return settings
            }).start()
        },
        updateDisableNumberRounding: { value in
            let _ = updateExteraSettingsInteractively(accountManager: accountManager, { settings in
                var settings = settings
                settings.disableNumberRounding = value
                return settings
            }).start()
        }
    )

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.exteraSettings])
    )
    |> map { presentationData, sharedData -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let settings = sharedData.entries[ApplicationSpecificSharedDataKeys.exteraSettings]?.get(ExteraSettings.self) ?? ExteraSettings.defaultSettings

        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text("exteraGram"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: exteraSettingsEntries(settings: settings), style: .blocks, animateChanges: true)

        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}
