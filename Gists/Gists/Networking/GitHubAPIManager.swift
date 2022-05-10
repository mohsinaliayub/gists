//
//  GitHubAPIManager.swift
//  Gists
//
//  Created by Mohsin Ali Ayub on 01.05.22.
//

import Foundation
import Alamofire
import Locksmith

class GitHubAPIManager {
    static let sharedInstance = GitHubAPIManager()
    
    private let clientID = "YOUR GITHUB APP CLIENT ID"
    private let clientSecret = "YOUR GITHUB APP CLIENT SECRET"
    var oAuthToken: String? {
        get {
            let dictionary = Locksmith.loadDataForUserAccount(userAccount: "github")
            return dictionary?["token"] as? String
        }
        set {
            guard let newValue = newValue,
                  let _ = try? Locksmith.updateData(data: ["token": newValue], forUserAccount: "github") else {
                let _ = try? Locksmith.deleteDataForUserAccount(userAccount: "github")
                return
            }
        }
    }
    var isLoadingOAuthToken: Bool {
        get { UserDefaults.standard.bool(forKey: "isLoadingOAuthToken") }
        set { UserDefaults.standard.set(newValue, forKey: "isLoadingOAuthToken") }
    }
    
    func printPublicGists() {
        AF.request(GistRouter.getPublic).responseString { response in
            if let receivedString = response.value {
                print(receivedString)
            }
        }
    }
    
    func fetchPublicGists(pageToLoad: String?, completion: @escaping (Result<[Gist], BackendError>, _ nextPageURLString: String?) -> Void) {
        if let urlString = pageToLoad {
            fetchGists(GistRouter.getAtPath(urlString), completion: completion)
        } else {
            fetchGists(GistRouter.getPublic, completion: completion)
        }
    }
    
    func fetchGists(_ urlRequest: URLRequestConvertible, completion: @escaping (Result<[Gist], BackendError>, _ nextPageURLString: String?) -> Void) {
        AF.request(urlRequest).responseData { response in
            let decoder = JSONDecoder()
            let result: Result<[Gist], BackendError> = decoder.decodeResponse(from: response)
            // get the link for the next page to load.
            let nextPageURLString = self.parseNextPageFromHeaders(response: response.response)
            completion(result, nextPageURLString)
        }
    }
    
    // MARK: - OAuth flow
    func hasOAuthToken() -> Bool {
        if let token = oAuthToken {
            return !token.isEmpty
        }
        return false
    }
    
    func urlToStartOAuth2Login() -> URL? {
        let authURLString = "https://github.com/login/oauth/authorize" + "?client_id=\(clientID)&scope=gist&state=TEST_STATE"
        return URL(string: authURLString)
    }
    
    func extractCodeFromOAuthStep1Response(url: URL) -> String? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var code: String?
        
        guard let queryItems = components?.queryItems else { return nil }
        
        for queryItem in queryItems {
            if queryItem.name.lowercased() == "code" {
                code = queryItem.value
                break
            }
        }
        
        return code
    }
    
    func processOAuthStep1Response(url: URL) {
        guard let code = extractCodeFromOAuthStep1Response(url: url) else {
            isLoadingOAuthToken = false
            return
        }
        swapCodeForOAuthToken(code: code)
    }
    
    func swapCodeForOAuthToken(code: String) {
        let getTokenPath: String = "https://github.com/login/oauth/access_token"
        let tokenParams = ["client_id": clientID, "client_secret": clientSecret,
                           "code": code]
        let jsonHeader = ["Accept": "application/json"]
        let headers = HTTPHeaders(jsonHeader)
        
        AF.request(getTokenPath, method: .post, parameters: tokenParams, encoding: URLEncoding.default, headers: headers)
            .responseDecodable(of: OAuthToken.self) { response in
                // TODO: Handle response to get OAuth token
                if let error = response.error {
                    print(error)
                    self.isLoadingOAuthToken = false
                    return
                }
                
                guard let value = response.value else {
                    print("no string received in response when swapping oauth code for token")
                    self.isLoadingOAuthToken = false
                    return
                }
                
                self.oAuthToken = value.accessToken
                self.isLoadingOAuthToken = false
                
                if self.hasOAuthToken() {
                    self.printMyStarredGistsWithOAuth2()
                }
            }
    }
    
    func parseOAuthTokenResponse(_ json: [String: String]) -> String? {
        var token: String?
        for (key, value) in json {
            switch key {
            case "access_token":
                token = value
            case "scope":
                // TODO: verify scope
                print("SET SCOPE")
            case "token_type":
                // TODO: verify is bearer
                print("CHECK IF BEARER")
            default:
                print("got more than I expected from the OAuth token exchange")
                print(key)
            }
        }
        return token
    }
    
    func printMyStarredGistsWithOAuth2() {
        AF.request(GistRouter.getMyStarred)
            .responseString { response in
                guard response.error == nil else {
                    print(response.error!)
                    return
                }
                
                if let receivedString = response.value {
                    print(receivedString)
                }
            }
    }
    
    // MARK: - Helper methods
    
    private func parseNextPageFromHeaders(response: HTTPURLResponse?) -> String? {
        guard let linkHeader = response?.allHeaderFields["Link"] as? String else {
          return nil
        }
        /* looks like: <https://...?page=2>; rel="next", <https://...?page=6>; rel="last" */
        // so split on ","
        let components = linkHeader.components(separatedBy: ",")
        // now we have separate lines like '<https://...?page=2>; rel="next"'
        for item in components {
          // see if it's "next"
          let rangeOfNext = item.range(of: "rel=\"next\"", options: [])
          guard rangeOfNext != nil else {
            continue
          }
          // this is the "next" item, extract the URL
          let rangeOfPaddedURL = item.range(of: "<(.*)>;",
                                            options: .regularExpression,
                                            range: nil,
                                            locale: nil)
          guard let range = rangeOfPaddedURL else {
            return nil
          }
          // strip off the < and >;
          let start = item.index(range.lowerBound, offsetBy: 1)
          let end = item.index(range.upperBound, offsetBy: -2)
          let trimmedSubstring = item[start..<end]
          return String(trimmedSubstring)
        }
        return nil
      }
}
