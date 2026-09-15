// Prints the CGWindowID of the first layer-0 window (≥ 100 px tall, visible alpha) owned by the process
// whose PID is argv[1], on ANY Space (the app may open on a different Space than the caller's).
// Exit 1 if none. Used by screenshot.sh.
import CoreGraphics
import Foundation
guard CommandLine.arguments.count > 1, let pid = Int(CommandLine.arguments[1]) else { exit(2) }
guard let list = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]] else { exit(1) }
for w in list {
    guard (w[kCGWindowOwnerPID as String] as? Int) == pid,
          (w[kCGWindowLayer as String] as? Int) == 0,
          ((w[kCGWindowAlpha as String] as? Double) ?? 1) > 0,
          let bounds = w[kCGWindowBounds as String] as? [String: Any],
          let height = bounds["Height"] as? Double, height >= 100,
          let id = w[kCGWindowNumber as String] as? Int else { continue }
    print(id)
    exit(0)
}
exit(1)
