// Prints the CGWindowID of the first on-screen, layer-0 window (≥ 100 px tall) owned by
// the app named in argv[1]. Exit 1 if none. Used by screenshot.sh.
import CoreGraphics
import Foundation
let owner = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ""
let opts: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
guard let list = CGWindowListCopyWindowInfo(opts, kCGNullWindowID) as? [[String: Any]] else { exit(1) }
for w in list {
    guard (w[kCGWindowOwnerName as String] as? String) == owner,
          (w[kCGWindowLayer as String] as? Int) == 0,
          let bounds = w[kCGWindowBounds as String] as? [String: Any],
          let height = bounds["Height"] as? Double, height >= 100,
          let id = w[kCGWindowNumber as String] as? Int else { continue }
    print(id)
    exit(0)
}
exit(1)
