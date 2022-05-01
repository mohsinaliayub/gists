//
//  GitHubAPIManager.swift
//  Gists
//
//  Created by Mohsin Ali Ayub on 01.05.22.
//

import Foundation
import Alamofire

class GitHubAPIManager {
    static let sharedInstance = GitHubAPIManager()
    
    func printPublicGists() {
        AF.request(GistRouter.getPublic).responseString { response in
            if let receivedString = response.value {
                print(receivedString)
            }
        }
    }
    
    func getPublicGists(completion: @escaping (Result<[Gist], BackendError>) -> Void) {
        AF.request(GistRouter.getPublic).responseData { response in
            let decoder = JSONDecoder()
            let result: Result<[Gist], BackendError> = decoder.decodeResponse(from: response)
            completion(result)
        }
    }
}