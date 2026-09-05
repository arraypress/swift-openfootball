//
//  Table.swift
//  OpenFootball
//
//  Created by David Sherlock on 2026.
//
//  The league table, computed from results.
//
//  This is the part worth having. The datasets publish fixtures and scores
//  but no table, so building one here is what turns "a list of matches" into
//  "who is top" — with no key, for any of 21 published seasons.
//
//  It is a pure function over matches, which means it is exactly testable:
//  a known season in, a known table out, no network.
//
//  Ordering is the standard three-key sort used by the English and Scottish
//  leagues: points, then goal difference, then goals scored. Where those all
//  tie, clubs are ordered alphabetically so the output is deterministic —
//  the real competitions break such ties by head-to-head or a play-off, which
//  a results list alone cannot settle, and inventing an order would be worse
//  than a stated convention.
//

import Foundation

/// Builds a table out of played matches.
public enum Table {

    /// Points for a win. Three since 1981 in England, 1994 elsewhere; older
    /// seasons in the archive used two, so this is a parameter, not a magic
    /// number buried in the loop.
    public static let pointsForWin = 3
    public static let pointsForDraw = 1

    /// The table after every played match, leader first.
    ///
    /// Unplayed fixtures are ignored, so calling this mid-season gives the
    /// table as it stands rather than a projection.
    public static func build(from matches: [Match], pointsForWin: Int = Table.pointsForWin) -> [TableRow] {
        var rows: [String: Tally] = [:]

        for match in matches where match.isPlayed {
            guard let homeGoals = match.homeGoals, let awayGoals = match.awayGoals else { continue }
            rows[match.home, default: Tally()].add(scored: homeGoals, conceded: awayGoals)
            rows[match.away, default: Tally()].add(scored: awayGoals, conceded: homeGoals)
        }

        let ordered = rows
            .map { TableRow(team: $0.key, tally: $0.value, pointsForWin: pointsForWin) }
            .sorted(by: TableRow.standardOrder)

        return ordered.enumerated().map { index, row in
            var row = row
            row.position = index + 1
            return row
        }
    }

    /// A club's running counts.
    struct Tally {
        var won = 0, drawn = 0, lost = 0, goalsFor = 0, goalsAgainst = 0

        mutating func add(scored: Int, conceded: Int) {
            goalsFor += scored
            goalsAgainst += conceded
            if scored > conceded { won += 1 } else if scored == conceded { drawn += 1 } else { lost += 1 }
        }
    }
}

/// One row of a computed table.
public struct TableRow: Sendable, Codable, Equatable {
    /// Where the club sits, 1-based. Filled in once the table is ordered.
    public internal(set) var position: Int = 0
    public let team: String
    public let played: Int
    public let won: Int
    public let drawn: Int
    public let lost: Int
    public let goalsFor: Int
    public let goalsAgainst: Int
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
