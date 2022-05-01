//
//  BackendError.swift
//  Gists
//
//  Created by Mohsin Ali Ayub on 01.05.22.
//

import Foundation

enum BackendError: Error {
    case network(error: Error)
    case unexpectedResponse(reason: String)
    case parsing(error: Error)
    case apiProvidedError(reason: String)
    case authCouldNot(reason: String)
    case authLost(reason: String)
}

struct APIProvidedError: Codable {
    let message: String
}
