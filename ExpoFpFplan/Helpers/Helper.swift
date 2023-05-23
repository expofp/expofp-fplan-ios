import Foundation
import WebKit

public struct Helper{
    public static func getEventAddress(_ url: String) -> String {
        func getWithoutParams (_ url: String, _ delimiter: Character) -> String {
            if let sIndex = url.firstIndex(of: delimiter){
                return String(url[...url.index(before: sIndex)])
            }
            else{
                return url
            }
        }
        
        let mainPart = url.replacingOccurrences(of: "https://www.", with: "")
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://www.", with: "")
            .replacingOccurrences(of: "http://", with: "")
        
        let result = getWithoutParams(getWithoutParams(mainPart, "/"), "?")
        return result
    }
    
    public static func getParams(_ url: String) -> String {
        if let index = url.firstIndex(of: "?") {
            return String(url[index...])
        }
        else{
            return ""
        }
    }
    
    public static func getEventId(_ url: String) -> String {
        let eventAddress = getEventAddress(url)
        if let index = eventAddress.firstIndex(of: ".") {
            return String(eventAddress[...eventAddress.index(index, offsetBy: -1)])
        }
        else{
            return ""
        }
    }
    
    public static func saveConfiguration(_ configuration: Configuration, fplanConfigPath: URL) throws {
        let fileDirectory = fplanConfigPath.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: fileDirectory.path){
            try! FileManager.default.createDirectory(atPath: fileDirectory.path, withIntermediateDirectories: true, attributes: nil)
        }
        
        let jsonEncoder = JSONEncoder()
        
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        jsonEncoder.dateEncodingStrategy = .custom({ date, encoder in
                var singleValueEnc = encoder.singleValueContainer()
                try singleValueEnc.encode(formatter.string(from: date))
        })
        
        let jsonData = try jsonEncoder.encode(configuration)
        let configJson = String(data: jsonData, encoding: String.Encoding.utf8)
        
        try configJson!.write(to: fplanConfigPath, atomically: true, encoding: String.Encoding.utf8)
    }
    
    public static func parseConfigurationJson(_ json: Data) throws -> Configuration {
        let decoder = JSONDecoder()

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)

            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = formatter.date(from: dateStr) {
                return date
            }
            
            throw DateError.invalidDate
        })
        
        let config = try decoder.decode(Configuration.self, from: json)
        return config
    }
    
    public static func downloadFile(_ url: URL, _ filePath: URL){
        let fileDirectory = filePath.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: fileDirectory.path){
            try! FileManager.default.createDirectory(atPath: fileDirectory.path, withIntermediateDirectories: true, attributes: nil)
        }
        
        let session = URLSession.shared
        let task = session.dataTask(with: url, completionHandler: { data, response, error in
            if(error == nil) {
                let fileManager = FileManager.default
                fileManager.createFile(atPath: filePath.path, contents: data)
            }
        })
        task.resume()
    }
    
    public static func loadConfiguration(fplanConfigPath: URL) throws -> Configuration {
        let json = try String.init(contentsOf: fplanConfigPath)
        return try parseConfigurationJson(json.data(using: .utf8)!)
    }
    
    public static func loadConfiguration(_ configuration: Configuration?, fplanConfigUrl: URL, callback: @escaping ((_ configuration: Configuration) -> Void)) {
        if(configuration != nil){
            callback(configuration!)
        }
        
        let session = URLSession.shared
        let task = session.dataTask(with: fplanConfigUrl, completionHandler: { data, response, error in
            
            if let json = data {
                guard let config = try? parseConfigurationJson(json) else {
                    print("[Fplan] Config file loaded from assets")
                    let config = getDefaultConfiguration()
                    callback(config)
                    return
                }
                
                print("[Fplan] Config file loaded from \(fplanConfigUrl.absoluteString)")
                callback(config)
            }
            else {
                print("[Fplan] Config file loaded from assets")
                let config = getDefaultConfiguration()
                callback(config)
            }
            
            
        })
        task.resume()
    }
    
    public static func getDefaultConfiguration() -> Configuration {
        return Configuration(androidHtmlUrl: nil, iosHtmlUrl: nil, zipArchiveUrl: nil, enablePositioningAfter: nil, disablePositioningAfter: nil)
    }
    
    public static func getCacheDirectory() -> URL {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0]
    }
}

