//
//  OpenFootball.swift
//  OpenFootball
//
//  Created by David Sherlock on 2026.
//
//  Football results as open data, keyless.
//
//  The openfootball project publishes each season of the major European
//  leagues as plain JSON in a public repository. There is no API, no key and
//  no quota — the files are fetched straight from raw.githubusercontent.com.
//
//  What that buys, and what it costs:
//
//    + complete seasons, not the truncated top five rows a free tier gives
//    + the whole English pyramid plus the Scottish Premiership
//    + 21 published seasons, so historical questions cost nothing
//    − no live scores: this is a dataset, not a feed. A match in progress has
//      no score here until the repository is updated.
//
//  For live scores use a keyed provider; for "who won" and "what is the
//  table", this is complete and free.
//

import Foundation

/// A keyless client for the openfootball datasets.
public struct OpenFootball: Sendable {

    /// How requests are performed — injectable so tests run on recordings.
    public typealias Transport = @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)

    public static let defaultUserAgent = "swift-openfootball/0.1 (+https://github.com/arraypress/swift-openfootball)"
    /// Where the datasets are served from.
    public static let defaultBaseURL = "https://raw.githubusercontent.com/openfootball/football.json/master"

    public let userAgent: String
    private let baseURL: String
    private let transport: Transport

    public init(userAgent: String = OpenFootball.defaultUserAgent,
                baseURL: String = OpenFootball.defaultBaseURL,
                transport: Transport? = nil) {
        self.userAgent = userAgent
        self.baseURL = baseURL
        self.transport = transport ?? { request in
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw OpenFootballError.malformed("not an HTTP response")
            }
            return (data, http)
        }
    }

    // MARK: - Fixtures and results

    /// A season's whole fixture list, played and unplayed.
    ///
    /// - Parameter season: `2025-26` for a split-year league, or `2025` for
    ///   one played inside a calendar year.
    public func season(_ competition: Competition,
                       _ season: String) async throws -> SeasonData {
        guard Seasons.isValid(season) else { throw OpenFootballError.badSeason(season) }
        let data = try await get("/\(season)/\(competition.rawValue).json", competition: competition, season: season)
        do {
            return try JSONDecoder().decode(SeasonData.self, from: data)
        } catch {
            throw OpenFootballError.malformed(error.localizedDescription)
        }
    }

    /// A season's matches.
    public func matches(_ competition: Competition, _ season: String) async throws -> [Match] {
        try await self.season(competition, season).matches
    }

    /// Only the matches that have been played, most recent last.
    public func results(_ competition: Competition, _ season: String) async throws -> [Match] {
        try await matches(competition, season).filter(\.isPlayed)
    }

    /// Only the matches still to come.
    public func fixtures(_ competition: Competition, _ season: String) async throws -> [Match] {
        try await matches(competition, season).filter { !$0.isPlayed }
    }

    // MARK: - Table

    /// The league table, computed from results.
    ///
    /// - Throws: ``OpenFootballError/noTable(_:)`` for a knockout competition,
    ///   which has no single table to compute.
    public func table(_ competition: Competition, _ season: String) async throws -> [TableRow] {
        guard competition.hasLeagueTable else {
            throw OpenFootballError.noTable(competition.displayName)
        }
        return Table.build(from: try await matches(competition, season))
    }

    // MARK: - Transport

    private func get(_ path: String, competition: Competition, season: String) async throws -> Data {
        guard let url = URL(string: baseURL + path) else {
            throw OpenFootballError.malformed("could not build a URL for \(path)")
        }
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await transport(request)
        switch response.statusCode {
        case 200:
            return data
        case 404:
            // The usual case by far: a season not yet published, or a league
            // that did not run that year. Worth its own error rather than a
            // bare 404, because it is expected rather than exceptional.
            throw OpenFootballError.noDataset(competition: competition.displayName, season: season)
        default:
            throw OpenFootballError.http(response.statusCode)
        }
    }
}

/// Season strings, and what a valid one looks like.
public enum Seasons {

    /// Whether `text` is `2025-26` or `2025`.
    public static func isValid(_ text: String) -> Bool {
        if text.count == 4, Int(text) != nil { return true }
        let parts = text.split(separator: "-")
        guard parts.count == 2, parts[0].count == 4, parts[1].count == 2,
              let start = Int(parts[0]), let end = Int(parts[1])
        else { return false }
        // 2025-26 is consecutive; 2025-30 is not a season.
        return (start + 1) % 100 == end
    }

    /// The split-year season a date falls in — `2025-26`.
    ///
    /// European football runs August to May, so the season is named for the
    /// year it began. July is the cut-over used here.
    public static func current(on date: Date = Date()) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        let parts = calendar.dateComponents([.year, .month], from: date)
        let year = parts.year ?? 0
        let start = (parts.month ?? 1) >= 7 ? year : year - 1
        return String(format: "%04d-%02d", start, (start + 1) % 100)
    }
}
