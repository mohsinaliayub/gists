//
//  OAuthToken.swift
//  Gists
//
//  Created by Mohsin Ali Ayub on 09.05.22.
//

import Foundation

struct OAuthToken: Codable {
    let accessToken: String
    let tokenType: String
    let scope: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
    }
}
