import Foundation
import ServiceManagement

enum LaunchAtLoginError: LocalizedError {
    case notSupported
    case operationFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notSupported:
            return "当前系统不支持 SMAppService。"
        case .operationFailed(let error):
            return "系统拒绝开机启动设置：\(error.localizedDescription)"
        }
    }
}

final class LaunchAtLoginService {
    func setEnabled(_ enabled: Bool) -> Result<Void, LaunchAtLoginError> {
        guard #available(macOS 13.0, *) else {
            return .failure(.notSupported)
        }

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return .success(())
        } catch {
            return .failure(.operationFailed(error))
        }
    }
}
