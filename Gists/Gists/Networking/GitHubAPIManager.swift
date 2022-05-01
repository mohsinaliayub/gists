//
//  GitHubAPIManager.swift
//  Gists
//
//  Created by Mohsin Ali Ayub on 01.05.22.
//

import Foundation
import Alamofire
import UIKit

class GitHubAPIManager {
    static let sharedInstance = GitHubAPIManager()
    
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
