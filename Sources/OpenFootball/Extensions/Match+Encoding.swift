//
//  Match+Encoding.swift
//  OpenFootball
//
//  Created by David Sherlock on 2026.
//
//  Written by hand because a custom `init(from:)` suppresses synthesis, and
//  useful anyway: the dataset packs scores into `{"ft": [4, 2]}` arrays, and
//  re-emitting that would push the unpacking onto everyone downstream.
//

import Foundation

extension Match {
    private enum OutputKeys: String, CodingKey {
        case round, date, time, home, away, homeGoals, awayGoals
        case homeHalfTimeGoals, awayHalfTimeGoals, isPlayed, winner
    }

    /// Writes the flattened shape, not the one the dataset stores.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: OutputKeys.self)
        try container.encodeIfPresent(round, forKey: .round)
        try container.encodeIfPresent(date, forKey: .date)
        try container.encodeIfPresent(time, forKey: .time)
        try container.encode(home, forKey: .home)
        try container.encode(away, forKey: .away)
        try container.encodeIfPresent(homeGoals, forKey: .homeGoals)
        try container.encodeIfPresent(awayGoals, forKey: .awayGoals)
        try container.encodeIfPresent(homeHalfTimeGoals, forKey: .homeHalfTimeGoals)
        try container.encodeIfPresent(awayHalfTimeGoals, forKey: .awayHalfTimeGoals)
        try container.encode(isPlayed, forKey: .isPlayed)
        try container.encodeIfPresent(winner, forKey: .winner)
    }
}
