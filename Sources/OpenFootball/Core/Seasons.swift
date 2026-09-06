//
//  Seasons.swift
//  OpenFootball
//
//  Created by David Sherlock on 2026.
//

import Foundation

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
