import Foundation

public enum RelistenLossless {
    public static func originalFLAC(mp3Name: String, files: [[String: String]]) -> String? {
        guard let mp3 = files.first(where: { $0["name"] == mp3Name }),
              let original = mp3["original"], original.lowercased().hasSuffix(".flac"),
              files.contains(where: { $0["name"] == original && $0["source"] == "original" }) else { return nil }
        return original
    }

    public static func compatibleFLACHeader(_ data: Data) -> Bool {
        let bytes = [UInt8](data)
        guard bytes.count >= 26, Array(bytes[0..<4]) == [0x66, 0x4c, 0x61, 0x43],
              bytes[4] & 0x7f == 0, bytes[5] == 0, bytes[6] == 0, bytes[7] == 34 else { return false }
        let value = bytes[18..<26].reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
        let rate = value >> 44
        let bits = ((value >> 36) & 31) + 1
        let channels = ((value >> 41) & 7) + 1
        return rate > 0 && rate <= 48_000 && (bits == 16 || bits == 24) && channels <= 2
    }

    public static func resolve(_ mp3URL: String) async -> String? {
        guard let source = URL(string: mp3URL), source.host == "audio-bare.relisten.net" || source.host == "archive.org" else { return nil }
        let parts = source.path.split(separator: "/").map(String.init)
        let offset = source.host == "archive.org" ? 0 : 1
        guard parts.count == offset + 3, parts[offset] == "download", source.host == "archive.org" || parts[0] == "archive.org" else { return nil }
        let identifier = parts[offset + 1], filename = parts[offset + 2]
        guard filename.lowercased().hasSuffix(".mp3"), !identifier.isEmpty else { return nil }
        let metadataURL = URL(string: "https://archive.org/metadata/")!.appendingPathComponent(identifier)
        var request = URLRequest(url: metadataURL)
        request.timeoutInterval = 8
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rawFiles = json["files"] as? [[String: Any]] else { return nil }
        let files = rawFiles.map { row in row.compactMapValues { $0 as? String } }
        guard let original = originalFLAC(mp3Name: filename, files: files) else { return nil }
        let target = URL(string: "https://archive.org/download/")!.appendingPathComponent(identifier).appendingPathComponent(original)
        var probe = URLRequest(url: target)
        probe.timeoutInterval = 8
        probe.setValue("bytes=0-63", forHTTPHeaderField: "Range")
        guard let (bytes, response) = try? await URLSession.shared.bytes(for: probe),
              (response as? HTTPURLResponse)?.statusCode == 206 else { return nil }
        var header = Data()
        do {
            for try await byte in bytes {
                header.append(byte)
                if header.count == 64 { break }
            }
        } catch { return nil }
        guard compatibleFLACHeader(header) else { return nil }
        return target.absoluteString
    }
}
