import Foundation
import CoatCheckCore

/// Answers the `coatcheck` command. Distributed notifications reach background apps only with
/// immediate delivery, which needs the selector-based API.
final class CommandListener: NSObject {
    private let handle: (Command.Request) -> Command.Reply

    init(handle: @escaping (Command.Request) -> Command.Reply) {
        self.handle = handle
        super.init()
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(received(_:)), name: Command.request,
                                                            object: nil, suspensionBehavior: .deliverImmediately)
    }

    deinit { DistributedNotificationCenter.default().removeObserver(self) }

    @objc private func received(_ notification: Notification) {
        guard let request = Command.Request(userInfo: notification.userInfo) else { return }
        let reply = handle(request)
        DistributedNotificationCenter.default().postNotificationName(Command.reply, object: nil,
                                                                     userInfo: reply.userInfo, deliverImmediately: true)
    }
}
