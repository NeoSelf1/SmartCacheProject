import Foundation

struct EnvironmentVar {
    var clientID: String {
        getEnvironmentVariable("NAVER_CLIENT_ID")
    }
    
    var clientSecret: String {
        getEnvironmentVariable("NAVER_CLIENT_SECRET")
    }
    
    private func getEnvironmentVariable(_ name: String) -> String {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: name) as? String else {
            fatalError("no api key found")
        }
        return apiKey
    }
}
