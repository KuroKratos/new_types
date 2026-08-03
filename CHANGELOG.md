# Changelog

Format: [keep a changelog](https://keepachangelog.com/en/1.1.0/).
Version headings match `manifest.json`'s `version`.

## 1.1.0

### Changed

- **The four machine givers are now new NPCs the mod places itself**, instead
  of scripts bolted onto existing characters. Each gets its own sprite, text
  constant and once-only flag, so no vanilla conversation is overwritten and
  none has to be replayed as a consolation line after the gift.
- Steel's giver moved **into the Power Plant** (7, 34), where Magnemite and
  Magneton live. That map has no vanilla NPC objects at all, which is exactly
  why the previous version had to settle for a Vermilion sailor.
- The other three: a little girl in **Mt. Moon 1F** (6, 6) for Moonblast, a
  Rocket grunt in **Celadon City** (33, 29) for Crunch, and a beauty in
  **Fuchsia City** (11, 12) for Play Rough.
- Every cell was proven walkable by rendering the real map and resolving its
  collision tile; every sprite id and object index was checked against an
  imported cache for existence and collisions.

## 1.0.0

### Added

- **DARK**, **STEEL** and **FAIRY**, with 39 new chart cells covering both
  their offensive and defensive halves, including all three immunities.
- **13 moves** across the three types, plus two secondary effects the engine
  had no equivalent of (a stat *rise* as a side effect — Gen 1 has none).
- **13 machines**, eight on Celadon's TM counter and four given by NPCs:
  a Rocket grunt in Celadon (Crunch), the Mt. Moon hiker (Moonblast), a
  Fuchsia youngster (Play Rough) and a Vermilion sailor (Iron Tail).
- **NEW TYPES**, **NEW TMS** and **BIG BAG** rows in OPTIONS, plus a
  **TYPE CHART** choice between `GEN6` and `GEN1`.

### Changed

- The four cells Gen 2 corrected. The big one: **Ghost now hits Psychic for
  2×** instead of 0 — the famous Gen 1 bug — so Psychic finally has two
  answers rather than none.
- Eleven species retyped to their modern typings.
- **Bite** is Dark, as Gen 2 made it.
- The bag holds **100** items; thirteen machines do not fit in twenty slots.
