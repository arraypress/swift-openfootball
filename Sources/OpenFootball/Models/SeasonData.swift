//
//  SeasonData.swift
//  OpenFootball
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A published season of a competition.
public struct SeasonData: Sendable, Codable, Equatable {
    /// The dataset's own name — "English Premier League 2025/26".
    public let name: String
    /// Every match of the season, in the order the dataset lists them.
    public let matches: [Match]

    private enum CodingKeys: String, CodingKey { case name, matches }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = (try? container.decode(String.self, forKey: .name)) ?? ""
        self.matches = (try? container.decode([Match].self, forKey: .matches)) ?? []
    }

    public init(name: String, matches: [Match]) {
        self.name = name
        self.matches = matches
    }

    /// Every club appearing in the fixture list.
    public var teams: [String] {
        Array(Set(matches.flatMap { [$0.home, $0.away] })).sorted()
    }
}
