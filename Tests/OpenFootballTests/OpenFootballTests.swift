//
//  OpenFootballTests.swift
//  OpenFootballTests
//
//  Created by David Sherlock on 2026.
//
//  Offline. The table computation is the part with real logic in it, so most
//  of this is a miniature league played out by hand with a known answer.
//

import Foundation
import XCTest
@testable import OpenFootball

final class OpenFootballTests: XCTestCase {

    private final class Recorder: @unchecked Sendable {
        var requests: [URLRequest] = []
        let body: String
        let status: Int
        init(_ body: String, status: Int = 200) { self.body = body; self.status = status }
        var transport: OpenFootball.Transport {
            { [self] request in
                requests.append(request)
                let response = HTTPURLResponse(url: request.url!, statusCode: status,
                                               httpVersion: nil, headerFields: [:])!
                return (Data(body.utf8), response)
            }
        }
    }

    // MARK: - Decoding

    func testAScoreArrivesAsAnArrayAndIsUnpacked() throws {
        let match = try JSONDecoder().decode(Match.self, from: Data("""
        { "round": "Matchday 1", "date": "2024-08-09", "time": "20:00",
          "team1": "Blackburn Rovers FC", "team2": "Derby County FC",
          "score": { "ht": [1, 0], "ft": [4, 2] } }
        """.utf8))

        XCTAssertEqual(match.home, "Blackburn Rovers FC")
        XCTAssertEqual(match.away, "Derby County FC")
        XCTAssertEqual(match.homeGoals, 4, "the score is a [home, away] array upstream")
        XCTAssertEqual(match.awayGoals, 2)
        XCTAssertEqual(match.homeHalfTimeGoals, 1)
        XCTAssertTrue(match.isPlayed)
        XCTAssertEqual(match.winner, "Blackburn Rovers FC")
    }

    func testAnUnplayedFixtureHasNoScoreAndNoWinner() throws {
        // A published season carries its whole fixture list from day one, so
        // most of it looks like this for most of the year.
        let match = try JSONDecoder().decode(Match.self, from: Data("""
        { "round": "Matchday 30", "date": "2026-04-11", "team1": "Celtic FC", "team2": "Rangers FC" }
        """.utf8))
        XCTAssertFalse(match.isPlayed)
        XCTAssertNil(match.winner)
        XCTAssertNil(match.homeGoals)
    }

    func testADrawHasNoWinner() throws {
        let match = try JSONDecoder().decode(Match.self, from: Data("""
        { "team1": "Heart of Midlothian", "team2": "Rangers FC", "score": { "ft": [0, 0] } }
        """.utf8))
        XCTAssertTrue(match.isPlayed)
        XCTAssertNil(match.winner, "a draw is played but has no winner — the two are different questions")
    }

    // MARK: - The table

    /// A four-club league played out by hand.
    ///
    ///   A beat B 2-0, A drew with C 1-1, A lost to D 0-1
    ///   B beat C 3-1, B drew with D 2-2
    ///   C beat D 2-0
    ///
    /// A: W1 D1 L1 = 4 pts, GF 3 GA 2 (+1)
    /// B: W1 D1 L1 = 4 pts, GF 5 GA 5 ( 0)
    /// C: W1 D1 L1 = 4 pts, GF 4 GA 4 ( 0)
    /// D: W1 D1 L1 = 4 pts, GF 3 GA 4 (−1)
    /// Every club is level on points, so goal difference orders them: A on
    /// +1, then B and C both on 0 — B scored more, so B before C — then D.
    private let miniLeague = [
        Match(home: "A", away: "B", homeGoals: 2, awayGoals: 0),
        Match(home: "A", away: "C", homeGoals: 1, awayGoals: 1),
        Match(home: "A", away: "D", homeGoals: 0, awayGoals: 1),
        Match(home: "B", away: "C", homeGoals: 3, awayGoals: 1),
        Match(home: "B", away: "D", homeGoals: 2, awayGoals: 2),
        Match(home: "C", away: "D", homeGoals: 2, awayGoals: 0),
    ]

    func testTheTableCountsPointsGoalsAndOrdersByTheStandardKeys() {
        let table = Table.build(from: miniLeague)

        XCTAssertEqual(table.map(\.team), ["A", "B", "C", "D"],
                       "points tie, so goal difference then goals scored decide")
        XCTAssertEqual(table.map(\.position), [1, 2, 3, 4])

        let a = try! XCTUnwrap(table.first { $0.team == "A" })
        XCTAssertEqual(a.played, 3)
        XCTAssertEqual(a.won, 1)
        XCTAssertEqual(a.drawn, 1)
        XCTAssertEqual(a.lost, 1)
        XCTAssertEqual(a.points, 4, "three for a win, one for a draw")
        XCTAssertEqual(a.goalsFor, 3)
        XCTAssertEqual(a.goalsAgainst, 2)
        XCTAssertEqual(a.goalDifference, 1)
    }

    func testEveryGoalScoredIsAGoalConceded() {
        let table = Table.build(from: miniLeague)
        XCTAssertEqual(table.reduce(0) { $0 + $1.goalsFor },
                       table.reduce(0) { $0 + $1.goalsAgainst })
        XCTAssertEqual(table.reduce(0) { $0 + $1.goalDifference }, 0,
                       "a whole league's goal difference must sum to zero")
    }

    func testUnplayedFixturesAreIgnoredSoAMidSeasonTableIsNotAProjection() {
        let withFixtures = miniLeague + [
            Match(home: "A", away: "B"),
            Match(home: "C", away: "D"),
        ]
        XCTAssertEqual(Table.build(from: withFixtures), Table.build(from: miniLeague))
        XCTAssertEqual(Table.build(from: withFixtures).first?.played, 3, "not 4")
    }

    func testTwoPointsForAWinReordersAnOlderSeason() {
        // Before 1981 a win was worth two, which changes who finishes above
        // whom when one club has more wins and another more draws.
        // Two wins against five draws is the case that flips.
        let matches = [
            Match(home: "Winners", away: "X", homeGoals: 1, awayGoals: 0),
            Match(home: "Winners", away: "Y", homeGoals: 1, awayGoals: 0),
            Match(home: "Drawers", away: "X", homeGoals: 0, awayGoals: 0),
            Match(home: "Drawers", away: "Y", homeGoals: 0, awayGoals: 0),
            Match(home: "Drawers", away: "Z", homeGoals: 0, awayGoals: 0),
            Match(home: "Drawers", away: "W", homeGoals: 0, awayGoals: 0),
            Match(home: "Drawers", away: "V", homeGoals: 0, awayGoals: 0),
        ]
        let modern = Table.build(from: matches)
        XCTAssertEqual(modern.first?.team, "Winners", "two wins is 6 points, five draws only 5")
        XCTAssertEqual(modern.first?.points, 6)

        let historic = Table.build(from: matches, pointsForWin: 2)
        XCTAssertEqual(historic.first?.team, "Drawers", "at two for a win it is 4 against 5, and the order flips")
        XCTAssertEqual(historic.first?.points, 5)
        XCTAssertEqual(historic.first(where: { $0.team == "Winners" })?.points, 4)
    }

    func testAnEmptySeasonProducesAnEmptyTableRatherThanACrash() {
        XCTAssertTrue(Table.build(from: []).isEmpty)
        XCTAssertTrue(Table.build(from: [Match(home: "A", away: "B")]).isEmpty,
                      "a fixture list with nothing played yet has no table")
    }

    // MARK: - Client

    func testTheDatasetPathIsSeasonThenCompetitionCode() async throws {
        let recorder = Recorder(#"{ "name": "x", "matches": [] }"#)
        _ = try await OpenFootball(transport: recorder.transport).matches(.scottishPremiership, "2024-25")

        let url = try XCTUnwrap(recorder.requests.first?.url?.absoluteString)
        XCTAssertTrue(url.hasSuffix("/2024-25/sco.1.json"), url)
        let agent = try XCTUnwrap(recorder.requests.first?.value(forHTTPHeaderField: "User-Agent"))
        XCTAssertTrue(agent.contains("swift-openfootball"))
    }

    func testAMissingDatasetIsItsOwnErrorBecauseItIsExpected() async {
        let recorder = Recorder("404: Not Found", status: 404)
        do {
            _ = try await OpenFootball(transport: recorder.transport).matches(.scottishPremiership, "2026-27")
            XCTFail("that season is not published")
        } catch let error as OpenFootballError {
            guard case .noDataset(let competition, let season) = error else {
                return XCTFail("expected .noDataset, got \(error)")
            }
            XCTAssertEqual(competition, "Scottish Premiership")
            XCTAssertEqual(season, "2026-27")
        } catch { XCTFail("unexpected \(error)") }
    }

    func testAKnockoutCompetitionRefusesATableRatherThanInventingOne() async {
        let recorder = Recorder(#"{ "name": "x", "matches": [] }"#)
        do {
            _ = try await OpenFootball(transport: recorder.transport).table(.championsLeague, "2024-25")
            XCTFail("a knockout cup has no single table")
        } catch let error as OpenFootballError {
            guard case .noTable = error else { return XCTFail("expected .noTable, got \(error)") }
        } catch { XCTFail("unexpected \(error)") }
        XCTAssertTrue(recorder.requests.isEmpty, "and it refuses before spending a request")
    }

    func testABadSeasonIsRefusedBeforeARequestIsMade() async {
        let recorder = Recorder("{}")
        do {
            _ = try await OpenFootball(transport: recorder.transport).matches(.premierLeague, "24/25")
            XCTFail("that is not a season string")
        } catch let error as OpenFootballError {
            XCTAssertEqual(error, .badSeason("24/25"))
        } catch { XCTFail("unexpected \(error)") }
        XCTAssertTrue(recorder.requests.isEmpty)
    }

    // MARK: - Seasons

    func testSeasonStringsAreValidatedIncludingTheConsecutiveYearRule() {
        XCTAssertTrue(Seasons.isValid("2025-26"))
        XCTAssertTrue(Seasons.isValid("2025"), "some leagues run inside a calendar year")
        XCTAssertTrue(Seasons.isValid("1999-00"), "the century rollover is still consecutive")
        XCTAssertFalse(Seasons.isValid("2025-30"), "not consecutive years")
        XCTAssertFalse(Seasons.isValid("24/25"))
        XCTAssertFalse(Seasons.isValid("2025-2026"), "the datasets use the two-digit second year")
        XCTAssertFalse(Seasons.isValid(""))
    }

    func testTheSeasonIsNamedForTheYearItBegan() throws {
        let august = try Date.ISO8601FormatStyle().parse("2025-08-15T00:00:00Z")
        let march = try Date.ISO8601FormatStyle().parse("2026-03-15T00:00:00Z")
        XCTAssertEqual(Seasons.current(on: august), "2025-26")
        XCTAssertEqual(Seasons.current(on: march), "2025-26",
                       "March belongs to the season that started the previous August")
    }

    // MARK: - Catalogue

    func testTheCatalogueCoversTheEnglishPyramidAndScotland() {
        let english = Competition.allCases.filter { $0.country == "England" }
        XCTAssertEqual(english.count, 4, "all four professional tiers")
        XCTAssertTrue(Competition.allCases.contains(.scottishPremiership))
        XCTAssertFalse(Competition.championsLeague.hasLeagueTable)
        XCTAssertTrue(Competition.premierLeague.hasLeagueTable)
    }

    func testAliasesAcceptWhatPeopleType() {
        XCTAssertEqual(Competition(alias: "epl"), .premierLeague)
        XCTAssertEqual(Competition(alias: "prem"), .premierLeague)
        XCTAssertEqual(Competition(alias: "SPL"), .scottishPremiership)
        XCTAssertEqual(Competition(alias: "en.1"), .premierLeague)
        XCTAssertEqual(Competition(alias: "ucl"), .championsLeague)
        XCTAssertNil(Competition(alias: "hurling"))
    }
}
