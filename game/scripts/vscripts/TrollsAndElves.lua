TechBuilding = {
	npc_trollsandelves_rock_1 = true
} --what is this doing here


if TrollsAndElvesGameMode == nil then
    TrollsAndElvesGameMode = {}
    TrollsAndElvesGameMode.__index = TrollsAndElvesGameMode
end

function TrollsAndElvesGameMode:new (o)
    o = o or {}
    setmetatable(o, self)
    TROLLSANDELVES_REFERENCE = o
    return o
end

function TrollsAndElvesGameMode:TechAdvance(player, building)
    print(player:GetClassname())
	print("Upgrading " .. building)
	for k,v in pairs(player) do
        if type(v) == "table" then
            print(" "..k.." = {")
            for k2,v2 in pairs(v) do
                if type(v2) == "table" then
                    v2 = "table"
                elseif type(v2) == "userdata" then
                    v2 = "userdata"
                end
                print("     "..tostring(k2).."="..tostring(v2))
            end
            print(" }")
        elseif type(v) == "userdata" then
            print(" "..k.."= userdata")
        else
            print(" "..k.."="..v)
        end
    end
	player.TechBuildings[building] = true
	if building == "npc_trollsandelves_rock_1" then 
		local buildmenu = player:GetAssignedHero():FindAbilityByName("trollsandelves_build_menu")
		buildmenu:SetHidden(false) 
		buildmenu:SetLevel(1) 
	end
end

function TrollsAndElvesGameMode:InitGameMode()
	Msg("Hello World, My name is TrollsAndElves!")
	GameRules:EnableCustomGameSetupAutoLaunch(false)
    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 12)
    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 12)
	--CEntities:FindByClassname(nil, "dota_base_game_mode"):SetFogOfWarDisabled(true)
	
    --Event registration --
	ListenToGameEvent('player_chat', Dynamic_Wrap(TrollsAndElvesGameMode,"onChatMessage"), self)
	ListenToGameEvent('player_connect_full', Dynamic_Wrap(TrollsAndElvesGameMode,"onPlayerConnect"), self)
	ListenToGameEvent("dota_item_purchased", Dynamic_Wrap(TrollsAndElvesGameMode, "OnItemPurchased"), self)
    ListenToGameEvent('npc_spawned', Dynamic_Wrap(TrollsAndElvesGameMode, "onNPCSpawned"), self)
    
	-- Start thinkers
    --self._scriptBind:BeginThink('TrollsAndElvesThink', Dynamic_Wrap(TrollsAndElvesGameMode, 'Think'), 0.1)
end

-- Listen for changes in the current state
ListenToGameEvent('game_rules_state_change', function(keys)
    -- Grab the current state
    local state = GameRules:State_Get()
    
    if state == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
        for i=1,(PlayerResource:GetPlayerCount() or 1) do
            local player = PlayerResource:GetPlayer(i)
            PlayerResource:SetCustomTeamAssignment(i, DOTA_TEAM_GOODGUYS)
        end
        GameRules:LockCustomGameSetupTeamAssignment(true)
        GameRules:GetGameModeEntity():SetCustomGameForceHero("npc_dota_hero_invoker")
        GameRules:SetCustomGameSetupRemainingTime(1)
    end
end, nil)

function TrollsAndElvesGameMode:onNPCSpawned(keys)
    local spawnedUnit = EntIndexToHScript(self.entindex)

    if spawnedUnit:IsRealHero() then
  		GameRules.ID_TO_HERO[spawnedUnit:GetPlayerID()] = spawnedUnit
  	end

    if spawnedUnit:GetClassname() ~= "npc_dota_creep" then
        print(spawnedUnit:GetClassname())
    end
    if spawnedUnit:GetClassname() == "npc_dota_hero_troll_warlord" or spawnedUnit:GetClassname() == "npc_dota_hero_lycan" then
        print("Troll detected!")
        local ability_1 = spawnedUnit:FindAbilityByName("trollsandelves_troll_invis")
        local ability_2 = spawnedUnit:FindAbilityByName("trollsandelves_troll_pillage")
        ability_1:SetLevel(1)
        ability_2:SetLevel(1)
        spawnedUnit:SetHullRadius(56)
    elseif spawnedUnit:GetClassname() == "npc_dota_hero_invoker" then --yep capital I
        EntityInit:NewByClassname(spawnedUnit:GetPlayerOwner(), "player")
    	EntityInit:NewByType(spawnedUnit, "Builder")
    end
end

function TrollsAndElvesGameMode:TrollBuyItem(player, item)
	local itemdata = ItemsCustomKV[item]
	local playergold = PlayerResource:GetGold(player:GetPlayerID())
	local lumbercost = itemdata.LumberCost or 0
	local itemcost = itemdata.ItemCost or 0
	local playerid = player:GetPlayerID()
	local hero = player:GetAssignedHero()

	print(itemdata)
	print(playergold)
	print(player.LumberTotal)
	print(itemdata.LumberCost)
	print(itemdata.ItemCost)

	if player.LumberTotal >= lumbercost and playergold >= itemcost then 
		PlayerResource:ModifyGold(playerid, -itemcost, false, 0)
		player.LumberTotal = player.LumberTotal - lumbercost
		FireGameEvent("trollsandelves_lumber", {pid=playerid, lumber=player.LumberTotal})
		local item = CreateItem( item, hero, hero )
		hero:AddItem(item)
	else --ERROR PLEASE
        if player.LumberTotal >= lumbercost then
            ShowGenericPopupToPlayer(player, "#trollsandelves_error_purchase", "#trollsandelves_error_gold", "", "", DOTA_SHOWGENERICPOPUP_TINT_SCREEN)
        else
            ShowGenericPopupToPlayer(player, "#trollsandelves_error_purchase", "#trollsandelves_error_lumber", "", "", DOTA_SHOWGENERICPOPUP_TINT_SCREEN)
        end
	end
end

function TrollsAndElvesGameMode:onChatMessage(keys)

end

local treesinit = false
function TrollsAndElvesGameMode:onPlayerConnect(keys)
	if treesinit == false then 
		for k,v in pairs(Entities:FindAllByClassname("ent_dota_tree")) do 
		    local u = CreateUnitByName( "npc_tree_dummy", Vector(0,0,0), true, nil, nil, 2)
		    u:SetOrigin(v:GetOrigin())
		    u:AddNewModifier(v, nil, "modifier_phased", {duration = -1})
		end
		treesinit = true
	end
end

function TrollsAndElvesGameMode:ModifyLumber(player, sum) --negative to reduce
	local lumber = player.LumberTotal
	if sum > player.LumberTotal then 
		player.LumberTotal = player.LumberTotal + sum
		return true
	else return false
	end
end

function TrollsAndElvesGameMode:OnItemPurchased(keys)
	local item = ItemsCustomKV[item]
	local player = EntIndexToHScript(PlayerResource:GetPlayer(keys.PlayerID))
	if item.LumberCost and item.LumberCost > 0 then self:ModifyLumber(player, item.LumberCost) end
end

--TODO: actually get this thing online
function TrollsAndElvesGameMode:Think()
    -- Track game time, since the dt passed in to think is actually wall-clock time not simulation time.
    local now = GameRules:GetGameTime()
    if self.t0 == nil then
        self.t0 = now
    end
    local dt = now - self.t0
    self.t0 = now
end

function TrollsAndElvesGameMode.PlayerWantsToSpawn(cmdname, origin, unit)
	
end

function TrollsAndElvesGameMode.PlayerWantsToBuild(cmdname, building) --maybe add some stuff to do stuff here
	print(building)
	local player = Convars:GetCommandClient()    
	player:GetAssignedHero():FindAbilityByName("trollsandelves_construct_building"):SetHidden(false)
	if UnitsCustomKV[building] then
        player.WantsToBuild = building
    else
        print("This doesn't seem right")
        FireGameEvent("dota_hud_error_message", {reason=0,message="Hello World!"})
    end
    print(player.WantsToBuild)
end

function TrollsAndElvesGameMode.BuildingQueueUnit(cmdname, building, unit)
	local unitdata = UnitsCustomKV[unit]
	local lumbercost = unitdata.LumberCost
	local goldcost = unitdata.GoldCost
	local playerowner = Convars:GetCommandClient()
	local currentlumber = playerowner.LumberTotal
	local currentgold = PlayerResource:GetGold(playerowner:GetPlayerID())
	local team = playerowner:GetTeam()
    
	--findclearspace won't work, need to generate an emission point when the building is created
	if currentlumber >= lumbercost and currentgold >= goldcost then 
		playerowner:ModifyGold(-goldcost, true, 0)	
		playerowner.LumberTotal = currentlumber - lumbercost
		local unit = CreateUnitByName(unit, Vector(0,0,0), true, nil, nil, keys.caster:GetTeamNumber())
		FindClearSpaceForUnit(unit, keys.caster:GetOrigin(), true)
	end
end

function TrollsAndElvesGameMode.UnitSelected(keys)
	
end

Convars:RegisterCommand("tae_use_spell", TrollsAndElvesGameMode.PlayerWantsToSpawn, "Build thing", 0)
Convars:RegisterCommand("tae_building_queue_unit", TrollsAndElvesGameMode.BuildingQueueUnit, "Build thing", 0)
Convars:RegisterCommand("tae_wants_to_build", TrollsAndElvesGameMode.PlayerWantsToBuild, "Build thing", 0)