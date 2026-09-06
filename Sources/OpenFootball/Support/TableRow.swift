//
//  TableRow.swift
//  OpenFootball
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One row of a computed table.
public struct TableRow: Sendable, Codable, Equatable {
    /// Where the club sits, 1-based. Filled in once the table is ordered.
    public internal(set) var position: Int = 0
    /// The club this row is for.
    public let team: String
    /// Matches played.
    public let played: Int
    /// Matches won.
    public let won: Int
    /// Matches drawn.
    public let drawn: Int
    /// Matches lost.
    public let lost: Int
    /// Goals scored.
    public let goalsFor: Int
    /// Goals conceded.
    public let goalsAgainst: Int
    /// League points, computed from the results, not read from the dataset.
    public let points: Int

    /// Goals scored minus conceded.
    public var goalDifference: Int { goalsFor - goalsAgainst }

    init(team: String, tally: Table.Tally, pointsForWin: Int) {
        self.team = team
        self.won = tally.won
        self.drawn = tally.drawn
        self.lost = tally.lost
        self.played = tally.won + tally.drawn + tally.lost
        self.goalsFor = tally.goalsFor
        self.goalsAgainst = tally.goalsAgainst
        self.points = tally.won * pointsForWin + tally.drawn * Table.pointsForDraw
    }

    /// Points, then goal difference, then goals scored, then name.
    ///
    /// The name is the last key only to make the output deterministic — see
    /// the note in ``Table``.
    static func standardOrder(_ lhs: TableRow, _ rhs: TableRow) -> Bool {
        if lhs.points != rhs.points { return lhs.points > rhs.points }
        if lhs.goalDifference != rhs.goalDifference { return lhs.goalDifference > rhs.goalDifference }
        if lhs.goalsFor != rhs.goalsFor { return lhs.goalsFor > rhs.goalsFor }
        return lhs.team < rhs.team
    }
}
