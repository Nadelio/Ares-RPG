local Registry = require("core.registry")

local TableUtils = require("core.utils.table_utils")

local Item = require("core.components.item")
local Stats = require("core.components.stats")
local StatSystem = require("core.systems.stats")

local ClassSystem = {}

local LEVELABLE_STATS = {
	health = true,
	movement = true,
	attack = true,
	defense = true,
	luck = true,
}

local function is_integer(value)
	return type(value) == "number" and value % 1 == 0
end

local function title_case(text)
	local words = {}

	for part in tostring(text):gmatch("[^_]+") do
		table.insert(words, part:sub(1, 1):upper() .. part:sub(2):lower())
	end

	return table.concat(words, " ")
end

local function normalize_class_id(class_id)
	local normalized = (class_id or "human"):lower()
	normalized = normalized:gsub("[^%w]+", "_")
	normalized = normalized:gsub("^_+", "")
	normalized = normalized:gsub("_+$", "")

	return normalized
end

local function reset_base_stats(stats)
	for _, definition in ipairs(Stats.definitions) do
		StatSystem.setBase(stats, definition.key, 0)
	end
end

local function adjust_tracked_current(entity, stat, amount)
	if stat ~= "health" and stat ~= "movement" then
		return
	end

	local maximum = StatSystem.get(entity.stats, stat)
	local current = entity.stats.current[stat] or 0

	entity.stats.current[stat] = math.min(maximum, math.max(0, current + amount))
end

local function apply_base_changes(entity, deltas)
	for stat, amount in pairs(deltas or {}) do
		StatSystem.modifyBase(entity.stats, stat, amount)
		adjust_tracked_current(entity, stat, amount)
	end
end

local function find_ability(entries, ability_id)
	for _, ability in ipairs(entries or {}) do
		if ability.id == ability_id then
			return ability
		end
	end

	return nil
end

local function collect_available(entries, learned, level)
	local available = {}

	for _, ability in ipairs(entries or {}) do
		if ability.level <= level and not learned[ability.id] then
			table.insert(available, TableUtils.clone(ability))
		end
	end

	return available
end

local function count_mastery_unlocks(previous_level, new_level)
	return math.max(0, math.floor(new_level / 5) - math.floor(previous_level / 5))
end

ClassSystem.definitions = {
	human = {
		name = "Human",
		base_stats = {
			health = 10,
			movement = 3,
			luck = 2,
			defense = 1,
			attack = 3,
			capacity = 1,
		},
		level_up_stats = { "health", "movement", "luck", "defense", "attack" },
		favored_enemy_tags = { "beast" },
		disfavored_enemy_tags = {},
		starter_items = {
			{
				name = "Rusty Sword",
				description = "A dependable blade for a new wanderer.",
				rarity = "common",
				bonuses = { attack = 2 },
			},
			{
				name = "Traveler's Coat",
				description = "Light armor meant for long roads.",
				rarity = "common",
				bonuses = { defense = 1 },
			},
		},
		skills = {
			{ id = "adapt", name = "Adapt", level = 2, description = "Gain a flexible edge when plans go bad." },
			{ id = "scrapper", name = "Scrapper", level = 4, description = "Turn improvised weapons into real threats." },
		},
		spells = {},
		mastery_skills = {
			{ id = "veteran", name = "Veteran", level = 5, bonuses = { health = 2 }, cost = { movement = -1 }, description = "Trade speed for staying power." },
		},
	},
	boxer = {
		name = "Boxer",
		base_stats = {
			health = 9,
			movement = 3,
			luck = 2,
			defense = 3,
			attack = 5,
			capacity = 1,
		},
		level_up_stats = { "attack", "health", "defense", "movement" },
		favored_enemy_tags = { "brute", "humanoid" },
		disfavored_enemy_tags = { "specter" },
		starter_items = {
			{
				name = "Weighted Wraps",
				description = "Cloth wraps packed with enough heft to sting.",
				rarity = "common",
				bonuses = { attack = 2 },
			},
			{
				name = "Mouthguard",
				description = "A battered guard that helps you keep your footing.",
				rarity = "common",
				bonuses = { defense = 1 },
			},
		},
		skills = {
			{ id = "counter_hook", name = "Counter Hook", level = 2, description = "Punish enemies that close the distance." },
			{ id = "backblast", name = "Backblast", level = 4, description = "Absorb pressure before swinging back harder." },
		},
		spells = {},
		mastery_skills = {
			{ id = "iron_jaw", name = "Iron Jaw", level = 5, bonuses = { defense = 2 }, cost = { luck = -1 }, description = "Commit harder to the brawl." },
		},
	},
	gambler = {
		name = "Gambler",
		base_stats = {
			health = 8,
			movement = 3,
			luck = 5,
			defense = 1,
			attack = 1,
			capacity = 1,
		},
		level_up_stats = { "luck", "movement", "attack", "health" },
		favored_enemy_tags = { "construct", "machine" },
		disfavored_enemy_tags = { "brute" },
		starter_items = {
			{
				name = "Loaded Dice",
				description = "Weighted just enough to offend a fair table.",
				rarity = "rare",
				bonuses = { luck = 2 },
			},
			{
				name = "Cardsharp Vest",
				description = "More pockets than protection, but still some protection.",
				rarity = "common",
				bonuses = { defense = 1 },
			},
		},
		skills = {
			{ id = "stacked_deck", name = "Stacked Deck", level = 2, description = "Turn a risky interaction into a favorable one." },
			{ id = "double_or_nothing", name = "Double or Nothing", level = 4, description = "Commit to huge swings when the odds look right." },
		},
		spells = {
			{ id = "house_edge", name = "House Edge", level = 3, description = "Tilt a contest ever so slightly in your favor." },
		},
		mastery_skills = {
			{ id = "lady_luck", name = "Lady Luck", level = 5, bonuses = { luck = 2 }, cost = { health = -1 }, description = "Win more often, but pay for it when you fail." },
		},
	},
	doctor = {
		name = "Doctor",
		base_stats = {
			health = 9,
			movement = 3,
			luck = 2,
			defense = 1,
			attack = 3,
			capacity = 1,
		},
		level_up_stats = { "health", "luck", "defense", "attack" },
		favored_enemy_tags = { "undead", "plague" },
		disfavored_enemy_tags = { "automaton" },
		starter_items = {
			{
				name = "Bone Saw",
				description = "Sharp enough for surgery and emergencies alike.",
				rarity = "common",
				bonuses = { attack = 1 },
			},
			{
				name = "Field Coat",
				description = "A stitched coat with room for bandages and blame.",
				rarity = "common",
				bonuses = { defense = 1, health = 1 },
			},
		},
		skills = {
			{ id = "triage", name = "Triage", level = 2, description = "Stabilize wounded allies under pressure." },
			{ id = "steady_hands", name = "Steady Hands", level = 4, description = "Keep utility items effective in chaotic fights." },
		},
		spells = {
			{ id = "first_aid", name = "First Aid", level = 3, description = "Patch injuries without a full rest." },
		},
		mastery_skills = {
			{ id = "battlefield_surgeon", name = "Battlefield Surgeon", level = 5, bonuses = { health = 2 }, cost = { attack = -1 }, description = "Commit to keeping the party alive first." },
		},
	},
	runner = {
		name = "Runner",
		base_stats = {
			health = 8,
			movement = 7,
			luck = 2,
			defense = 1,
			attack = 3,
			capacity = 1,
		},
		level_up_stats = { "movement", "luck", "health", "attack" },
		favored_enemy_tags = { "beast", "sniper" },
		disfavored_enemy_tags = { "netter" },
		starter_items = {
			{
				name = "Sprint Shoes",
				description = "Light shoes built for reckless route changes.",
				rarity = "rare",
				bonuses = { movement = 1 },
			},
			{
				name = "Windbreaker",
				description = "Thin armor for someone who plans on never getting hit twice.",
				rarity = "common",
				bonuses = { defense = 1 },
			},
		},
		skills = {
			{ id = "dash_step", name = "Dash Step", level = 2, description = "Exploit narrow openings in movement-heavy turns." },
			{ id = "line_break", name = "Line Break", level = 4, description = "Push through control effects by sheer momentum." },
		},
		spells = {},
		mastery_skills = {
			{ id = "afterimage", name = "Afterimage", level = 5, bonuses = { movement = 2 }, cost = { defense = -1 }, description = "Trade protection for unmatched speed." },
		},
	}
}

ClassSystem.aliases = {
	human = "human",
	boxer = "boxer",
	gambler = "gambler",
	doctor = "doctor",
	runner = "runner"
}

function ClassSystem.get_definition(class_id)
	local normalized = normalize_class_id(class_id)
	local resolved = ClassSystem.aliases[normalized] or normalized

	return ClassSystem.definitions[resolved], resolved
end

function ClassSystem.refresh_progression(entity)
	local state = entity.class_state

	if not state then
		return nil
	end

	local definition = state.definition
	local level = entity.level or 1

	state.available_level_up_stats = TableUtils.clone(definition.level_up_stats or {})
	state.available_skills = collect_available(definition.skills, state.learned.skills, level)
	state.available_spells = collect_available(definition.spells, state.learned.spells, level)
	state.available_mastery_skills = collect_available(definition.mastery_skills, state.learned.masteries, level)

	return state
end

function ClassSystem.assign(entity, class_id, Events)
	assert(entity and entity.stats, "Cannot assign a class to an entity without stats")

	local definition, resolved_id = ClassSystem.get_definition(class_id or entity.class_id or entity.stats.class)
	assert(definition, ("Unknown class '%s'"):format(class_id or entity.class_id or entity.stats.class or "nil"))

	reset_base_stats(entity.stats)

	for stat, value in pairs(definition.base_stats or {}) do
		StatSystem.setBase(entity.stats, stat, value)
	end

	entity.stats.class = definition.name
	entity.class_id = resolved_id
	entity.level = entity.level or entity.stats.base.level or 1
	entity.stats.base.level = entity.level
	entity.stats.current.health = StatSystem.get(entity.stats, "health")
	entity.stats.current.movement = StatSystem.get(entity.stats, "movement")
	entity.stats.current.capacity = entity.stats.current.capacity or 0
	entity.dead = false

	entity.class_state = {
		id = resolved_id,
		name = definition.name,
		definition = definition,
		learned = {
			skills = {},
			spells = {},
			masteries = {},
		},
		learned_order = {
			skills = {},
			spells = {},
			masteries = {},
		},
		pending_stat_choices = 0,
		pending_skill_choices = 0,
		pending_mastery_choices = 0,
		favored_enemy_tags = TableUtils.clone(definition.favored_enemy_tags or {}),
		disfavored_enemy_tags = TableUtils.clone(definition.disfavored_enemy_tags or {}),
	}

	ClassSystem.refresh_progression(entity)

	if Events then
		for _, starter in ipairs(definition.starter_items or {}) do
			local item = Item.new(TableUtils.clone(starter))
			item.class_starter = true
			item.class_owner = resolved_id

			Events.emit("inventory_add", {
				entity = entity,
				item = item,
			})
		end
	end

	return entity.class_state
end

function ClassSystem.get_level_up_options(entity)
	local state = ClassSystem.refresh_progression(entity)

	if not state then
		return nil
	end

	return {
		stats = TableUtils.clone(state.available_level_up_stats),
		skills = TableUtils.clone(state.available_skills),
		spells = TableUtils.clone(state.available_spells),
		mastery_skills = TableUtils.clone(state.available_mastery_skills),
		pending_stat_choices = state.pending_stat_choices,
		pending_skill_choices = state.pending_skill_choices,
		pending_mastery_choices = state.pending_mastery_choices,
	}
end

function ClassSystem.get_level_up_choices(entity)
	local options = ClassSystem.get_level_up_options(entity)

	if not options then
		return nil
	end

	local tabs = {}

	if options.pending_stat_choices > 0 or #options.stats > 0 then
		local entries = {}

		for _, stat in ipairs(options.stats) do
			local definition = Stats.get_definition(stat)

			table.insert(entries, {
				id = stat,
				kind = "stat",
				event = "class_choose_stat",
				label = definition and definition.label or title_case(stat),
				description = "Increase this stat by 1.",
			})
		end

		table.insert(tabs, {
			id = "stats",
			label = "Stats",
			pending = options.pending_stat_choices,
			entries = entries,
		})
	end

	if #options.skills > 0 or #options.spells > 0 then
		local entries = {}

		for _, ability in ipairs(options.skills) do
			local choice = TableUtils.clone(ability)
			choice.kind = "skill"
			choice.event = "class_learn_skill"
			choice.label = choice.name
			table.insert(entries, choice)
		end

		for _, ability in ipairs(options.spells) do
			local choice = TableUtils.clone(ability)
			choice.kind = "spell"
			choice.event = "class_learn_spell"
			choice.label = choice.name
			table.insert(entries, choice)
		end

		table.insert(tabs, {
			id = "skills",
			label = "Skills",
			pending = options.pending_skill_choices,
			entries = entries,
		})
	end

	if #options.mastery_skills > 0 then
		local entries = {}

		for _, ability in ipairs(options.mastery_skills) do
			local choice = TableUtils.clone(ability)
			choice.kind = "mastery"
			choice.event = "class_learn_mastery"
			choice.label = choice.name
			table.insert(entries, choice)
		end

		table.insert(tabs, {
			id = "masteries",
			label = "Mastery",
			pending = options.pending_mastery_choices,
			entries = entries,
		})
	end

	return tabs
end

function ClassSystem.has_advantage(entity, enemy_tag)
	local state = entity and entity.class_state

	if not state or not enemy_tag then
		return false
	end

	return TableUtils.contains(state.favored_enemy_tags, enemy_tag)
end

function ClassSystem.has_disadvantage(entity, enemy_tag)
	local state = entity and entity.class_state

	if not state or not enemy_tag then
		return false
	end

	return TableUtils.contains(state.disfavored_enemy_tags, enemy_tag)
end

function ClassSystem.init(Events, world, map, logger)
	Events.on("class_assign", function(e)
		e.state = ClassSystem.assign(e.entity, e.class, Events)
	end, 100)

	Events.on("class_choose_stat", function(e)
		local entity = e.entity
		local state = entity and entity.class_state
		local stat = e.stat
		local amount = e.amount or 1

		if not entity or not state then
			e.cancelled = true
			return
		end

		if not is_integer(amount) or amount <= 0 then
			error("Class stat choices must spend a positive integer amount")
		end

		if state.pending_stat_choices < amount then
			e.cancelled = true
			return
		end

		if not LEVELABLE_STATS[stat] or not TableUtils.contains(state.available_level_up_stats, stat) then
			e.cancelled = true
			return
		end

		apply_base_changes(entity, {
			[stat] = amount,
		})

		state.pending_stat_choices = state.pending_stat_choices - amount
		ClassSystem.refresh_progression(entity)
	end, 100)

	local function learn_ability(entity, ability_id, source_key, learned_key, pending_key)
		local state = entity and entity.class_state

		if not state then
			return false
		end

		local ability = find_ability(state.definition[source_key], ability_id)

		if not ability or state.learned[learned_key][ability.id] then
			return false
		end

		if (entity.level or 1) < ability.level then
			return false
		end

		if pending_key and state[pending_key] <= 0 then
			return false
		end

		state.learned[learned_key][ability.id] = true
		TableUtils.append_unique(state.learned_order[learned_key], ability.id)

		apply_base_changes(entity, ability.cost)
		apply_base_changes(entity, ability.bonuses)

		if pending_key then
			state[pending_key] = state[pending_key] - 1
		end

		ClassSystem.refresh_progression(entity)

		return true, ability
	end

	Events.on("class_learn_skill", function(e)
		local learned, ability = learn_ability(e.entity, e.skill, "skills", "skills", "pending_skill_choices")

		if not learned then
			e.cancelled = true
			return
		end

		e.ability = ability
	end, 100)

	Events.on("class_learn_spell", function(e)
		local learned, ability = learn_ability(e.entity, e.spell, "spells", "spells", "pending_skill_choices")

		if not learned then
			e.cancelled = true
			return
		end

		e.ability = ability
	end, 100)

	Events.on("class_learn_mastery", function(e)
		local learned, ability = learn_ability(e.entity, e.mastery, "mastery_skills", "masteries", "pending_mastery_choices")

		if not learned then
			e.cancelled = true
			return
		end

		e.ability = ability
	end, 100)

	Events.on("level_up", function(e)
		local entity = e.entity
		local state = entity and entity.class_state
		local levels = e.amount or 1

		if not entity or not state then
			return
		end

		entity.stats.base.level = entity.level or entity.stats.base.level

		local previous_level = math.max(0, (entity.level or 1) - levels)

		state.pending_stat_choices = state.pending_stat_choices + levels
		state.pending_skill_choices = state.pending_skill_choices + levels
		state.pending_mastery_choices = state.pending_mastery_choices + count_mastery_unlocks(previous_level, entity.level or previous_level)

		ClassSystem.refresh_progression(entity)
	end, 90)

	for _, entity in ipairs(world:get_all()) do
		local class_id = entity.class_id

		if not class_id and entity.stats and entity.stats.class and entity.stats.class ~= "None" then
			class_id = entity.stats.class
		end

		if class_id and entity.stats and not entity.class_state then
			ClassSystem.assign(entity, class_id, Events)
		end
	end
end

Registry.register("systems", "class", ClassSystem)

return ClassSystem