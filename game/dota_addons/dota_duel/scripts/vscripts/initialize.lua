-- Initialization of the game

require('neutrals')


-- Initializes the custom neutrals system
function InitNeutrals()
  Timers:RemoveTimer("neutrals_timer")

  local spawn_neutrals = function()
    SpawnAllNeutrals()
    return 60.0
  end

  local args = {
    -- Neutral camps now spawn at the one minute mark like in the base game
    endTime = 60.0,
    callback = spawn_neutrals
  }

  Timers:CreateTimer("neutrals_timer", args)
end


-- Levels the entity to max level
function LevelEntityToMax(entity)
  if entity then
    entity:AddExperience(99000.0, 0, false, false)

    for i=0,30 do
      local ability = entity:GetAbilityByIndex(i)

      if ability then
        -- The return value of this function is undocumented, but secondary abilities like
        -- activate fire remnant and shadow step seem to always return 4 while no other
        -- ability does
        if ability:CanAbilityBeUpgraded() ~= 4 then
          -- Lua ranges are inclusive so this starts at 1 to compensate
          for i=1,ability:GetMaxLevel() - ability:GetLevel() do
            entity:UpgradeAbility(ability)
          end
        end
      end
    end
  end
end
