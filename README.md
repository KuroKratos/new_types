# New Types

DARK, STEEL and FAIRY, on the modern chart — with the official retypings, their
moves, and places to learn them.

**Persona: the Mechanic Designer.** Registry work only; no engine seam, no
permission, no source edit.

## Try it

```sh
python3 tools/modkit.py validate mods/new_types --strict
```

```sh
python3 tools/modkit.py lint mods/new_types
```

```sh
luajit mods/new_types/tests/new_types_test.lua
```

## Why

Gen 1's table has a hole you can drive a Mewtwo through. Psychic has no working
counter, and the one type that should answer it does *literally nothing* to it:
`GHOST>PSYCHIC_TYPE` is **0** in the ROM. Gen 2 fixed that with Dark and Steel;
Gen 6 added Fairy. This brings all three, and the four cells Gen 2 corrected
along the way.

## The chart

Multipliers are base 10 in this engine — `20` = 2×, `10` = neutral, `5` = 0.5×,
`0` = immune — and neutral cells are simply absent.

### Offence

| Attacking | 2× | 0.5× |
|---|---|---|
| **DARK** | Psychic, Ghost | Fighting, Dark, Fairy |
| **STEEL** | Rock, Ice, Fairy | Fire, Water, Electric, Steel |
| **FAIRY** | Fighting, Dragon, Dark | Fire, Poison, Steel |

### Defence

| Defending | takes 2× from | takes 0.5× from | immune to |
|---|---|---|---|
| **DARK** | Fighting, Bug, Fairy | Ghost, Dark | **Psychic** |
| **STEEL** | Fire, Fighting, Ground | Normal, Grass, Ice, Flying, Psychic, Bug, Rock, Dragon, Steel, Fairy | **Poison** |
| **FAIRY** | Poison, Steel | Fighting, Bug, Dark | **Dragon** |

This is the **Gen 6** chart, so Steel does *not* resist Ghost or Dark — that
was a Gen 2–5 property the newer games removed.

### The four corrections

| Cell | Gen 1 | Here |
|---|---|---|
| Ghost → Psychic | **0×** | 2× |
| Bug → Poison | 2× | 0.5× |
| Poison → Bug | 2× | neutral |
| Ice → Fire | neutral | 0.5× |

`TYPE CHART` in OPTIONS → MODS switches to `GEN1` to keep the three new types
without these four.

## Physical or special

This engine decides the split **by type**, not per move — `Damage.categoryOf`
reads `move.category or TypeChart.category(move.type)` — and every new move
leaves its `category` unset so the type answers for it. That is the Gen 2 model:

| Type | Category |
|---|---|
| DARK | **special** |
| STEEL | **physical** |
| FAIRY | **special** |

**The consequence is real and deliberate**: Bite, Crunch and Play Rough hit off
Special here, where the modern games make them physical. The alternative — a
category per move — would break the rule that holds Gen 1's whole balance
together, and would suddenly make high-Attack Pokémon good with types they
never were.

## The species

| Species | Was | Now | |
|---|---|---|---|
| Magnemite, Magneton | Electric | **Electric/Steel** | Gen 2 |
| Clefairy, Clefable | Normal | **Fairy** | Gen 6 |
| Jigglypuff, Wigglytuff | Normal | **Normal/Fairy** | Gen 6 |
| Mr. Mime | Psychic | **Psychic/Fairy** | Gen 6 |
| Meowth, Persian | Normal | **Dark** | *Alolan* |
| Grimer, Muk | Poison | **Poison/Dark** | *Alolan* |

The first four rows are simply what the games say today. **Dark is the problem**:
not one of the 151 carries it even now — the first Dark Pokémon are Gen 2 — so
the type would arrive with its whole defensive half unreachable.

Rather than invent, the four Dark entries follow their **Alolan forms**, which
are official typings of those very species. Rattata and Raticate were left out
on purpose: their Alolan form is Dark/Normal, and a Route 1 encounter immune to
both Psychic *and* Ghost is too much too early.

## The moves

| | Power | Acc | PP | |
|---|---|---|---|---|
| **Bite** | 60 | 100 | 25 | retyped Normal → Dark, as Gen 2 did |
| **Crunch** | 80 | 100 | 15 | 20% Special drop |
| **Faint Attack** | 60 | — | 20 | never misses |
| **Pursuit** | 40 | 100 | 20 | |
| **Metal Claw** | 50 | 95 | 35 | 10% Attack rise |
| **Steel Wing** | 70 | 90 | 25 | 10% Defense rise |
| **Iron Tail** | 100 | 75 | 15 | 30% Defense drop |
| **Fairy Wind** | 40 | 100 | 30 | |
| **Disarming Voice** | 40 | — | 15 | never misses |
| **Draining Kiss** | 50 | 100 | 10 | drains |
| **Dazzling Gleam** | 80 | 100 | 10 | |
| **Moonblast** | 95 | 100 | 15 | 30% Special drop |
| **Play Rough** | 90 | 90 | 10 | 10% Attack drop |
| **Charm** | — | 100 | 20 | drops Attack |

Two of these needed effects the engine did not have: **no Gen 1 move raises a
stat as a side effect**, so Metal Claw and Steel Wing register their own.

## Getting them

Eight machines sit on **Celadon's TM counter** (2F), appended to the nine
vanilla ones rather than replacing them. The four signature moves come from four
people, in places that fit:

| Who | Where | Cell | Gives |
|---|---|---|---|
| Scientist | Power Plant | 7, 34 | **Iron Tail** |
| Little girl | Mt. Moon 1F | 6, 6 | **Moonblast** |
| Rocket grunt | Celadon City | 33, 29 | **Crunch** |
| Beauty | Fuchsia City | 11, 12 | **Play Rough** |

**These are new NPCs, not vanilla ones wearing a new script.** Each is a fresh
object the mod appends to the map, with its own sprite, its own text constant
and its own once-only flag — so no existing character loses a line, and no
vanilla conversation is replayed as a consolation prize after the gift.

Every coordinate was proven walkable by rendering the real map and resolving the
cell's collision tile, not guessed. That is also why Steel's giver stands
**inside the Power Plant**, where Magnemite and Magneton actually live: that map
has no vanilla NPC objects at all, so an earlier draft had to put its scientist
in Vermilion instead. Placing an NPC removed the constraint.

Object indices start at 90, clear of the vanilla ones (which run from 1 and
never approach it on these maps) — the index is half the save key
`<map>_obj_<index>`, so a collision would make a giver share a "talked to" bit
with a real character.

Appending is done through `__append`. A bare list there would **replace** the
map's entire object table and delete every NPC on it; the test asserts the
neighbour survives.

Machine compatibility is granted by **type affinity**, walked over the merged
roster at load, so a species mod or a total conversion is covered without a
151-row table to maintain.

**The bag goes to 100 slots.** A distinct item id costs a slot whatever its
quantity, and thirteen machines do not fit in twenty. `BIG BAG` turns that off.

## Known limits

- **`.sav` export.** `GenSave`'s type table is hard-coded and unaware of the
  registry, so a Dark/Steel/Fairy Pokémon exports to a Game Boy save as
  **Normal**. This is the one hard wall.
- **`affects_link` is true.** `type_chart`, `moves` and `pokemon` are all on the
  link surface and the handshake hashes every type's category, so this cannot
  pair with a vanilla build. Correct, not a bug.
- **The four NPCs give a machine rather than teaching directly.** A true move
  tutor needs a custom command and a party-menu flow this mod does not carry.
- **A giver whose map is missing is silently skipped**, with a warning in the
  log. That is what happens on a fixture or a total conversion; on any real
  Red/Blue/Yellow import all four are placed.
- **Pursuit** is a plain 40-power move: its doubling against a switching target
  has no seam to hang on. **Draining Kiss** drains the engine's Gen 1 half
  rather than Gen 6's three quarters.
- Type names do not pass through `Strings()` in the engine, so they are not
  translatable.

## Credits

- pret/pokered — the type table, move and species data this extends.
