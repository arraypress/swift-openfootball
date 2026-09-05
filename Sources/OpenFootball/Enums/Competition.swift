//
//  Competition.swift
//  OpenFootball
//
//  Created by David Sherlock on 2026.
//
//  The datasets are addressed by a country-and-tier code — `en.1` is the
//  Premier League, `en.2` the Championship, `sco.1` the Scottish
//  Premiership. Typing them keeps the codes out of call sites and makes the
//  catalogue enumerable, which is what an agent needs to answer "what can I
//  ask for?".
//

import Foundation

/// A competition with a published dataset.
public enum Competition: String, CaseIterable, Sendable, Codable {
    // England — the full pyramid, all four professional tiers.
    case premierLeague = "en.1"
    case championship = "en.2"
    case leagueOne = "en.3"
    case leagueTwo = "en.4"
    // Scotland.
    case scottishPremiership = "sco.1"
    // The rest of the majors.
    case bundesliga = "de.1"
    case bundesliga2 = "de.2"
    case laLiga = "es.1"
    case laLiga2 = "es.2"
    case serieA = "it.1"
    case serieB = "it.2"
    case ligue1 = "fr.1"
    case ligue2 = "fr.2"
    case eredivisie = "nl.1"
    case primeiraLiga = "pt.1"
    case proLeague = "be.1"
    case austrianBundesliga = "at.1"
    case superLeagueGreece = "gr.1"
    case superLig = "tr.1"
    case ligaMX = "mx.1"
    case aLeague = "au.1"
    case championsLeague = "uefa.cl"

    /// What a person calls it.
    public var displayName: String {
        switch self {
        case .premierLeague: return "Premier League"
        case .championship: return "Championship"
        case .leagueOne: return "League One"
        case .leagueTwo: return "League Two"
        case .scottishPremiership: return "Scottish Premiership"
        case .bundesliga: return "Bundesliga"
        case .bundesliga2: return "2. Bundesliga"
        case .laLiga: return "La Liga"
        case .laLiga2: return "La Liga 2"
        case .serieA: return "Serie A"
        case .serieB: return "Serie B"
        case .ligue1: return "Ligue 1"
        case .ligue2: return "Ligue 2"
        case .eredivisie: return "Eredivisie"
        case .primeiraLiga: return "Primeira Liga"
        case .proLeague: return "Belgian Pro League"
        case .austrianBundesliga: return "Austrian Bundesliga"
        case .superLeagueGreece: return "Super League Greece"
        case .superLig: return "Süper Lig"
        case .ligaMX: return "Liga MX"
        case .aLeague: return "A-League"
        case .championsLeague: return "UEFA Champions League"
        }
    }

    /// Where it is played.
    public var country: String {
        switch self {
        case .premierLeague, .championship, .leagueOne, .leagueTwo: return "England"
        case .scottishPremiership: return "Scotland"
        case .bundesliga, .bundesliga2: return "Germany"
        case .laLiga, .laLiga2: return "Spain"
        case .serieA, .serieB: return "Italy"
        case .ligue1, .ligue2: return "France"
        case .eredivisie: return "Netherlands"
        case .primeiraLiga: return "Portugal"
        case .proLeague: return "Belgium"
        case .austrianBundesliga: return "Austria"
        case .superLeagueGreece: return "Greece"
        case .superLig: return "Türkiye"
        case .ligaMX: return "Mexico"
        case .aLeague: return "Australia"
        case .championsLeague: return "Europe"
        }
    }

    /// Whether a league table means anything here.
    ///
    /// A knockout cup has no single table, so computing one would be a lie.
    public var hasLeagueTable: Bool { self != .championsLeague }

    /// Accepts the names people type — `epl`, `prem`, `spl`, `en.1`.
    public init?(alias: String) {
        let key = alias.lowercased().replacingOccurrences(of: " ", with: "")
        switch key {
        case "epl", "prem", "premierleague", "en1": self = .premierLeague
        case "efl", "championship", "en2": self = .championship
        case "leagueone", "en3": self = .leagueOne
        case "leaguetwo", "en4": self = .leagueTwo
        case "spl", "spfl", "scottish", "scottishpremiership", "sco1": self = .scottishPremiership
        case "ucl", "cl", "championsleague": self = .championsLeague
        case "laliga", "es1": self = .laLiga
        case "seriea", "it1": self = .serieA
        case "ligue1", "fr1": self = .ligue1
        case "bundesliga", "de1": self = .bundesliga
        default:
            guard let match = Competition(rawValue: alias.lowercased()) else { return nil }
            self = match
        }
    }
}
