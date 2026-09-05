# swift-openfootball

Complete football seasons — English pyramid, Scottish Premiership, the European
majors — with **no key at all**.

```swift
import OpenFootball

let football = OpenFootball()

try await football.table(.premierLeague, "2024-25")        // all 20 rows
try await football.table(.scottishPremiership, "2024-25")  // Celtic, Rangers, all 12
try await football.results(.championship, "2025-26")
```

## Why this exists

Free tiers of the commercial football APIs are thinner than they look. Measured
on 2026-09-05, TheSportsDB's free key returns the Premier League table
**truncated to its top 5 rows of 20**, and one fixture out of a ten-match
matchday. That is not a table.

The [openfootball](https://github.com/openfootball/football.json) project
publishes each season as plain JSON in a public repository. No key, no account,
no quota, no truncation — and the table is *computed here from the results*, so
you get all twenty rows, correct.

## Coverage

| | |
|---|---|
| England | Premier League, Championship, League One, League Two |
| Scotland | Premiership |
| Europe | Bundesliga 1–2, La Liga 1–2, Serie A–B, Ligue 1–2, Eredivisie, Primeira Liga, Belgian Pro League, Austrian Bundesliga, Super League Greece, Süper Lig, Champions League |
| Elsewhere | Liga MX, A-League |
| Seasons | 21 published, 2010-11 onward |

Competitions accept the names people type: `epl`, `prem`, `spl`, `ucl`, or the
dataset codes (`en.1`, `sco.1`).

## The table is computed, and checked against the record books

```swift
let table = try await football.table(.premierLeague, "2024-25")
table[0]   // Liverpool FC — 84 pts, played 38
table[1]   // Arsenal FC
```

Ordering is the standard three keys: points, then goal difference, then goals
scored. Ties beyond that are broken alphabetically for determinism — the real
competitions use head-to-head or a play-off, which a results list cannot settle,
and a stated convention beats an invented one.

Older seasons used two points for a win, so that is a parameter:

```swift
Table.build(from: matches, pointsForWin: 2)
```

A live test asserts the computed 2024/25 Premier League table against the known
final table (Liverpool on 84, Arsenal second, 38 games each, league-wide goal
difference summing to zero) and the Scottish Premiership at 12 clubs with Celtic
champions. Both passed on 2026-09-05.

## What it does not do

**No live scores.** This is a dataset, not a feed — a match in progress has no
score here until the repository is updated. For live scores use a keyed provider.
For "who won", "what is the table" and anything historical, this is complete and
free.

A published season contains its whole fixture list from day one, so most of it
has no score for most of the year. `match.isPlayed` is the difference between a
fixture and a result, and the table ignores unplayed ones — a mid-season table is
the table as it stands, not a projection.

## Details worth knowing

- Scores arrive packed as arrays (`{"ft": [4, 2], "ht": [1, 0]}`); they come out
  as `homeGoals` / `awayGoals`, half-time included.
- A knockout competition refuses to produce a table rather than inventing one —
  and refuses before spending a request.
- Season strings are `2025-26` (or `2025` for calendar-year leagues), validated
  including the consecutive-year rule, so `2025-30` is rejected before a fetch.

## Tested

19 tests. Sixteen offline, including a four-club league played out by hand with
a known final order; three live, skipped unless asked for:

```console
$ OF_LIVE=1 swift test --filter LiveTests
```

## Licence

MIT for this code. The datasets are openfootball's, published as open data
under the [Public Domain Dedication](https://github.com/openfootball/football.json).

## Installation

```swift
.package(url: "https://github.com/arraypress/swift-openfootball.git", from: "0.1.0")
```
