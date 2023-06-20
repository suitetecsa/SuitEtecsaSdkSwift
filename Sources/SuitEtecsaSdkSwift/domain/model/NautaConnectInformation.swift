// YApi QuickType插件生成，具体参考文档:https://plugins.jetbrains.com/plugin/18847-yapi-quicktype/documentation

import Foundation

// MARK: - NautaConnectInformation
public struct NautaConnectInformation {
    let lastsConnections: [LastsConnection]
    let accountInfo: AccountInfo
}

// MARK: - AccountInfo
public struct AccountInfo {
    let accessAreas, accountStatus, credit, expirationDate: String
}

// MARK: - LastsConnection
public struct LastsConnection {
    let from, to, time: String
}
