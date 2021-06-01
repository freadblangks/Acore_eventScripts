--
--
-- Created by IntelliJ IDEA.
-- User: Silvia
-- Date: 17/05/2021
-- Time: 19:50
-- To change this template use File | Settings | File Templates.
-- Originally created by Honey for Azerothcore
-- requires ElunaLua module


-- This module spawns (custom) NPCs and grants them scripted combat abilities
------------------------------------------------------------------------------------------------
-- ADMIN GUIDE:  -  compile the core with ElunaLua module
--               -  adjust config in this file
--               -  add this script to ../lua_scripts/
--               -  adjust the IDs and config flags in case of conflicts and run the associated SQL to add the required NPCs
------------------------------------------------------------------------------------------------
-- GM GUIDE:     -  use .startevent $event $difficulty to start and spawn 
--               -  maybe offer teleports               '
------------------------------------------------------------------------------------------------
local Config = {}                   --general config flags
local Config_npcEntry = {}          --db entry of the NPC creature to summon the boss
local Config_npcText = {}           --gossip in npc_text to be told by the summoning NPC
local Config_bossEntry = {}         --db entry of the boss creature
local Config_addEntry = {}          --db entry of the add creature

-- Name of Eluna dB scheme
Config.customDbName = "ac_eluna"
-- Min GM rank to start an event
Config.GMRankForEventStart = 2
-- Min GM rank to add NPCs to the db
Config.GMRankForUpdateDB = 3
-- set to 1 to print error messages to the console. Any other value including nil turns it off.
Config.printErrorsToConsole = 1

-- Database NPC entries. Must match the associated .sql file
Config_bossEntry[1] = 1112001
Config_npcEntry[1] = 1112002
Config_addEntry[1] = 1112003
Config_npcText[1] = 91111


------------------------------------------
-- NO ADJUSTMENTS REQUIRED BELOW THIS LINE
------------------------------------------

--constants
local PLAYER_EVENT_ON_LOGOUT = 4            -- (event, player)
local PLAYER_EVENT_ON_REPOP = 35            -- (event, player)
local PLAYER_EVENT_ON_COMMAND = 42          -- (event, player, command) - player is nil if command used from console. Can return false
local TEMPSUMMON_MANUAL_DESPAWN = 8         -- despawns when UnSummon() is called
local GOSSIP_EVENT_ON_HELLO = 1             -- (event, player, object) - Object is the Creature/GameObject/Item. Can return false to do default action. For item gossip can return false to stop spell casting.
local GOSSIP_EVENT_ON_SELECT = 2            -- (event, player, object, sender, intid, code, menu_id)
local OPTION_ICON_CHAT = 0
local OPTION_ICON_BATTLE = 9

local SELECT_TARGET_RANDOM = 0              -- Just selects a random target
local SELECT_TARGET_TOPAGGRO = 1            -- Selects targets from top aggro to bottom
local SELECT_TARGET_BOTTOMAGGRO = 2         -- Selects targets from bottom aggro to top
local SELECT_TARGET_NEAREST = 3
local SELECT_TARGET_FARTHEST = 4

--local variables
local cancelGossipEvent
local eventInProgress
local bossfightInProgress
local difficulty                            -- difficulty is set when using .startevent and it is meant for a range of 1-5
local addsDownCounter
local phase
local x
local y
local z
local o
local spawnedBossGuid
local spawnedCreature1Guid
local spawnedCreature2Guid
local spawnedCreature3Guid
local spawnedNPC

--local arrays
local cancelEventIdHello = {}
local cancelEventIdStart = {}
local addNPC = {}
local bossNPC = {}
local playersInRaid = {}
local groupPlayers = {}

local function eS_command(event, player, command)
    local commandArray = {}
    local eventNPC

    --prevent players from using this  
    if player ~= nil then  
        if player:GetGMRank() < Config.GMRankForEventStart then
            return
        end  
    end
  
    -- split the command variable into several strings which can be compared individually
    commandArray = eS_splitString(command)

    if commandArray[2] ~= nil then
        commandArray[2] = commandArray[2]:gsub("[';\\, ]", "")
        if commandArray[3] ~= nil then
            commandArray[3] = commandArray[3]:gsub("[';\\, ]", "")
        end
    end
  
    if commandArray[2] == nil then commandArray[2] = 1 end
    if commandArray[3] == nil then commandArray[3] = 1 end
  
    if commandArray[1] == "startevent" then
        eventNPC = tonumber(commandArray[2])
        difficulty = tonumber(commandArray[3])

        if difficulty <= 0 then difficulty = 1 end

        if eventInProgress == nil then
            eventInProgress = eventNPC
            eS_summonEventNPC(player:GetGUID())
            player:SendBroadcastMessage("Starting event "..eventInProgress..".")
            return false
        else
            player:SendBroadcastMessage("Event "..eventInProgress.." is already active.")
            return false
        end
    elseif commandArray[1] == "stopevent" then
        if eventInProgress == nil then
            player:SendBroadcastMessage("There is no event in progress.")
            return false
        end
        player:SendBroadcastMessage("Stopping event "..eventInProgress..".")
        ClearCreatureGossipEvents(Config_npcEntry[eventInProgress])
        --todo: find a way to unsummon Chromie
        eventInProgress = nil
    end
    
    --prevent non-Admins from using the rest
    if player ~= nil then  
        if player:GetGMRank() < Config.GMRankForUpdateDB then
            return
        end  
    end
    
end
    
function eS_summonEventNPC(playerGuid)
    local player
    -- tempSummon an NPC with a dialouge option to start the encounter, store the guid for later unsummon
    player = GetPlayerByGUID(playerGuid)
    x = player:GetX()
    y = player:GetY()
    z = player:GetZ()
    o = player:GetO()
    spawnedNPC = player:SpawnCreature(Config_npcEntry[eventInProgress], x, y, z, o)

    --print("summonEventNPC")

    -- add an event to spawn the Boss in a phase when gossip is clicked
    cancelEventIdHello[eventInProgress] = RegisterCreatureGossipEvent(Config_npcEntry[eventInProgress], GOSSIP_EVENT_ON_HELLO, eS_onHello)
    cancelEventIdStart[eventInProgress] = RegisterCreatureGossipEvent(Config_npcEntry[eventInProgress], GOSSIP_EVENT_ON_SELECT, eS_spawnBoss)
end

function eS_onHello(event, player, creature)
    --print("event: "..event)
    if bossfightInProgress ~= nil then return end

    player:GossipMenuAddItem(OPTION_ICON_CHAT, "We are ready to fight a servant!", Config_npcEntry[eventInProgress], 0)
    player:GossipMenuAddItem(OPTION_ICON_CHAT, "We brought the best there is and we're ready for anything.", Config_npcEntry[eventInProgress], 1)
    player:GossipSendMenu(Config_npcText[1], creature,0)
end

function eS_spawnBoss(event, player, object, sender, intid, code, menu_id)
    --print("event: "..event)
    --print("intid: "..intid)
    --print("sender: "..sender)
    --print("spawnBoss")

    local spawnedBoss
    local spawnedCreature
    local spawnedCreature1
    local spawnedCreature2
    local spawnedCreature3

    if player:IsInGroup() == false then
        player:SendBroadcastMessage("You need to be in a party.")
        player:GossipComplete()
        return
    end

    local group = player:GetGroup()

    if intid == 0 then
        if group:IsRaidGroup() == true then
            player:SendBroadcastMessage("You can not accept that task while in a raid group.")
            player:GossipComplete()
            return
        end
        --start 5man encounter
        bossfightInProgress = 1
        spawnedCreature = player:SpawnCreature(Config_addEntry[eventInProgress], x, y, z, o)
        spawnedCreature:SetPhaseMask(2)
        spawnedCreature:SetScale(eS_getSize(difficulty))

        groupPlayers = group:GetMembers()
        --todo: add a range check
        for n, v in pairs(groupPlayers) do
            v:SetPhaseMask(2)
            playersInRaid[n] = v:GetGUID()
            spawnedCreature:SetInCombatWith(v)
            v:SetInCombatWith(spawnedCreature)
            spawnedCreature:AddThreat(v, 1)
        end

    elseif intid == 1 then
        if group:IsRaidGroup() == false then
            player:SendBroadcastMessage("You can not accept that task without being in a raid group.")
            player:GossipComplete()
            return
        end
        --start raid encounter
        bossfightInProgress = 2

        spawnedBoss = player:SpawnCreature(Config_bossEntry[eventInProgress], x, y, z+2, o)
        spawnedCreature1 = player:SpawnCreature(Config_addEntry[eventInProgress], x-10, y, z+2, o)
        spawnedCreature2 = player:SpawnCreature(Config_addEntry[eventInProgress], x, y-10, z+2, o)
        spawnedCreature3 = player:SpawnCreature(Config_addEntry[eventInProgress], x, y+10, z+2, o)
        spawnedBoss:SetPhaseMask(2)
        spawnedCreature1:SetPhaseMask(2)
        spawnedCreature2:SetPhaseMask(2)
        spawnedCreature3:SetPhaseMask(2)
        spawnedBoss:SetScale(eS_getSize(difficulty))
        spawnedCreature1:SetScale(eS_getSize(difficulty))
        spawnedCreature2:SetScale(eS_getSize(difficulty))
        spawnedCreature3:SetScale(eS_getSize(difficulty))

        groupPlayers = group:GetMembers()
        --todo: add a range check
        for n, v in pairs(groupPlayers) do
            v:SetPhaseMask(2)
            playersInRaid[n] = v:GetGUID()
            spawnedBoss:SetInCombatWith(v)
            spawnedCreature1:SetInCombatWith(v)
            spawnedCreature2:SetInCombatWith(v)
            spawnedCreature3:SetInCombatWith(v)
            v:SetInCombatWith(spawnedBoss)
            v:SetInCombatWith(spawnedCreature1)
            v:SetInCombatWith(spawnedCreature2)
            v:SetInCombatWith(spawnedCreature3)
            spawnedBoss:AddThreat(v, 1)
            spawnedCreature1:AddThreat(v, 1)
            spawnedCreature2:AddThreat(v, 1)
            spawnedCreature3:AddThreat(v, 1)
        end

        spawnedBossGuid = spawnedBoss:GetGUID()
        spawnedCreature1Guid = spawnedCreature1:GetGUID()
        spawnedCreature2Guid = spawnedCreature2:GetGUID()
        spawnedCreature3Guid = spawnedCreature3:GetGUID()
    end
    player:GossipComplete()
end

-- list of spells:
-- 60488 Shadow Bolt (30)
-- 24326 HIGH knockback (ZulFarrak beast)
-- 12421 Mithril Frag Bomb 8y 149-201 damage + stun

-- 38846 Forceful Cleave (Target + nearest ally)
-- 25840 Full heal
-- 53721 Death and decay

-- 45108 CKs Fireball

function bossNPC.onEnterCombat(event, creature, target)
    local timer1 = 19000
    local timer2 = 20000
    local timer3 = 11000
    local player

    timer1 = timer1 / (1 + ((difficulty - 1) / 5))
    timer2 = timer2 / (1 + ((difficulty - 1) / 5))
    timer3 = timer3 / (1 + ((difficulty - 1) / 5))

    creature:RegisterEvent(bossNPC.Cleave, timer1, 0)
    creature:RegisterEvent(bossNPC.AoE, timer2, 0)
    creature:RegisterEvent(bossNPC.HealOrBoom, timer3, 0)
    creature:CallAssistance()
    creature:SendUnitYell("You will NOT interrupt this mission!", 0 )
    phase = 1
    addsDownCounter = 0
    creature:CallForHelp(200)

end

function bossNPC.reset(event, creature)
    --print("bossNPC.reset")
    local player
    creature:RemoveEvents()
    bossfightInProgress = nil
    addsDownCounter = nil
    if creature:IsDead() == true then
        creature:SendUnitYell("This... was not... the last time...", 0 )
        local playerListString
        for _, v in pairs(playersInRaid) do
            player = GetPlayerByGUID(v)
            player:SetPhaseMask(1)
            if playerListString == nil then
                playerListString = player:GetName()
            else
                playerListString = playerListString..", "..player:GetName()
            end
        end
        SendWorldMessage("The raid encounter Glorifrir Flintshoulder was completed on difficulty "..difficulty.." by: "..playerListString.." Congratulations!")
        CreateLuaEvent(eS_castFireworks, 1000, 20)
    else
        creature:SendUnitYell("You never had a chance.", 0 )
        for _, v in pairs(playersInRaid) do
            player = GetPlayerByGUID(v)
            player:SetPhaseMask(1)
        end
    end
    creature:DespawnOrUnsummon(0)
end

function bossNPC.Cleave(event, delay, pCall, creature)
    creature:CallForHelp(100)
    creature:CastSpell(creature:GetVictim(), 38846)
    eS_checkInCombat()
end

function bossNPC.AoE(event, delay, pCall, creature)
    --AoE spell on a random player
    local players = creature:GetPlayersInRange(30)
    if #players > 1 then
        creature:CastSpell(creature:GetAITarget(SELECT_TARGET_NEAREST, true, 2, 30), 53721)
    else
        creature:CastSpell(creature:GetVictim(),53721)
    end
end

function bossNPC.HealOrBoom(event, delay, pCall, creature)          -- also handles yells/phases
    local targetPlayer
    --heal self if adds alive, else random singletarget
    if addsDownCounter < 3 then
        creature:CastSpell(creature, 69898)
        return
    elseif phase == 1 then
        --Phase2
        creature:SendUnitYell("You might have handled these creatures. But now I WILL handle YOU!", 0 )
        phase = 2
    elseif phase == 2 and creature:GetHealthPct() < 10 then
        creature:SendUnitYell("FEEL MY WRATH!", 0 )
        phase = 3
        creature:CastSpell(creature, 69166)
    else
        if (math.random(1, 100) <= 25) then
            local players = creature:GetPlayersInRange()
            targetPlayer = players[math.random(1, #players)]
            creature:SendUnitYell("You die now, "..targetPlayer:GetName().."!", 0 )
            creature:CastSpell(targetPlayer, 45108)
        end
    end
end

function addNPC.onEnterCombat(event, creature, target)
    local timer1 = 12000
    local timer2 = 7000
    local timer3 = 24000
    local player

    timer1 = timer1 / (1 + ((difficulty - 1) / 5))
    timer2 = timer2 / (1 + ((difficulty - 1) / 5))
    timer3 = timer3 / (1 + ((difficulty - 1) / 5))

    --print("addNPC.onEnterCombat")

    creature:RegisterEvent(addNPC.Bomb, timer1, 0)
    creature:RegisterEvent(addNPC.Bolt, timer2, 0)
    creature:RegisterEvent(addNPC.Knockback, timer3, 0)
    creature:CallAssistance()
    for _, v in pairs(playersInRaid) do
        player = GetPlayerByGUID(v)
        creature:AddThreat(player, 1)
    end
end

function addNPC.Bomb(event, delay, pCall, creature)
    local players = creature:GetPlayersInRange(30)
    --print("#players: "..#players)
    if #players > 1 then
        creature:CastSpell(creature:GetAITarget(SELECT_TARGET_NEAREST, true, 2, 30), 12421)
    else
        creature:CastSpell(creature:GetVictim(),12421)
    end
end

function addNPC.Bolt(event, delay, pCall, creature)
    if (math.random(1, 100) <= 25) then
        creature:CastSpell(creature:GetVictim(), 60488)
    end
end

function addNPC.Knockback(event, delay, pCall, creature)
    creature:CastSpell(creature, 24326)
    eS_checkInCombat()
end

function addNPC.reset(event, creature)
    --print("addNPC.reset")
    local player
    creature:RemoveEvents()
    creature:DespawnOrUnsummon(0)
    if bossfightInProgress == 1 then
        for n, v in pairs(playersInRaid) do
            player = GetPlayerByGUID(v)
            player:SetPhaseMask(1)
        end
        bossfightInProgress = nil
        local playerListString
        CreateLuaEvent(eS_castFireworks, 1000, 20)
        for _, v in pairs(playersInRaid) do
            player = GetPlayerByGUID(v)
            if playerListString == nil then
                playerListString = player:GetName()
            else
                playerListString = playerListString..", "..player:GetName()
            end
            player:SetPhaseMask(1)
        end
        SendWorldMessage("The encounter to slay an add of Glorifrir Flintshoulder was completed on difficulty "..difficulty.." by: "..playerListString.." Congratulations!")
    else
        if creature:IsDead() == true then
            if addsDownCounter == nil then
                addsDownCounter = 1
            else
                addsDownCounter = addsDownCounter + 1
            end
        end
    end
end

function eS_castFireworks()
    local fireworks = {}
    local player
    fireworks[1] = 66400
    fireworks[2] = 66402
    fireworks[3] = 46847
    fireworks[4] = 46829
    fireworks[5] = 46830
    fireworks[6] = 62074
    fireworks[7] = 62075
    fireworks[8] = 62077
    fireworks[9] = 55420
    for n, v in pairs(playersInRaid) do
        player = GetPlayerByGUID(v)
        player:CastSpell(player, fireworks[math.random(1, #fireworks)])
    end
end

function eS_resetPlayers(event, player)
    if eS_has_value(player:GetGUID()) then
        player:SetPhaseMask(1)
        player:SendBroadcastMessage("You left the event.")
    end
end

function eS_getSize(difficulty)
    local value
    if difficulty == 1 then
        value = 1
    else
        value = (difficulty - 1) / 4
    end
    return value
end

function eS_splitString(inputstr, seperator)
    if seperator == nil then
        seperator = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..seperator.."]+)") do
        table.insert(t, str)
    end
    return t
end

function eS_checkInCombat()
    --check if all players are in combat
    local player
    for n, v in pairs(playersInRaid) do
        player = GetPlayerByGUID(v)
        if player:IsInCombat() == false and player:GetPhaseMask() == 2 then
            player:SetPhaseMask(1)
            player:SendBroadcastMessage("You where returned to the real time because you did not participate.")
        end
    end
end

local function eS_has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

RegisterPlayerEvent(PLAYER_EVENT_ON_COMMAND, eS_command)
RegisterPlayerEvent(PLAYER_EVENT_ON_REPOP, eS_resetPlayers)

--init combat events
RegisterCreatureEvent(1112003, 1, addNPC.onEnterCombat)
RegisterCreatureEvent(1112003, 2, addNPC.reset) -- OnLeaveCombat
RegisterCreatureEvent(1112003, 4, addNPC.reset) -- OnDied

RegisterCreatureEvent(1112001, 1, bossNPC.onEnterCombat)
RegisterCreatureEvent(1112001, 2, bossNPC.reset) -- OnLeaveCombat
RegisterCreatureEvent(1112001, 4, bossNPC.reset) -- OnDied

--todo: Insert a function to despawn everything into .stopevent
-- get creature like this:
--local map = player:GetMap()
--local spawnedBoss = map:GetWorldObject(spawnedBossGuid):ToCreature()
--spawnedBoss:SendUnitSay("It works!", 0)

--todo: add a timer to the victory announcement and differ the party and raid announcements
--todo: Check DnD damaging adds

-- Custom Boss NPC:
-- INSERT INTO `chr_world`.`creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `modelid1`, `modelid2`, `modelid3`, `modelid4`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `scale`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `trainer_type`, `trainer_spell`, `trainer_class`, `trainer_race`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `InhabitType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `mechanic_immune_mask`, `spell_school_immune_mask`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES ('1112001', '0', '0', '0', '0', '0', '3456', '0', '0', '0', 'Glorifrir Flintshoulder', '', '0', '43', '43', '0', '63', '0', '1', '1.14286', '3', '3', '0', '30', '2000', '2000', '1', '1', '1', '32832', '2048', '0', '0', '0', '0', '0', '0', '7', '4', '0', '0', '0', '0', '0', '50000', '60000', 'SmartAI', '1', '3', '1', '600', '1', '1', '0', '0', '1', '0', '0', '256', '', '12340');
-- Custom Chromie:
-- INSERT INTO `chr_world`.`creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `modelid1`, `modelid2`, `modelid3`, `modelid4`, `name`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `scale`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `trainer_type`, `trainer_spell`, `trainer_class`, `trainer_race`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `InhabitType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `mechanic_immune_mask`, `spell_school_immune_mask`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES ('1112002', '0', '0', '0', '0', '0', '10008', '0', '0', '0', 'Chromie', '62001', '63', '63', '0', '35', '1', '1', '1.14286', '1', '0', '0', '1', '2000', '2000', '1', '1', '1', '33536', '2048', '0', '0', '0', '0', '0', '0', '2', '0', '0', '0', '100001', '0', '0', '0', '0', '', '0', '3', '1', '1.35', '1', '1', '0', '0', '1', '0', '0', '2', '', '12340');
-- Custom Add NPC:
-- INSERT INTO `chr_world`.`creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `modelid1`, `modelid2`, `modelid3`, `modelid4`, `name`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `scale`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `trainer_type`, `trainer_spell`, `trainer_class`, `trainer_race`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `InhabitType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `mechanic_immune_mask`, `spell_school_immune_mask`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES ('1112003', '0', '0', '0', '0', '0', '21443', '0', '0', '0', 'Zombie Captain', '0', '42', '42', '0', '415', '0', '1', '1.14286', '1', '1', '0', '10', '2000', '2000', '1', '1', '1', '0', '2048', '0', '0', '0', '0', '0', '0', '6', '0', '4860', '0', '0', '0', '0', '297', '393', 'SmartAI', '1', '3', '1', '30', '1', '1', '0', '0', '1', '650854271', '0', '0', '', '12340');
-- npc_text
-- INSERT INTO `chr_world`.`npc_text` (`ID`, `text0_0`, `BroadcastTextID0`, `lang0`, `Probability0`, `em0_0`, `em0_1`, `em0_2`, `em0_3`, `em0_4`, `em0_5`, `BroadcastTextID1`, `lang1`, `Probability1`, `em1_0`, `em1_1`, `em1_2`, `em1_3`, `em1_4`, `em1_5`, `BroadcastTextID2`, `lang2`, `Probability2`, `em2_0`, `em2_1`, `em2_2`, `em2_3`, `em2_4`, `em2_5`, `BroadcastTextID3`, `lang3`, `Probability3`, `em3_0`, `em3_1`, `em3_2`, `em3_3`, `em3_4`, `em3_5`, `BroadcastTextID4`, `lang4`, `Probability4`, `em4_0`, `em4_1`, `em4_2`, `em4_3`, `em4_4`, `em4_5`, `BroadcastTextID5`, `lang5`, `Probability5`, `em5_0`, `em5_1`, `em5_2`, `em5_3`, `em5_4`, `em5_5`, `BroadcastTextID6`, `lang6`, `Probability6`, `em6_0`, `em6_1`, `em6_2`, `em6_3`, `em6_4`, `em6_5`, `BroadcastTextID7`, `lang7`, `Probability7`, `em7_0`, `em7_1`, `em7_2`, `em7_3`, `em7_4`, `em7_5`, `VerifiedBuild`) VALUES ('91111', 'Greetings, $n. One of the invaders of the timeline is in a nearby timenode. I might be able to make them visible for your eyes and vulnerable to your magic and weapons, but i can not aid you in this fight while i am maintaining the spell. Are you ready to face the worst this timeline has to deal with?', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '1');
-- INSERT INTO `chr_world`.`gossip_menu` (`MenuID`, `TextID`) VALUES ('62001', '91111');