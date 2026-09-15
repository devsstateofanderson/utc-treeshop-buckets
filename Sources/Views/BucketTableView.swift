import SwiftUI
struct BucketTableView: View {
    let bucket: Bucket
    var body: some View { ContentUnavailableView(bucket.title, systemImage: bucket.symbol) }
}
