//
//  GistRouter.swift
//  Gists
//
//  Created by Mohsin Ali Ayub on 01.05.22.
//

import Foundation
import Alamofire

enum GistRouter: URLRequestConvertible {
    static let baseURLString = "https://api.github.com"
    
    case getPublic // GET https://api.github.com/gists/public
    case getMyStarred // GET https://api.github.com/gists/starred
    case getAtPath(String) // GET at given path
    
    func asURLRequest() throws -> URLRequest {
        var method: HTTPMethod {
            switch self {
            case .getPublic, .getAtPath(_), .getMyStarred:
                return .get
            }
        }
        
        let url: URL = {
            let relativePath: String
            switch self {
            case .getPublic:
                relativePath = "gists/public"
            case .getAtPath(let path):
                // already have the full path, so return it
                return URL(string: path)!
            case .getMyStarred:
                relativePath = "gists/starred"
            }
            
            let url = URL(string: GistRouter.baseURLString)!
            return url.appendingPathComponent(relativePath)
        }()
        
        // no params to send with this request so ignore them for now
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        
        // Set OAuth token if we have one
        if let token = GitHubAPIManager.sharedInstance.oAuthToken {
            urlRequest.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return urlRequest
    }
}
