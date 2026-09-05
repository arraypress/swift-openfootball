//
//  OpenFootballError.swift
//  OpenFootball
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// What can go wrong reading the datasets.
public enum OpenFootballError: Error, LocalizedError, Sendable, Equatable {
    /// No dataset for that competition and season — a season not yet
    /// published, or a league that did not run it.
    case noDataset(competition: String, season: String)
    case http(Int)
    case malformed(String)
    /// A season string that is not `2025-26` or `2025`.
    case badSeason(String)
    /// A table was asked for where one has no meaning.
    case noTable(String)

    public var errorDescription: String? {
        switch self {
        case .noDataset(let competition, let season):
            return "no dataset for \(competition) in \(season)"
        case .http(let code): return "the dataset host answered HTTP \(code)"
        case .malformed(let what): return "unexpected dataset shape: \(what)"
        case .badSeason(let text): return "\(text) is not a season like 2025-26 or 2025"
        case .noTable(let what): return "\(what) has no league table"
        }
    }
}
