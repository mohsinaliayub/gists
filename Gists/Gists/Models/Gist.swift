//
//  Gist.swift
//  Gists
//
//  Created by Mohsin Ali Ayub on 01.05.22.
//

import Foundation

struct Gist: Codable {
    struct Owner: Codable {
        var login: String
        var avatarURL: URL?
        
        enum CodingKeys: String, CodingKey {
            case login
            case avatarURL = "avatar_url"
        }
    }
    
    var id: String
    var description: String?
    var url: String
    var owner: Owner?
}
