//
//  RootInvitation.swift
//  IBM Security Verify
//
//  Created by Clayton Gilbert on 3/4/2025.
//
import Foundation

struct RootInvitation: Decodable {
    let invitation: Invitation
}

struct Invitation: Decodable {
    let type: String
    let id: String
    let label: String
    let recipientKeys: [String]
    let serviceEndpoint: String
    let routingKeys: [String]
    let ext: Bool
    let url: String
    let shortUrl: String

    private enum CodingKeys: String, CodingKey {
        case type = "@type"
        case id = "@id"
        case label
        case recipientKeys
        case serviceEndpoint
        case routingKeys
        case ext
        case url
        case shortUrl = "short_url"
    }
}
