//
//  JSONEncoder+EncodeResponse.swift
//  Gists
//
//  Created by Mohsin Ali Ayub on 01.05.22.
//

import Foundation
import Alamofire

extension JSONDecoder {
    func decodeResponse<T: Decodable>(from response: AFDataResponse<Data>) -> Result<T, BackendError> {
        guard response.error == nil else {
            // got an error in getting the data
            print(response.error!)
            return .failure(.network(error: response.error!))
        }
        
        // make sure we got JSON in response
        guard let responseData = response.data else {
            print("Didn't get any data from API")
            return .failure(.unexpectedResponse(reason: "Did not get data in response"))
        }
        
        // check for "message" errors in the JSON because this API does that
        if let apiProvidedError = try? self.decode(APIProvidedError.self, from: responseData) {
            return .failure(.apiProvidedError(reason: apiProvidedError.message))
        }
        
        // turn data into expected type
        do {
            let item = try self.decode(T.self, from: responseData)
            return .success(item)
        } catch {
            print("error trying to convert data to JSON")
            print(error)
            return .failure(.parsing(error: error))
        }
    }
}
