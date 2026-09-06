//
//  Match.swift
//  OpenFootball
//
//  Created by David Sherlock on 2026.
//

//

import Foundation

/// One fixture, played or not.
public struct Match: Sendable, Codable, Equatable {
    /// `Matchday 1`, `Regular, Matchday 1`.
    public let round: String?
    /// `yyyy-MM-dd`.
    public let date: String?
    /// `20:00`, when known.
    public let time: String?
    /// The home club, as the dataset spells it.
    public let home: String
    /// The away club, as the dataset spells it.
    public let away: String
    /// Goals at full time, when the match has been played.
    public let homeGoals: Int?
    /// Goals the away side scored. Absent for a match not yet played.
    public let awayGoals: Int?
    /// Goals at half time, where the dataset records them.
    public let homeHalfTimeGoals: Int?
    /// Away goals at half time, where the dataset records them.
    public let awayHalfTimeGoals: Int?

    /// Whether the match has a result.
    ///
    /// A published season contains its whole fixture list from day one, so
    /// most of it has no score for most of the year — this is the difference
    /// between a fixture and a result.
    public var isPlayed: Bool { homeGoals != nil && awayGoals != nil }

    /// The winner's name, or `nil` for a draw or an unplayed match.
    public var winner: String? {
        guard let homeGoals, let awayGoals else { return nil }
        if homeGoals > awayGoals { return home }
        if awayGoals > homeGoals { return away }
        return nil
    }

    private enum CodingKeys: String, CodingKey {
        case round, date, time, team1, team2, score
    }
    private enum ScoreKeys: String, CodingKey { case ht, ft }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.round = try? container.decodeIfPresent(String.self, forKey: .round)
        self.date = try? container.decodeIfPresent(String.self, forKey: .date)
        self.time = try? container.decodeIfPresent(String.self, forKey: .time)
        self.home = (try? container.decode(String.self, forKey: .team1)) ?? ""
        self.away = (try? container.decode(String.self, forKey: .team2)) ?? ""

        // Scores are two-element arrays: {"ft": [4, 2], "ht": [1, 0]}.
        let score = try? container.nestedContainer(keyedBy: ScoreKeys.self, forKey: .score)
        let fullTime = Match.pair(score, .ft)
        let halfTime = Match.pair(score, .ht)
        self.homeGoals = fullTime?.0
        self.awayGoals = fullTime?.1
        self.homeHalfTimeGoals = halfTime?.0
        self.awayHalfTimeGoals = halfTime?.1
    }

    public init(round: String? = nil, date: String? = nil, time: String? = nil,
                home: String, away: String, homeGoals: Int? = nil, awayGoals: Int? = nil,
                homeHalfTimeGoals: Int? = nil, awayHalfTimeGoals: Int? = nil) {
        self.round = round
        self.date = date
        self.time = time
        self.home = home
        self.away = away
        self.homeGoals = homeGoals
        self.awayGoals = awayGoals
        self.homeHalfTimeGoals = homeHalfTimeGoals
        self.awayHalfTimeGoals = awayHalfTimeGoals
    }

    /// Reads a `[home, away]` score array.
    private static func pair(_ container: KeyedDecodingContainer<ScoreKeys>?,
                             _ key: ScoreKeys) -> (Int, Int)? {
        guard let container,
              let goals = (try? container.decodeIfPresent([Int].self, forKey: key)) ?? nil,
              goals.count == 2
        else { return nil }
        return (goals[0], goals[1])
    }
}
