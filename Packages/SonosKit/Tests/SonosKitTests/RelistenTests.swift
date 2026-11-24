import XCTest
@testable import SonosKit

final class RelistenTests: XCTestCase {
    func testResolvedTrackMetadataRoundTrips() {
        let url = "https://audio.example/recording.mp3"
        ResolvedPlaybackRegistry.rememberRelisten(playURL: url, title: "Song", artist: "Band", album: "Show", art: nil)
        let saved = ResolvedPlaybackRegistry.relistenMetadata(playURL: url)
        XCTAssertEqual(saved?.title, "Song")
        XCTAssertEqual(saved?.artist, "Band")
        XCTAssertEqual(saved?.album, "Show")
    }

    @MainActor
    func testTrackUsesAnonymousMediaURIResolution() {
        let id = "Track:example-band:2026:2026-01-01:123:456"
        let track = SMAPIMediaItem(id: id, title: "Track", itemType: "track",
                                   artist: "Artist", album: "Show", albumArtURI: "",
                                   canPlay: true, canBrowse: false, uri: "", metadata: "")
        let item = ServiceSearchProvider.shared.smapiItemToBrowseItem(track, serviceID: ServiceID.relisten, sn: 0)
        XCTAssertEqual(item.objectID, "smapi:270:\(id)")
        XCTAssertEqual(item.playbackStrategy, .smapiResolveThenEmpty)
        XCTAssertNotNil(item.resourceURI)
    }
}
