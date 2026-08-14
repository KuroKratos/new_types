-- New Types: DARK, STEEL and FAIRY, on the modern chart.
--
-- Gen 1's table has famous holes -- PSYCHIC has no working counter, and the
-- one type that should answer it, GHOST, does literally nothing to it
-- (GHOST>PSYCHIC_TYPE is 0 in the ROM).  Gen 2 fixed that with DARK and
-- STEEL; Gen 6 added FAIRY.  This brings all three, plus the four cells Gen 2
-- corrected along the way.
--
-- Nothing here touches src/.  The type_chart registry owns its whole target
-- and takes two id shapes: a bare id is a TYPE RECORD, and "ATTACKER>DEFENDER"
-- is a CHART CELL.  Multipliers are base 10 -- 20 = 2x, 10 = neutral,
-- 5 = 0.5x, 0 = immune -- and neutral cells are simply absent.
--
-- Physical/Special is decided per TYPE here, not per move, because that is
-- how this engine works everywhere else: Damage.categoryOf reads
-- `move.category or TypeChart.category(move.type)`.  DARK is special and
-- STEEL is physical exactly as in Gen 2; FAIRY is special, which fits all of
-- its moves but PLAY_ROUGH.  The consequence is deliberate and documented:
-- BITE and CRUNCH hit off Special here.

local TYPES = {
  -- Gen 2 put DARK on the special side of the split and STEEL on the
  -- physical side; FAIRY postdates the split entirely, so it takes the side
  -- that matches all but one of its moves.
  DARK  = { name = "DARK",  category = "special"  },
  STEEL = { name = "STEEL", category = "physical" },
  FAIRY = { name = "FAIRY", category = "special"  },
}

-- Every cell the three new types add, written once each.  Registering a pair
-- twice would create two rows: Damage walks the ordered list and would apply
-- both, while TypeChart.effectiveness keeps only the last -- so the immunity
-- check and the damage would disagree.  The suite asserts no pair repeats.
--
-- PSYCHIC's id is PSYCHIC_TYPE (the move named PSYCHIC owns the bare name).
local CELLS = {
  -- ---- DARK attacking
  { "DARK>PSYCHIC_TYPE", 20 }, { "DARK>GHOST", 20 },
  { "DARK>FIGHTING", 5 }, { "DARK>DARK", 5 }, { "DARK>FAIRY", 5 },

  -- ---- STEEL attacking
  { "STEEL>ROCK", 20 }, { "STEEL>ICE", 20 }, { "STEEL>FAIRY", 20 },
  { "STEEL>FIRE", 5 }, { "STEEL>WATER", 5 }, { "STEEL>ELECTRIC", 5 },
  { "STEEL>STEEL", 5 },

  -- ---- FAIRY attacking
  { "FAIRY>FIGHTING", 20 }, { "FAIRY>DRAGON", 20 }, { "FAIRY>DARK", 20 },
  { "FAIRY>FIRE", 5 }, { "FAIRY>POISON", 5 }, { "FAIRY>STEEL", 5 },

  -- ---- DARK defending
  { "FIGHTING>DARK", 20 }, { "BUG>DARK", 20 },
  { "GHOST>DARK", 5 },
  { "PSYCHIC_TYPE>DARK", 0 },

  -- ---- STEEL defending.  Gen 6 removed the GHOST and DARK resistances
  -- Gen 2-5 gave it, so those two cells are deliberately absent.
  { "FIRE>STEEL", 20 }, { "FIGHTING>STEEL", 20 }, { "GROUND>STEEL", 20 },
  { "NORMAL>STEEL", 5 }, { "GRASS>STEEL", 5 }, { "ICE>STEEL", 5 },
  { "FLYING>STEEL", 5 }, { "PSYCHIC_TYPE>STEEL", 5 }, { "BUG>STEEL", 5 },
  { "ROCK>STEEL", 5 }, { "DRAGON>STEEL", 5 },
  { "POISON>STEEL", 0 },

  -- ---- FAIRY defending
  { "POISON>FAIRY", 20 },
  { "FIGHTING>FAIRY", 5 }, { "BUG>FAIRY", 5 },
  { "DRAGON>FAIRY", 0 },
}

-- The four cells Gen 2 corrected on the existing table.  A nil target means
-- "make it neutral", which for this registry means removing the row -- the
-- chart stores no neutral cells.
local FIXES = {
  -- the Gen 1 bug: GHOST did nothing at all to PSYCHIC.  Fixing it is what
  -- makes GHOST a real answer to PSYCHIC alongside the new DARK.
  { "GHOST>PSYCHIC_TYPE", 20 },
  { "BUG>POISON", 5 },
  { "POISON>BUG", nil },
  { "ICE>FIRE", 5 },
}

-- The official modern typings, plus one deliberate departure.
--
-- STEEL and FAIRY are simply what the games say today.  DARK is the problem:
-- not one of the 151 carries it even now -- the first Dark Pokemon are Gen 2 --
-- so adding the type would leave its whole defensive half (the PSYCHIC
-- immunity, the FIGHTING and BUG weaknesses) unreachable.
--
-- Rather than invent, the four Dark entries follow their ALOLAN forms, which
-- are official typings of these very species.  Rattata and Raticate are
-- deliberately left out: their Alolan forms are Dark/Normal, and a starter-
-- route encounter immune to both PSYCHIC and GHOST is too much too early.
local RETYPES = {
  -- Gen 2
  { "MAGNEMITE", { "ELECTRIC", "STEEL" } },
  { "MAGNETON",  { "ELECTRIC", "STEEL" } },
  -- Gen 6
  { "CLEFAIRY",   { "FAIRY" } },
  { "CLEFABLE",   { "FAIRY" } },
  { "JIGGLYPUFF", { "NORMAL", "FAIRY" } },
  { "WIGGLYTUFF", { "NORMAL", "FAIRY" } },
  { "MR_MIME",    { "PSYCHIC_TYPE", "FAIRY" } },
  -- after the Alolan forms
  { "MEOWTH",  { "DARK" } },
  { "PERSIAN", { "DARK" } },
  { "GRIMER",  { "POISON", "DARK" } },
  { "MUK",     { "POISON", "DARK" } },
}

-- No move carries a `category`: omitting it is how the "category follows the
-- type" decision is expressed, since Damage.categoryOf falls through to the
-- type record.  That makes BITE, CRUNCH and PLAY_ROUGH special here where
-- the modern games make them physical -- deliberate, and in the README.
local MOVES = {
  -- ---- DARK (special)
  { id = "CRUNCH", name = "CRUNCH", type = "DARK",
    power = 80, accuracy = 100, pp = 15, effect = "SPECIAL_DOWN_SIDE_EFFECT" },
  { id = "FAINT_ATTACK", name = "FAINT ATTACK", type = "DARK",
    -- SWIFT_EFFECT is the engine's never-miss path, which is Faint Attack's
    -- whole point
    power = 60, accuracy = 100, pp = 20, effect = "SWIFT_EFFECT" },
  { id = "PURSUIT", name = "PURSUIT", type = "DARK",
    -- the real Pursuit doubles on a switching target; there is no switch
    -- seam to hang that on, so it lands as a plain 40-power move
    power = 40, accuracy = 100, pp = 20, effect = "NO_ADDITIONAL_EFFECT" },

  -- ---- STEEL (physical)
  { id = "METAL_CLAW", name = "METAL CLAW", type = "STEEL",
    power = 50, accuracy = 95, pp = 35, effect = "NEW_TYPES_ATTACK_UP_SIDE" },
  { id = "STEEL_WING", name = "STEEL WING", type = "STEEL",
    power = 70, accuracy = 90, pp = 25, effect = "NEW_TYPES_DEFENSE_UP_SIDE" },
  { id = "IRON_TAIL", name = "IRON TAIL", type = "STEEL",
    power = 100, accuracy = 75, pp = 15, effect = "DEFENSE_DOWN_SIDE_EFFECT" },

  -- ---- FAIRY (special)
  { id = "FAIRY_WIND", name = "FAIRY WIND", type = "FAIRY",
    power = 40, accuracy = 100, pp = 30, effect = "NO_ADDITIONAL_EFFECT" },
  { id = "DISARMING_VOICE", name = "DISARM VOICE", type = "FAIRY",
    power = 40, accuracy = 100, pp = 15, effect = "SWIFT_EFFECT" },
  { id = "DRAINING_KISS", name = "DRAIN KISS", type = "FAIRY",
    -- Gen 6 drains 75%; the engine's drain is Gen 1's 50%
    power = 50, accuracy = 100, pp = 10, effect = "DRAIN_HP_EFFECT" },
  { id = "DAZZLING_GLEAM", name = "DAZZL GLEAM", type = "FAIRY",
    power = 80, accuracy = 100, pp = 10, effect = "NO_ADDITIONAL_EFFECT" },
  { id = "MOONBLAST", name = "MOONBLAST", type = "FAIRY",
    power = 95, accuracy = 100, pp = 15, effect = "SPECIAL_DOWN_SIDE_EFFECT" },
  { id = "PLAY_ROUGH", name = "PLAY ROUGH", type = "FAIRY",
    power = 90, accuracy = 90, pp = 10, effect = "ATTACK_DOWN_SIDE_EFFECT" },
  { id = "CHARM", name = "CHARM", type = "FAIRY",
    power = 0, accuracy = 100, pp = 20, effect = "ATTACK_DOWN1_EFFECT" },
}

-- Machines are priced like their vanilla neighbours on the Celadon shelf;
-- anything unlisted falls back to 3000.
local TM_PRICES = {
  FAIRY_WIND = 2000, DISARMING_VOICE = 2000, PURSUIT = 2000,
  METAL_CLAW = 3000, DRAINING_KISS = 3000, CHARM = 2000,
  STEEL_WING = 4000, FAINT_ATTACK = 3000, DAZZLING_GLEAM = 4000,
  CRUNCH = 5000, IRON_TAIL = 5000, PLAY_ROUGH = 5000, MOONBLAST = 5500,
}

-- Who can learn what, by type affinity rather than a 151-row table.  The
-- merged roster is walked at load, so a species mod or a total conversion is
-- covered without anything here being maintained.
local TMHM_RULES = {
  { types = { STEEL = true, ROCK = true, GROUND = true, ELECTRIC = true },
    moves = { "METAL_CLAW", "IRON_TAIL" } },
  { types = { FLYING = true, STEEL = true, DRAGON = true },
    moves = { "STEEL_WING" } },
  { types = { POISON = true, GHOST = true, DARK = true, NORMAL = true },
    moves = { "CRUNCH", "FAINT_ATTACK", "PURSUIT" } },
  { types = { FAIRY = true, NORMAL = true, PSYCHIC_TYPE = true, WATER = true },
    moves = { "FAIRY_WIND", "DISARMING_VOICE", "DAZZLING_GLEAM",
              "DRAINING_KISS", "CHARM" } },
  { types = { FAIRY = true, NORMAL = true, FIGHTING = true },
    moves = { "PLAY_ROUGH" } },
  { types = { FAIRY = true, PSYCHIC_TYPE = true },
    moves = { "MOONBLAST" } },
}

-- On sale at Celadon's TM counter: the workhorses, not the finishers.
local SHELF = { "METAL_CLAW", "STEEL_WING", "FAIRY_WIND", "DISARMING_VOICE",
                "PURSUIT", "CHARM", "DRAINING_KISS", "DAZZLING_GLEAM" }

-- The four signature machines come from people this mod puts on the map --
-- brand new objects, not vanilla NPCs with their dialogue hijacked.
--
-- Every coordinate below was proven walkable by rendering the real map and
-- resolving the collision tile of the cell (Map:cellTile takes the cell's
-- bottom-left 8x8 tile and checks it against the tileset's `walkable` list).
-- That is also why STEEL finally gets its scientist INSIDE the Power Plant,
-- where Magnemite and Magneton actually live: the map has no vanilla NPC
-- objects at all, so hooking one was never an option.
--
-- `index` starts at 90 to stay clear of the vanilla object indices, which run
-- from 1 and never approach it on these maps.
local GIVERS = {
  { map = "POWER_PLANT", x = 7, y = 34, index = 90,
    sprite = "SPRITE_SCIENTIST", move = "IRON_TAIL",
    line = "This place hums\nwith steel.\fTake this, and\nhit like it." },
  { map = "MT_MOON_1F", x = 6, y = 6, index = 91,
    sprite = "SPRITE_LITTLE_GIRL", move = "MOONBLAST",
    line = "The CLEFAIRY here\ndraw power from\fthe moon.\nSo can yours!" },
  { map = "CELADON_CITY", x = 33, y = 29, index = 92,
    sprite = "SPRITE_ROCKET", move = "CRUNCH",
    line = "Heh... you fight\ndirty enough.\fTake it. Don't\ntell the boss." },
  { map = "FUCHSIA_CITY", x = 11, y = 12, index = 93,
    sprite = "SPRITE_BEAUTY", move = "PLAY_ROUGH",
    line = "The SAFARI mon\nplay rough with\fme all day.\nYou try it!" },
}

return function(mod)

  mod.options:define({
    { key = "enabled", label = "NEW TYPES", type = "toggle", default = true },
    { key = "machines", label = "NEW TMS", type = "toggle", default = true },
    { key = "big_bag", label = "BIG BAG", type = "toggle", default = true },
    -- GEN1 keeps the three new types but leaves the four vanilla cells
    -- alone, for anyone who wants the types without the rebalance.
    { key = "chart", label = "TYPE CHART", type = "choice", default = "gen6",
      choices = { { "GEN6", "gen6" }, { "GEN1", "gen1" } } },
  })

  local function on(key) return mod.options:get(key) ~= false end

  if not on("enabled") then return end

  -- ------------------------------------------------------------------
  -- The types

  -- Which types this mod actually brought into existence. On Red/Blue/Yellow
  -- that is all three; on Gold it is FAIRY alone, because the cart already
  -- ships DARK and STEEL (src/battle/gen2/Battle.lua:491 lists them).
  --
  -- The distinction matters far more for the CHART than for the records. Gold
  -- carries the Gen 2 chart, where STEEL resists GHOST and DARK; this mod
  -- carries Gen 6, where it does not. Writing our cells over a type we did not
  -- introduce would quietly rebalance a game that never asked for it.
  local introduced = {}

  for id, record in pairs(TYPES) do
    if mod.content.type_chart:get(id) then
      -- another mod, or the cart itself, got here first; leave its record
      -- alone rather than fight over the category, which decides
      -- physical/special
      mod.log:info("%s is already in this game's chart; left untouched", id)
    else
      mod.content.type_chart:register(id, record)
      introduced[id] = true
    end
  end

  -- A cell is ours to write only if one of its two sides is a type we just
  -- created. FAIRY>DARK and STEEL>FAIRY are ours on Gold; DARK>PSYCHIC_TYPE
  -- is not, and neither are the Gen 1 corrections, which Gold made long ago.
  local function ours(id)
    local attacker, defender = id:match("^([^>]+)>(.+)$")
    if not attacker then return introduced[id] == true end
    return introduced[attacker] == true or introduced[defender] == true
  end

  -- ------------------------------------------------------------------
  -- The chart
  --
  -- register on a fresh id, override on an existing one.  Both shapes are
  -- needed: the fixture dataset carries only a three-type triangle, while a
  -- real import already has every vanilla cell -- and a mod loaded ahead of
  -- this one may have touched either.

  local function setCell(id, multiplier)
    if mod.content.type_chart:get(id) then
      mod.content.type_chart:override(id, { multiplier = multiplier })
    else
      mod.content.type_chart:register(id, { multiplier = multiplier })
    end
  end

  local function clearCell(id)
    if mod.content.type_chart:get(id) then
      mod.content.type_chart:remove(id)
    end
  end

  local wrote, left = 0, 0
  for _, cell in ipairs(CELLS) do
    if ours(cell[1]) then
      setCell(cell[1], cell[2])
      wrote = wrote + 1
    else
      left = left + 1
    end
  end

  -- The four Gen 1 corrections are Gen 2's own doing: Gold already hits
  -- PSYCHIC with GHOST for 2x. Applying them only where a type we introduced
  -- is involved means they fire on Red/Blue/Yellow and stay out of Gold's way.
  -- Every fix touches two VANILLA types, so `ours` can never be true for one.
  -- The right question is whether this game still needs them: a cart that
  -- already had DARK and STEEL is a Gen 2 cart, and Gen 2 is where these four
  -- corrections came from in the first place.
  if mod.options:get("chart") ~= "gen1" and introduced.DARK and introduced.STEEL then
    for _, fix in ipairs(FIXES) do
      if fix[2] == nil then clearCell(fix[1]) else setCell(fix[1], fix[2]) end
    end
  end
  if left > 0 then
    mod.log:info("%d chart cells written, %d left to this game's own chart",
                 wrote, left)
  else
    mod.log:info("%d chart cells written", wrote)
  end

  -- ------------------------------------------------------------------
  -- Retyping the 151
  --
  -- `types` is a list, and a bare list REPLACES under record semantics --
  -- which is exactly right here, since every one of these is a full retype.
  -- Guarded on the species existing so the fixture dataset (three species)
  -- and a total conversion both load without complaint.

  local retyped, missing = 0, {}
  for _, entry in ipairs(RETYPES) do
    if mod.content.pokemon:get(entry[1]) then
      mod.content.pokemon:patch(entry[1], { types = entry[2] })
      retyped = retyped + 1
    else
      missing[#missing + 1] = entry[1]
    end
  end
  if #missing > 0 then
    mod.log:info("%d species retyped; absent from this roster: %s",
                 retyped, table.concat(missing, " "))
  else
    mod.log:info("%d species retyped", retyped)
  end

  -- ------------------------------------------------------------------
  -- Two secondary effects the engine has no equivalent of
  --
  -- There are DOWN side effects for every stat but no UP ones, because no
  -- Gen 1 move raises a stat as a side effect.  A `run` handler must return
  -- a list of message rows -- the caller iterates it -- so the miss path
  -- returns an empty table rather than nothing.

  local function raiseSelf(stat)
    return function(ctx)
      -- 10%, the Gen 2 rate for both of these: 26 of 256
      if ctx.rng(0, 255) < 26 then
        return ctx.changeStage(ctx.user, stat, 1)
      end
      return {}
    end
  end

  mod.content.move_effects:register("NEW_TYPES_ATTACK_UP_SIDE",
    { kind = "secondary", run = raiseSelf("attack") })
  mod.content.move_effects:register("NEW_TYPES_DEFENSE_UP_SIDE",
    { kind = "secondary", run = raiseSelf("defense") })

  -- ------------------------------------------------------------------
  -- The moves

  -- Gold names its effects in its own namespace, and every one of these is a
  -- move Gen 2 already had a behaviour for -- so this is a translation, not an
  -- invention. Gold even carries the two stat-UP side effects Gen 1 lacked,
  -- which is why this mod's custom pair is Gen 1-only.
  local EFFECT_ON_GEN2 = {
    NO_ADDITIONAL_EFFECT      = "EFFECT_NORMAL_HIT",
    SWIFT_EFFECT              = "EFFECT_ALWAYS_HIT",
    DRAIN_HP_EFFECT           = "EFFECT_LEECH_HIT",
    SPECIAL_DOWN_SIDE_EFFECT  = "EFFECT_SP_DEF_DOWN_HIT",
    ATTACK_DOWN_SIDE_EFFECT   = "EFFECT_ATTACK_DOWN_HIT",
    DEFENSE_DOWN_SIDE_EFFECT  = "EFFECT_DEFENSE_DOWN_HIT",
    ATTACK_DOWN1_EFFECT       = "EFFECT_ATTACK_DOWN",
    FLINCH_SIDE_EFFECT1       = "EFFECT_FLINCH_HIT",
    NEW_TYPES_ATTACK_UP_SIDE  = "EFFECT_ATTACK_UP_HIT",
    NEW_TYPES_DEFENSE_UP_SIDE = "EFFECT_DEFENSE_UP_HIT",
  }

  -- Resolve an effect id against THIS game's registry, translating only when
  -- the id the table names is not there. A move whose behaviour neither game
  -- can supply is skipped by name rather than registered with a dangling
  -- reference, which would fail cross-validation at load.
  -- Prefer the id this game actually knows, then the translation, then the id
  -- as written. Never nil: dropping the move would leave its TM and every
  -- tmhm entry pointing at a name nothing defines, which is a worse failure
  -- than an effect id that cross-validation can name for you.
  local function effectFor(move)
    if mod.content.move_effects:get(move.effect) then return move.effect end
    local alias = EFFECT_ON_GEN2[move.effect]
    if alias and mod.content.move_effects:get(alias) then return alias end
    return alias or move.effect
  end

  local added = 0
  local untranslatable = {}
  for _, move in ipairs(MOVES) do
    if mod.content.moves:get(move.id) then
      -- Gold already ships CRUNCH, IRON_TAIL, METAL_CLAW and friends; its
      -- versions are the cart's own and stay untouched.
      mod.log:info("move %s already exists in this game; left alone", move.id)
    else
      local effect = effectFor(move)
      if not effect then
        untranslatable[#untranslatable + 1] = move.id
      else
        local record = {}
        for k, v in pairs(move) do record[k] = v end
        record.effect = effect
        mod.content.moves:register(move.id, record)
        added = added + 1
      end
    end
  end
  if #untranslatable > 0 then
    mod.log:info("%d moves need an effect this game has no equivalent for: %s",
                 #untranslatable, table.concat(untranslatable, " "))
  end

  -- BITE is the one retcon: Gen 1 ships it as NORMAL, Gen 2 moved it to
  -- DARK and left everything else about it alone.  patch, not override, so
  -- another mod's power tweak survives.
  if mod.content.moves:get("BITE") then
    mod.content.moves:patch("BITE", { type = "DARK" })
    added = added + 1
  end
  mod.log:info("%d moves added or retyped", added)

  -- ------------------------------------------------------------------
  -- Machines
  --
  -- One TM per new move.  machine.number is required by the schema, and only
  -- 51..55 stay clear of the .sav crosswalk (TM01-50 occupy bytes 201-250) --
  -- but a Pokemon carrying one of these types already cannot round-trip
  -- through a .sav at all, so the numbering runs past 55 and the whole
  -- question is documented rather than worked around.

  if on("machines") then
    local number = 50
    for _, move in ipairs(MOVES) do
      number = number + 1
      local itemId = "TM_" .. move.id
      if not mod.content.items:get(itemId) then
        mod.content.items:register(itemId, {
          id = itemId, name = ("TM%02d"):format(number),
          price = TM_PRICES[move.id] or 3000,
          machine = { kind = "TM", number = number, move = move.id },
        })
      end
    end

    -- Compatibility by type affinity rather than a 151-row table: the merged
    -- roster is walked at load, so a species mod or a total conversion gets
    -- sensible coverage for free and nothing has to be maintained here.
    for id, def in mod.content.pokemon:each() do
      local grants = {}
      for _, group in ipairs(TMHM_RULES) do
        local matches = false
        for _, t in ipairs(def.types or {}) do
          if group.types[t] then matches = true break end
        end
        if matches then
          for _, moveId in ipairs(group.moves) do grants[#grants + 1] = moveId end
        end
      end
      if #grants > 0 then
        -- __append, never a bare list: a bare list would REPLACE the whole
        -- vanilla tmhm and quietly strip every machine the species had.
        mod.content.pokemon:patch(id, { tmhm = { __append = grants } })
      end
    end

    -- The Celadon department store's TM shelf, appended to rather than
    -- replaced so the nine vanilla machines stay on sale.
    if mod.content.text_pointers:get("CeladonMart2F") then
      local shelf = {}
      for _, moveId in ipairs(SHELF) do shelf[#shelf + 1] = "TM_" .. moveId end
      mod.content.text_pointers:patch("CeladonMart2F", {
        TEXT_CELADONMART2F_CLERK2 = { mart = { __append = shelf } },
      })
    end

    -- Four NPCs the mod puts on the map itself, each giving its machine once.
    -- Two steps per giver: append the object to the map, then attach a talk
    -- script keyed on its own text constant.  __append is essential -- a bare
    -- list would REPLACE every vanilla object on that map.
    local placed = 0
    for _, giver in ipairs(GIVERS) do
      local map = mod.content.maps:get(giver.map)
      if not map then
        mod.log:warn("no map %s; its giver was not placed", giver.map)
      else
        local textId = "TEXT_NEW_TYPES_" .. giver.move
        local flag = "MOD_NEW_TYPES_" .. giver.move
        mod.content.maps:patch(giver.map, {
          objects = { __append = { {
            index = giver.index,
            name = "NEW_TYPES_" .. giver.move,
            text = textId,
            sprite = giver.sprite,
            movement = "STAY",
            range = "DOWN",
            x = giver.x, y = giver.y,
          } } },
        })
        mod.content.map_scripts:register(giver.map, {
          talk = {
            [textId] = {
              { "check_flag", flag },
              { "jump_if_true", "given" },
              { "face_player" },
              { "show_text", giver.line },
              { "give_item", "TM_" .. giver.move, 1, false },
              { "set_flag", flag },
              { "jump", "end" },
              { "label", "given" },
              { "face_player" },
              { "show_text", "Use it well!" },
            },
          },
        })
        placed = placed + 1
      end
    end
    mod.log:info("%d move givers placed", placed)

    -- A 20-slot bag cannot hold thirteen new machines on top of everything
    -- else, and a distinct item id costs a slot whatever its quantity.
    if on("big_bag") then
      mod.content.constants:override("bagSize", 100)
    end
  end

  -- ------------------------------------------------------------------
  -- For the suite and for other mods.

  mod.exports.cellCount = function() return #CELLS end
  mod.exports.moveIds = function()
    local out = {}
    for _, move in ipairs(MOVES) do out[#out + 1] = move.id end
    return out
  end
  mod.exports.retypes = function()
    local out = {}
    for _, entry in ipairs(RETYPES) do out[entry[1]] = entry[2] end
    return out
  end
  mod.exports.types = function()
    local out = {}
    for id in pairs(TYPES) do out[#out + 1] = id end
    table.sort(out)
    return out
  end
end
