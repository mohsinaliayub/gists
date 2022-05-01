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
    
    case getPublic
    
    func asURLRequest() throws -> URLRequest {
        var method: HTTPMethod {
            switch self {
            case .getPublic:
                return .get
            }
        }
        
        let url: URL = {
            let relativePath: String
            switch self {
            case .getPublic:
                relativePath = "gists/public"
            }
            
            let url = URL(string: GistRouter.baseURLString)!
            return url.appendingPathComponent(relativePath)
        }()
        
        // no params to send with this request so ignore them for now
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        return urlRequest
    }
}
