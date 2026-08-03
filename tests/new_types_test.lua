-- Standalone: luajit mods/new_types/tests/new_types_test.lua
--
-- Runs on the ROM-free fixture (CI has no ROM).  The fixture ships a
-- three-type FIRE/GRASS/WATER triangle and no `types` table at all -- the 15
-- vanilla type records arrive from Builtins during the load -- so everything
-- asserted here about the new types is genuinely produced by the mod.
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local TypeChart = require("src.battle.TypeChart")
local Damage = require("src.battle.Damage")

local Data = T.fixtures.fresh()

-- The fixture has three species and no BITE, so the retype and retcon paths
-- would silently no-op.  Inject just enough vanilla shape to exercise them.
local function species(id, dex, types)
  Data.pokemon[id] = { id = id, name = id, dex = dex, types = types,
    baseStats = { hp = 50, attack = 50, defense = 50, speed = 50, special = 50 },
    catchRate = 45, baseExp = 64, growthRate = "MEDIUM_FAST",
    level1Moves = {}, learnset = {}, tmhm = {}, evolutions = {} }
end
species("MAGNEMITE", 81, { "ELECTRIC" })
species("CLEFAIRY", 35, { "NORMAL" })
species("JIGGLYPUFF", 39, { "NORMAL" })
species("MR_MIME", 122, { "PSYCHIC_TYPE" })
species("MEOWTH", 52, { "NORMAL" })
species("MUK", 89, { "POISON" })
Data.moves.BITE = { id = "BITE", name = "BITE", type = "NORMAL",
  power = 60, accuracy = 100, pp = 25, effect = "FLINCH_SIDE_EFFECT1" }

-- One of the four giver maps, so the NPC placement runs for real.  It keeps
-- an object of its own: appending must not cost the map its inhabitants,
-- which is exactly what a bare list instead of __append would do.
local function flat(w, h, block)
  local blocks = {}
  for i = 1, w * h do blocks[i] = block end
  return blocks
end
Data.maps.POWER_PLANT = {
  id = "POWER_PLANT", label = "PowerPlant", index = 1099,
  tileset = "FIX_OUT", width = 10, height = 9, blocks = flat(10, 9, 1),
  borderBlock = 0,
  objects = {
    { index = 1, name = "FIX_RESIDENT", sprite = "SPRITE_FIX_NPC",
      movement = "STAY", range = "NONE", text = "TEXT_FIX_RESIDENT",
      x = 2, y = 2 },
  },
}

local run = T.sdk.loadMod("mods/new_types", { data = Data })
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")

-- effectiveness reads module state, not the data table
TypeChart.load(Data)

local function fx(attacker, ...)
  return TypeChart.effectiveness(attacker, { ... })
end

-- ------- the type records

do
  local types = Data.type_chart.types
  T.eq(types.DARK ~= nil, true, "DARK exists")
  T.eq(types.STEEL ~= nil, true, "STEEL exists")
  T.eq(types.FAIRY ~= nil, true, "FAIRY exists")

  -- the category IS the physical/special split in this engine
  T.eq(types.DARK.category, "special", "DARK is special, as in Gen 2")
  T.eq(types.STEEL.category, "physical", "STEEL is physical, as in Gen 2")
  T.eq(types.FAIRY.category, "special", "FAIRY is special")
  T.eq(Damage.isSpecial("DARK"), true, "and Damage agrees for DARK")
  T.eq(Damage.isSpecial("STEEL"), false, "and for STEEL")
  T.eq(Damage.isSpecial("FAIRY"), true, "and for FAIRY")

  -- the 15 vanilla records must survive untouched
  local count = 0
  for _ in pairs(types) do count = count + 1 end
  T.eq(count, 18, "15 vanilla types plus the three new ones")
  T.eq(types.FIRE.category, "special", "FIRE is still special")
  T.eq(types.NORMAL.category, "physical", "NORMAL is still physical")
end

-- ------- the immunities, which are the cells that bite hardest

do
  T.eq(fx("PSYCHIC_TYPE", "DARK"), 0, "PSYCHIC cannot touch DARK")
  T.eq(fx("POISON", "STEEL"), 0, "POISON cannot touch STEEL")
  T.eq(fx("DRAGON", "FAIRY"), 0, "DRAGON cannot touch FAIRY")
end

-- ------- DARK, the answer to PSYCHIC

do
  T.eq(fx("DARK", "PSYCHIC_TYPE"), 20, "DARK is super effective on PSYCHIC")
  T.eq(fx("DARK", "GHOST"), 20, "and on GHOST")
  T.eq(fx("DARK", "FIGHTING"), 5, "FIGHTING resists DARK")
  T.eq(fx("DARK", "DARK"), 5, "DARK resists itself")
  T.eq(fx("DARK", "FAIRY"), 5, "and FAIRY resists it")
  T.eq(fx("FIGHTING", "DARK"), 20, "FIGHTING hits DARK hard")
  T.eq(fx("BUG", "DARK"), 20, "so does BUG")
  T.eq(fx("GHOST", "DARK"), 5, "DARK resists GHOST")
end

-- ------- STEEL, and the Gen 6 nerf

do
  T.eq(fx("STEEL", "ROCK"), 20, "STEEL beats ROCK")
  T.eq(fx("STEEL", "ICE"), 20, "and ICE")
  T.eq(fx("STEEL", "FAIRY"), 20, "and FAIRY")
  T.eq(fx("STEEL", "FIRE"), 5, "FIRE resists STEEL")
  T.eq(fx("STEEL", "STEEL"), 5, "so does STEEL")
  T.eq(fx("FIRE", "STEEL"), 20, "FIRE melts STEEL")
  T.eq(fx("GROUND", "STEEL"), 20, "GROUND hits STEEL hard")
  T.eq(fx("FIGHTING", "STEEL"), 20, "and FIGHTING")
  T.eq(fx("NORMAL", "STEEL"), 5, "STEEL resists NORMAL")
  T.eq(fx("DRAGON", "STEEL"), 5, "and DRAGON")

  -- the Gen 6 change: Gen 2-5 STEEL resisted these two, Gen 6 does not
  T.eq(fx("GHOST", "STEEL"), 10, "Gen 6: STEEL no longer resists GHOST")
  T.eq(fx("DARK", "STEEL"), 10, "Gen 6: nor DARK")
end

-- ------- FAIRY

do
  T.eq(fx("FAIRY", "DRAGON"), 20, "FAIRY beats DRAGON")
  T.eq(fx("FAIRY", "FIGHTING"), 20, "and FIGHTING")
  T.eq(fx("FAIRY", "DARK"), 20, "and DARK")
  T.eq(fx("FAIRY", "STEEL"), 5, "STEEL resists FAIRY")
  T.eq(fx("FAIRY", "POISON"), 5, "so does POISON")
  T.eq(fx("POISON", "FAIRY"), 20, "and POISON hits FAIRY hard")
  T.eq(fx("STEEL", "FAIRY"), 20, "as does STEEL")
  T.eq(fx("FIGHTING", "FAIRY"), 5, "FAIRY resists FIGHTING")
end

-- ------- dual types stack, and the floor divides per defender type

do
  T.eq(fx("STEEL", "ROCK", "ICE"), 40, "two weaknesses multiply to 4x")
  T.eq(fx("FAIRY", "DRAGON", "STEEL"), 10, "2x then 0.5x lands back on neutral")
  T.eq(fx("PSYCHIC_TYPE", "DARK", "FIGHTING"), 0, "an immunity wins outright")
end

-- ------- the four Gen 2 corrections

do
  T.eq(fx("GHOST", "PSYCHIC_TYPE"), 20,
       "the Gen 1 bug is fixed: GHOST now hits PSYCHIC")
  T.eq(fx("BUG", "POISON"), 5, "BUG no longer beats POISON")
  T.eq(fx("ICE", "FIRE"), 5, "FIRE now resists ICE")
  -- POISON>BUG became NEUTRAL, and this chart stores no neutral cells --
  -- so the assertion is that the row is GONE, not that it reads 10
  T.eq(fx("POISON", "BUG"), 10, "POISON is now neutral into BUG")
  for _, row in ipairs(Data.type_chart.matchups) do
    T.neq(row.attacker .. ">" .. row.defender, "POISON>BUG",
          "and the POISON>BUG row was removed, not set to 10")
  end
end

-- ------- the retypings

do
  T.same(Data.pokemon.MAGNEMITE.types, { "ELECTRIC", "STEEL" },
         "MAGNEMITE gained STEEL")
  T.same(Data.pokemon.CLEFAIRY.types, { "FAIRY" },
         "CLEFAIRY is pure FAIRY, not Normal/Fairy")
  T.same(Data.pokemon.JIGGLYPUFF.types, { "NORMAL", "FAIRY" },
         "JIGGLYPUFF keeps NORMAL and gains FAIRY")
  T.same(Data.pokemon.MR_MIME.types, { "PSYCHIC_TYPE", "FAIRY" },
         "MR. MIME gains FAIRY")
  T.same(Data.pokemon.MEOWTH.types, { "DARK" }, "MEOWTH follows its Alolan form")
  T.same(Data.pokemon.MUK.types, { "POISON", "DARK" }, "so does MUK")

  -- the retype is a full replacement, and nothing else on the record moves
  T.eq(Data.pokemon.MAGNEMITE.baseStats.speed, 50, "base stats survive the patch")
  T.eq(Data.pokemon.CLEFAIRY.catchRate, 45, "and so does everything else")

  -- and the consequences that matter in a fight.  Spelled out rather than
  -- unpacked from the record: `and`/`or` truncate multiple returns to one,
  -- which silently tested MAGNEMITE as pure ELECTRIC the first time round.
  T.eq(fx("POISON", "ELECTRIC", "STEEL"), 0, "MAGNEMITE is now immune to POISON")
  T.eq(fx("GROUND", "STEEL"), 20, "and GROUND hits its STEEL half hard")
  -- the 4x from GROUND needs the vanilla GROUND>ELECTRIC cell, which the
  -- fixture triangle does not carry; the real-data check covers it
  T.eq(fx("DRAGON", "NORMAL", "FAIRY"), 0, "JIGGLYPUFF now walls DRAGON")
  T.eq(fx("PSYCHIC_TYPE", "DARK"), 0, "and MEOWTH is immune to PSYCHIC")
end

-- ------- the moves

do
  local moves = Data.moves
  T.eq(moves.BITE.type, "DARK", "BITE was retyped, as Gen 2 did")
  T.eq(moves.BITE.power, 60, "and kept its power")
  T.eq(moves.BITE.effect, "FLINCH_SIDE_EFFECT1", "and its flinch")

  T.eq(moves.MOONBLAST.type, "FAIRY", "MOONBLAST is FAIRY")
  T.eq(moves.MOONBLAST.power, 95, "at 95 power")
  T.eq(moves.IRON_TAIL.type, "STEEL", "IRON TAIL is STEEL")
  T.eq(moves.CRUNCH.type, "DARK", "CRUNCH is DARK")

  -- no move carries a category: that IS the "category follows the type"
  -- decision, and it is what makes BITE special here
  for _, id in ipairs(run.loader.exports.new_types.moveIds()) do
    T.eq(moves[id].category, nil, id .. " leaves its category to its type")
  end
  T.eq(Damage.isSpecial(moves.CRUNCH.type), true, "so CRUNCH hits off Special")
  T.eq(Damage.isSpecial(moves.IRON_TAIL.type), false, "and IRON TAIL off Attack")

  -- the two custom effects exist and are secondary
  T.eq(Data.move_effects.NEW_TYPES_ATTACK_UP_SIDE.kind, "secondary",
       "the stat-raising side effect registered")
  T.eq(type(Data.move_effects.NEW_TYPES_DEFENSE_UP_SIDE.run), "function",
       "and carries a handler")
end

-- ------- machines, compatibility and the bag

do
  local Bag = require("src.inventory.Bag")

  T.eq(Data.items.TM_MOONBLAST ~= nil, true, "every new move got a machine")
  T.eq(Data.items.TM_MOONBLAST.machine.move, "MOONBLAST", "pointing at its move")
  T.eq(Data.items.TM_MOONBLAST.machine.kind, "TM", "as a TM, not an HM")
  T.check(Data.items.TM_MOONBLAST.machine.number > 50,
          "numbered past the vanilla fifty")

  -- every machine number must be distinct, or two TMs collide in the save
  local numbers = {}
  for id, def in pairs(Data.items) do
    if def.machine then
      T.eq(numbers[def.machine.number], nil,
           "machine number " .. def.machine.number .. " is unique (" .. id .. ")")
      numbers[def.machine.number] = id
    end
  end

  -- compatibility is granted by type affinity, and __append must not have
  -- eaten the vanilla list
  local magnemite = Data.pokemon.MAGNEMITE
  local has = {}
  for _, m in ipairs(magnemite.tmhm) do has[m] = true end
  T.eq(has.METAL_CLAW, true, "MAGNEMITE can learn METAL CLAW, being STEEL")
  T.eq(has.IRON_TAIL, true, "and IRON TAIL")
  T.eq(has.MOONBLAST, nil, "but not MOONBLAST, which is not its affinity")

  local clefairy = Data.pokemon.CLEFAIRY
  local fhas = {}
  for _, m in ipairs(clefairy.tmhm) do fhas[m] = true end
  T.eq(fhas.MOONBLAST, true, "CLEFAIRY can learn MOONBLAST, being FAIRY")
  T.eq(fhas.PLAY_ROUGH, true, "and PLAY ROUGH")

  -- the bag has to hold them
  T.eq(Bag.capacity(Data), 100, "the bag was widened to 100 slots")
end

-- ------- no pair may appear twice
--
-- A duplicate is invisible in normal play but wrong twice over: Damage walks
-- the ordered row list and would apply both, while TypeChart.effectiveness
-- keeps a last-write-wins index and would see only one -- so the damage and
-- the immunity check would disagree.

do
  local seen, dupes = {}, {}
  for _, row in ipairs(Data.type_chart.matchups) do
    local key = row.attacker .. ">" .. row.defender
    if seen[key] then dupes[#dupes + 1] = key end
    seen[key] = true
  end
  T.eq(#dupes, 0, "no chart cell is registered twice: " .. table.concat(dupes, " "))
end

-- ------- the giver NPCs
--
-- Only POWER_PLANT exists in this fixture; the other three log a warning and
-- place nothing, which is the guard doing its job on a partial dataset.

do
  local plant = Data.maps.POWER_PLANT
  T.eq(#plant.objects, 2, "the giver was appended, not substituted")
  T.eq(plant.objects[1].name, "FIX_RESIDENT", "the map kept its own NPC")

  local giver = plant.objects[2]
  T.eq(giver.name, "NEW_TYPES_IRON_TAIL", "and the second object is the giver")
  T.eq(giver.sprite, "SPRITE_SCIENTIST", "wearing the sprite it asked for")
  T.eq(giver.text, "TEXT_NEW_TYPES_IRON_TAIL", "keyed on its own text constant")
  T.eq(giver.x, 7, "at the x it was placed at")
  T.eq(giver.y, 34, "and the y")
  -- indices are the save key (mapId .. "_obj_" .. index), so a collision
  -- would make the giver share a "talked to" bit with a vanilla NPC
  T.check(giver.index ~= plant.objects[1].index, "with an index of its own")

  -- map_scripts has compose semantics: registrations accumulate into a
  -- per-map chain in Data.map_scripts rather than replacing each other, and
  -- that chain is what data/scripts/init.lua reads at boot.
  local ops
  for _, entry in ipairs(Data.map_scripts.POWER_PLANT or {}) do
    ops = ops or (entry.talk and entry.talk[giver.text])
  end
  T.check(type(ops) == "table",
          "talking to the giver resolves to a script")

  -- the gift is once-only: a flag check guards it and a set_flag closes it
  local sets, gives = 0, 0
  for _, op in ipairs(ops) do
    if op[1] == "set_flag" then sets = sets + 1 end
    if op[1] == "give_item" then
      gives = gives + 1
      T.eq(op[2], "TM_IRON_TAIL", "it hands over the right machine")
    end
  end
  T.eq(ops[1][1], "check_flag", "the branch opens by checking its flag")
  T.eq(sets, 1, "and sets it exactly once")
  T.eq(gives, 1, "handing the machine over exactly once")
end

run.release()
T.finish("new_types")
