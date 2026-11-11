/// Build facts shown on Help & about; the app target fills them from its bundle.
public struct AppInfo: Sendable, Equatable {
    public let version: String
    public let build: String

    public init(version: String, build: String) {
        self.version = version
        self.build = build
    }
}
