-- Utility functions


-- Constants
STRENGTH_MAGIC_RESISTANCE = 0.00
NEUTRAL_ITEM_SLOT = 16

neutral_items = {
  -- Tier 1
  ["item_arcane_ring"] = true,
  ["item_broom_handle"] = true,
  ["item_duelist_gloves"] = true,
  ["item_seeds_of_serenity"] = true,
  ["item_spark_of_courage"] = true,
  ["item_lance_of_pursuit"] = true,
  ["item_occult_bracelet"] = true,
  ["item_trusty_shovel"] = true,

  -- Tier 2
  ["item_grove_bow"] = true,
  ["item_dragon_scale"] = true,
  ["item_pupils_gift"] = true,
  ["item_philosophers_stone"] = true,
  ["item_bullwhip"] = true,
  ["item_dagger_of_ristul"] = true,
  ["item_quicksilver_amulet"] = true,
  ["item_specialists_array"] = true,
  ["item_eye_of_the_vizier"] = true,
  ["item_misericorde"] = true,
  ["item_vambrace"] = true,
  ["item_gossamer_cape"] = true,

  -- Tier 3
  ["item_paladin_sword"] = true,
  ["item_titan_sliver"] = true,
  ["item_mind_breaker"] = true,
  ["item_ceremonial_robe"] = true,
  ["item_cloak_of_flames"] = true,
  ["item_elven_tunic"] = true,
  ["item_psychic_headband"] = true,
  ["item_black_powder_bag"] = true,
  ["item_enchanted_quiver"] = true,
  ["item_ogre_seal_totem"] = true,

  -- Tier 4
  ["item_timeless_relic"] = true,
  ["item_spell_prism"] = true,
  ["item_flicker"] = true,
  ["item_ninja_gear"] = true,
  ["item_havoc_hammer"] = true,
  ["item_the_leveller"] = true,
  ["item_stormcrafter"] = true,
  ["item_trickster_cloak"] = true,
  ["item_penta_edged_sword"] = true,
  ["item_ascetic_cap"] = true,

  -- Tier 5
  ["item_force_boots"] = true,
  ["item_seer_stone"] = true,
  ["item_mirror_shield"] = true,
  ["item_fallen_sky"] = true,
  ["item_apex"] = true,
  ["item_ballista"] = true,
  ["item_pirate_hat"] = true,
  ["item_ex_machina"] = true,
  ["item_desolator_2"] = true,
  ["item_giants_ring"] = true,
  ["item_book_of_shadows"] = true,
}


-- Returns a table containing handles to all player entities
function GetPlayerEntities()
  local player_entities = {}
  local player_ids = {}

  local entity = Entities:First()

  for i, playerID in pairs(GetPlayerIDs()) do
    local entity = PlayerResource:GetSelectedHeroEntity(playerID)

    if entity then
      table.insert(player_entities, entity)
      player_ids[playerID] = true
    end
  end

  -- Also add these entities because the above code won't find them
  -- NOTE: This adds duplicates if more than one of any of these heroes are in the game, but that
  -- shouldn't cause any issues
  local entity_names = {
    "npc_dota_hero_meepo",
    "npc_dota_hero_arc_warden",
    "npc_dota_lone_druid_bear",
  }

  for i, name in pairs(entity_names) do
    for i, entity in pairs(Entities:FindAllByName(name)) do
      if not IsDummyHero(entity) then
        table.insert(player_entities, entity)
      end
    end
  end

  return player_entities
end


-- Returns a table containing all non-spectator player IDs
function GetPlayerIDs()
  local players = {}

  for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
    if PlayerResource:IsValidPlayerID(playerID) then
      local team = PlayerResource:GetTeam(playerID)
      if (team == DOTA_TEAM_GOODGUYS) or (team == DOTA_TEAM_BADGUYS) then
        table.insert(players, playerID)
      end
    end
  end

  return players
end


-- Teleports `entity` to the entity with the name `target_entity`
function TeleportEntity(entity, target_entity_name)
  local point = Entities:FindByName(nil, target_entity_name):GetAbsOrigin()

  FindClearSpaceForUnit(entity, point, false)
  entity:Stop()
end


-- Teleports `entity` to the entity named `radiant_target_name` if `entity` is on the radiant team, or
-- to the entity named `dire_target_name` otherwise
function TeleportEntityByTeam(entity, radiant_target_name, dire_target_name)
  local team = entity:GetTeam()

  if team == DOTA_TEAM_GOODGUYS then
    TeleportEntity(entity, radiant_target_name)
  end

  if team == DOTA_TEAM_BADGUYS then
    TeleportEntity(entity, dire_target_name)
  end
end


-- Returns the team that is the enemy of the provided one
-- Returns nil for teams other than DOTA_TEAM_GOODGUYS and DOTA_TEAM_BADGUYS
function GetOppositeTeam(team)
  if team == DOTA_TEAM_GOODGUYS then
    return DOTA_TEAM_BADGUYS
  elseif team == DOTA_TEAM_BADGUYS then
    return DOTA_TEAM_GOODGUYS
  end
end


-- Returns the player entity of a player that is on the opposite team of the provided one
function GetEnemyPlayer(team)
  local player_entities = GetPlayerEntities()

  for i, player_entity in pairs(player_entities) do
    if player_entity:GetTeam() ~= team then
      return player_entity
    end
  end
end


-- Returns whether a timer with the given name exists
function TimerExists(name)
  return Timers.timers[name] ~= nil
end


-- Returns whether the item with the provided name should have its cooldown reset
-- Returns false for items that cause bugs when their cooldowns get reset
function ShouldResetItemCooldown(item_name)
  local unsafe_items = {
    ["item_ward_observer"] = true,
    ["item_ward_sentry"] = true,
    ["item_ward_dispenser"] = true,
    ["item_smoke_of_deceit"] = true,
  }

  return not unsafe_items[item_name]
end


-- Returns whether the provided entity is a monkey king clone
function IsMonkeyKingClone(entity)
  return entity:HasModifier("modifier_monkey_king_fur_army_soldier_hidden")
    or   entity:HasModifier("modifier_monkey_king_fur_army_soldier")
    or   entity:HasModifier("modifier_monkey_king_fur_army_soldier_inactive")
    or   entity:HasModifier("modifier_monkey_king_fur_army_soldier_in_position")
end


-- Returns whether the match has ended
function IsMatchEnded()
  return (GameRules:State_Get() == DOTA_GAMERULES_STATE_POST_GAME) or (game_state == GAME_STATE_END)
end


-- Clears all players' inventories and stashes
function ClearInventories()
  for i, playerID in pairs(GetPlayerIDs()) do
    local player = PlayerResource:GetPlayer(playerID)
    local player_entity = player:GetAssignedHero()

    ClearInventory(player_entity)
  end
end


-- Clears the inventory and stash of the entity
function ClearInventory(entity)
  if entity and entity.GetItemInSlot then
    for i=0,20 do
      local item = entity:GetItemInSlot(i)

      if item then
        item:Destroy()
      end
    end
  end
end


-- Returns the inventories of every player
-- Returns a list of tables, each with the same format as those returned by GetInventoryOfEntity
function GetPlayerInventories()
  all_inventories = {}
  for i, playerID in pairs(GetPlayerIDs()) do
    local player_hero_handle = PlayerResource:GetSelectedHeroEntity(playerID)

    all_inventories[playerID] = GetInventoryOfEntity(player_hero_handle)
  end
  return all_inventories
end


-- Gets the inventory of the entity
-- Returns a table with items of the form [item_name, item_charges, item_secondary_charges]
-- The items are ordered by their index in the inventory
-- Ignores TP scrolls
function GetInventoryOfEntity(entity)
  local inventory = {}

  for i=0,20 do
    local item = entity:GetItemInSlot(i)

    if item then
      if not (item:GetAbilityName() == "item_tpscroll") then
        inventory[i] = {
          [1] = item:GetAbilityName(),
          [2] = item:GetCurrentCharges(),
          [3] = item:GetSecondaryCharges(),
        }
      end
    end
  end

  return inventory
end


-- Sets the entity's inventory state to the provided table and adds 3 TP scrolls
-- All created items are owned by item_owner
-- The table should be in the format returned by GetInventoryItems
-- Clears the entity's inventory before adding items
function SetupInventory(entity, item_owner, inventory)
  ClearInventory(entity)

  -- Add TP scrolls
  local tp_scroll = CreateAndConfigureItem("item_tpscroll", item_owner)
  tp_scroll:SetCurrentCharges(3)
  entity:AddItem(tp_scroll)

  -- Occupies the neutral item slot while other neutral items are added
  local dummy_neutral_item = entity:AddItemByName("item_apex")

  -- Add neutral items
  for i=20,0,-1 do
    if i ~= NEUTRAL_ITEM_SLOT then
      local item_info = inventory[i]

      if item_info and IsNeutralItem(item_info[1]) then
        local item = CreateAndConfigureItem(item_info[1], item_owner)

        entity:AddItem(item)
        -- Swap with first backpack slot (it's where neutral items go if the neutral slot is filled)
        entity:SwapItems(6, i)
      end
    end
  end

  -- Add the real item to the neutral item slot
  dummy_neutral_item:Destroy()

  local real_neutral_item = inventory[NEUTRAL_ITEM_SLOT]

  if real_neutral_item then
    local item = CreateAndConfigureItem(real_neutral_item[1], item_owner)
    entity:AddItem(item)
  end

  -- Add normal items
  for i = 20,0,-1 do
    local item = entity:GetItemInSlot(i)

    local item_info = inventory[i]

    -- Neutral items are handled separately
    if item_info and not IsNeutralItem(item_info[1]) then
      local item = CreateAndConfigureItem(item_info[1], item_owner)

      if item_info[2] then
        item:SetCurrentCharges(item_info[2])
      end

      if item_info[3] then
        item:SetSecondaryCharges(item_info[3])
      end

      entity:AddItem(item)
      entity:SwapItems(0, i)
    end
  end
end


-- Clears the inventory of the entity
function ClearInventory(entity)
  for i=0,20 do
    local item = entity:GetItemInSlot(i)

    if item then
      item:Destroy()
    end
  end
end


-- Returns the correct localization string for the name of the provided team
-- `winner` should be either DOTA_TEAM_GOODGUYS or DOTA_TEAM_BADGUYS
function GetLocalizationTeamName(team)
  if team == DOTA_TEAM_GOODGUYS then
    return "#DOTA_GoodGuys"
  elseif team == DOTA_TEAM_BADGUYS then
    return "#DOTA_BadGuys"
  end
end


-- Removes all old hero entities, such as those left behind when giving players new heroes
-- NOTE: Do not call this until all spark wraiths have been removed or they will get stuck
function RemoveOldHeroes()
  local hero_names = {}
  local hero_entities = {}

  for i, id in pairs(GetPlayerIDs()) do
    local hero = PlayerResource:GetSelectedHeroEntity(id)

    if hero then
      hero_names[hero:GetName()] = true
      hero_entities[hero] = true
    end
  end

  local old_heroes = {}
  local entity = Entities:First()
  while entity do
    if entity.IsHero and entity:IsHero() then
      if not IsDummyHero(entity) and not hero_entities[entity] then
        -- There doesn't seem to be a way to check whether clones belong to old heroes, so a
        -- time-based check is used here instead. This relies on SetPreviousRoundEndTime being
        -- called at the latest possible time before new heroes are created for players in order to
        -- catch all old heroes/clones. If SetPreviousRoundEndTime is called too early, some old
        -- heroes/clones will persist until the next time RemoveOldHeroes is called, but this
        -- shouldn't cause any issues.
        if entity:GetCreationTime() < PreviousRoundEndTime() then
          table.insert(old_heroes, entity)
        end
      end
    end

    entity = Entities:Next(entity)
  end

  -- Entities are removed in a separate loop to avoid iterator invalidation
  for i, old_hero in pairs(old_heroes) do
    UTIL_Remove(old_hero)
  end
end


-- Returns whether the player with the provided ID is a bot
function IsBot(id)
  return tostring(PlayerResource:GetSteamID(id)) == "0"
end


-- Sets the add bot button's enabled state to the provided value
function EnableAddBotButton(enabled)
  local data = {}
  data.enabled = enabled

  CustomGameEventManager:Send_ServerToAllClients("enable_add_bot_button", data)
end


-- Returns the multiplier for physical damage taken given an armor value
function GetPhysicalDamageMultiplier(armor_value)
  return 1 - ((0.052 * armor_value) / (0.9 + 0.048 * math.abs(armor_value)))
end


-- Returns whether the provided entity has any item in the table
-- Ignores backpack and stash
function HasAnyItem(entity, items)
  for i=0,5 do
    local item = entity:GetItemInSlot(i)

    if item and items[item:GetAbilityName()] then
      return true
    end
  end

  return false
end


-- Returns the dummy hero
function GetDummyHero()
  return Entities:FindByNameWithin(nil, DUMMY_HERO_NAME, DUMMY_HERO_POSITION, 250.0)
end


-- Returns whether the provided entity is the dummy hero
function IsDummyHero(entity)
  return entity:GetName() == DUMMY_HERO_NAME
    and (entity:GetAbsOrigin() - DUMMY_HERO_POSITION):Length2D() < 250.0
end


-- Returns whether the provided entity is taunted
function IsTaunted(entity)
  local taunt_modifiers = {
    ["modifier_axe_berserkers_call"] = true,
    ["modifier_troll_warlord_battle_trance"] = true,
    ["modifier_winter_wyvern_winters_curse"] = true,
    ["modifier_huskar_life_break_taunt"] = true,
    ["modifier_aether_remnant_pull"] = true,
  }

  for i,modifier in pairs(entity:FindAllModifiers()) do
    local modifier_name = modifier:GetName()

    if taunt_modifiers[modifier_name] then
      return true
    end
  end

  return false
end


-- Returns whether the provided entity is feared
function IsFeared(entity)
  local fear_modifiers = {
    ["modifier_dark_willow_debuff_fear"] = true,
    ["modifier_lone_druid_savage_roar"] = true,
    ["modifier_queenofpain_scream_of_pain_fear"] = true,
    ["modifier_terrorblade_fear"] = true,
    ["modifier_nevermore_requiem_fear"] = true,
    ["modifier_vengeful_spirit_wave_of_terror_fear"] = true,
  }

  for i,modifier in pairs(entity:FindAllModifiers()) do
    local modifier_name = modifier:GetName()

    if fear_modifiers[modifier_name] then
      return true
    end
  end

  return false
end


-- Returns whether the provided entity is a clone
function IsClone(entity)
  local player_id = entity:GetPlayerOwnerID()

  if player_id then
    local player_hero = PlayerResource:GetSelectedHeroEntity(player_id)

    if not player_hero then
      return false
    end

    return (entity:GetName() == player_hero:GetName()) and (entity ~= player_hero) and not entity:IsIllusion()
  else
    return false
  end
end


-- Returns whether the 1v1 map is being played
function IsOneVsOneMap()
  return GameRules:GetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS) == 1
end


-- Returns whether a bot can be added (only on 1v1 map and if playing solo)
function CanAddBot()
  local total_players = 0
  total_players = total_players + PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS)
  total_players = total_players + PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_BADGUYS)

  -- FIXME: Disabled until bots are rewritten due to them being hardcoded for the old map
  return false and IsOneVsOneMap() and (total_players == 1) and not IsMatchEnded()
end


-- Returns whether the item is a neutral item
function IsNeutralItem(item_name)
  return neutral_items[item_name] ~= nil
end


-- Calls `fn` with all items in the player's inventory and their bear's inventory
-- fn should be of type function(entity, item)
function MapInventoryItems(player_id, fn)
  local hero = PlayerResource:GetSelectedHeroEntity(player_id)

  for i=0,20 do
    local item = hero:GetItemInSlot(i)

    if item then
      fn(hero, item)
    end
  end

  for j, entity in pairs(Entities:FindAllByName("npc_dota_lone_druid_bear")) do
    if entity:GetOwnerEntity() == hero then
      for i=0,20 do
        local item = entity:GetItemInSlot(i)

        if item then
          fn(entity, item)
        end
      end
    end
  end
end


-- Returns whether the entity has consumed a scepter shard
function HasScepterShard(entity)
  return entity:HasModifier("modifier_item_aghanims_shard")
end


-- Sets the music status for all players
function SetMusicStatus(status, intensity)
  for i, player_id in pairs(GetPlayerIDs()) do
    local player = PlayerResource:GetPlayer(player_id)
    -- NOTE: Currently disabled because it is buggy
    -- player:SetMusicStatus(status, intensity)
  end
end


-- Sends a message to all client consoles
function SendServerMessage(text)
  local data = {}
  data.text = text
  CustomGameEventManager:Send_ServerToAllClients("server_message", data)
end


-- Creates and returns an item owned by `owner`, setting its purchaser and disabling it as
-- necessary
-- This should always be used over CreateItem
function CreateAndConfigureItem(name, owner)
  local item = CreateItem(name, owner, owner)

  -- Make the item sellable (important for neutral items)
  item:SetPurchaser(owner)

  -- Disable seer stone to prevent abuse (will be re-enabled at round start)
  if item:GetAbilityName() == "item_seer_stone" then
    item:SetActivated(false)
  end

  return item
end


-- Kills the provided NPC, bypassing shallow grave and similar effects
-- Does not prevent reincarnation
function KillNPC(entity)
  ClearBuffs(entity)
  entity:Kill(nil, activator)
end