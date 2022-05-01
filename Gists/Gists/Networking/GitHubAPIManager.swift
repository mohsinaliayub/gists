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
    
    func getPublicGists(completion: @escaping (Result<[Gist], BackendError>) -> Void) {
        AF.request(GistRouter.getPublic).responseData { response in
            let decoder = JSONDecoder()
            let result: Result<[Gist], BackendError> = decoder.decodeResponse(from: response)
            completion(result)
        }
    }
    
    func image(fromURL url: URL, completion: @escaping (UIImage?, Error?) -> Void) {
        AF.request(url).responseData { response in
            guard let data = response.data else {
                completion(nil, response.error)
                return
            }
            
            let image = UIImage(data: data)
            completion(image, nil)
        }
    }
}
