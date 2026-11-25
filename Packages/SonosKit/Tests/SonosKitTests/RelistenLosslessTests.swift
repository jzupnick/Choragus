import XCTest
@testable import SonosKit

final class RelistenLosslessTests: XCTestCase {
    func testOnlyUsesDeclaredOriginalFLAC() {
        let files = [["name": "track.mp3", "original": "track.flac"], ["name": "track.flac", "source": "original"]]
        XCTAssertEqual(RelistenLossless.originalFLAC(mp3Name: "track.mp3", files: files), "track.flac")
        XCTAssertNil(RelistenLossless.originalFLAC(mp3Name: "other.mp3", files: files))
        XCTAssertNil(RelistenLossless.originalFLAC(mp3Name: "track.mp3", files: [files[0]]))
    }

    func testOnlyAcceptsSonosCompatibleFLAC() {
        func header(rate: UInt64, bits: UInt64) -> Data {
            var bytes = [UInt8](repeating: 0, count: 64)
            bytes.replaceSubrange(0..<8, with: [0x66, 0x4c, 0x61, 0x43, 0, 0, 0, 34])
            let value = (rate << 44) | (1 << 41) | ((bits - 1) << 36)
            for i in 0..<8 { bytes[18 + i] = UInt8((value >> ((7 - i) * 8)) & 255) }
            return Data(bytes)
        }
        XCTAssertTrue(RelistenLossless.compatibleFLACHeader(header(rate: 48_000, bits: 24)))
        XCTAssertFalse(RelistenLossless.compatibleFLACHeader(header(rate: 96_000, bits: 24)))
        XCTAssertFalse(RelistenLossless.compatibleFLACHeader(Data()))
    }
}
