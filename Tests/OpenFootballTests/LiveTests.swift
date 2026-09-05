//
//  LiveTests.swift
//  OpenFootballTests
//
//  Created by David Sherlock on 2026.
//
//      OF_LIVE=1 swift test --filter LiveTests
//

import Foundation
import XCTest
@testable import OpenFootball

final class LiveTests: XCTestCase {

    private var isEnabled: Bool { ProcessInfo.processInfo.environment["OF_LIVE"] == "1" }

    /// Ground truth: the 2024/25 Premier League was won by Liverpool on 84
    /// points from 38 games, with Arsenal second. If the computed table says
    /// anything else, the computation is wrong — not the record books.
    func testTheComputedTableMatchesTheKnownFinalTable() async throws {
        try XCTSkipUnless(isEnabled, "set OF_LIVE=1 to run")

        let table = try await OpenFootball().table(.premierLeague, "2024-25")
        XCTAssertEqual(table.count, 20, "the Premier League is twenty clubs")

        let champion = try XCTUnwrap(table.first)
        XCTAssertTrue(champion.team.contains("Liverpool"), "2024/25 was Liverpool's: got \(champion.team)")
        XCTAssertEqual(champion.points, 84, "Liverpool finished on 84")
        XCTAssertEqual(champion.played, 38, "a Premier League season is 38 games")

        let second = try XCTUnwrap(table.dropFirst().first)
        XCTAssertTrue(second.team.contains("Arsenal"), "Arsenal were second: got \(second.team)")

        // Every club plays every other twice.
        for row in table {
            XCTAssertEqual(row.played, 38, "\(row.team) played \(row.played)")
            XCTAssertEqual(row.won + row.drawn + row.lost, 38)
        }
        // Goals scored across the league must equal goals conceded.
        XCTAssertEqual(table.reduce(0) { $0 + $1.goalsFor },
                       table.reduce(0) { $0 + $1.goalsAgainst },
                       "every goal scored is a goal conceded")
        XCTAssertEqual(table.reduce(0) { $0 + $1.goalDifference }, 0)
    }

    func testTheScottishPremiershipCarriesCelticAndRangers() async throws {
        try XCTSkipUnless(isEnabled, "set OF_LIVE=1 to run")

        let table = try await OpenFootball().table(.scottishPremiership, "2024-25")
        XCTAssertEqual(table.count, 12, "the Scottish Premiership is twelve clubs")

        let names = table.map(\.team)
        XCTAssertTrue(names.contains { $0.contains("Celtic") }, "\(names)")
        XCTAssertTrue(names.contains { $0.contains("Rangers") }, "\(names)")

        let champion = try XCTUnwrap(table.first)
        XCTAssertTrue(champion.team.contains("Celtic"), "Celtic won 2024/25: got \(champion.team)")
    }

    func testAnUnpublishedSeasonIsNotFoundRatherThanACrash() async throws {
        try XCTSkipUnless(isEnabled, "set OF_LIVE=1 to run")
        do {
            _ = try await OpenFootball().matches(.scottishPremiership, "2026-27")
            // If it has since been published, that is fine too.
        } catch let error as OpenFootballError {
            guard case .noDataset = error else { return XCTFail("expected .noDataset, got \(error)") }
        }
    }
}
