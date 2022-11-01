import Foundation

///Fplan configuration
public struct Configuration : Codable {
    
    ///Hides the panel with information about exhibitors
    public let noOverlay: Bool?
    
    ///URL index.html for Android version
    public let androidHtmlUrl: String?
    
    ///URL index.html for iOS version
    public let iosHtmlUrl: String?
    
    ///The date after which the component will connect to the location provider
    public let enablePositioningAfter: Date?
    
    ///The date after which the component will not connect to the location provider
    public let disablePositioningAfter: Date?
    
    ///Branch - part of the file path
    public let branch: String?
    
    ///Array of cached files
    public var files: [FileInfo]
    
    public init(noOverlay: Bool?, androidHtmlUrl: String?, iosHtmlUrl: String?, enablePositioningAfter: Date?, disablePositioningAfter: Date?, branch: String?, files: [FileInfo]) {
        self.noOverlay = noOverlay
        self.androidHtmlUrl = androidHtmlUrl
        self.iosHtmlUrl = iosHtmlUrl
        self.enablePositioningAfter = enablePositioningAfter
        self.disablePositioningAfter = disablePositioningAfter
        self.branch = branch
        self.files = files
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.noOverlay = try container.decode(Bool.self, forKey: .noOverlay)
        self.androidHtmlUrl = try container.decodeIfPresent(String.self, forKey: .androidHtmlUrl)
        self.iosHtmlUrl = try container.decodeIfPresent(String.self, forKey: .iosHtmlUrl)
        self.enablePositioningAfter = try container.decodeIfPresent(Date.self, forKey: .enablePositioningAfter)
        self.disablePositioningAfter = try container.decodeIfPresent(Date.self, forKey: .disablePositioningAfter)
        self.branch = try container.decodeIfPresent(String.self, forKey: .branch)
        self.files = try container.decode([FileInfo].self, forKey: .files)
    }
    
    public mutating func addFile(_ file: FileInfo){
        self.files.append(file)
    }
}
