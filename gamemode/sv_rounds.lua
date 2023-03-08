util.AddNetworkString("SetRound")
util.AddNetworkString("DeclareWinner")
util.AddNetworkString("ChangeMaxLength")

local IsValid = IsValid
local math_max = math.max
local team_GetPlayers = team.GetPlayers
local pairs = pairs

GM.RoundStage = 0
GM.RoundCount = 0
GM.RoundStarted = 0
GM.Murderers = {}

if GAMEMODE then
	GM.RoundStage = GAMEMODE.RoundStage
	GM.RoundCount = GAMEMODE.RoundCount
	GM.RoundStarted = GAMEMODE.RoundStarted
end

function GM:GetRound()
	return self.RoundStage or 0
end

function GM:GetRoundTime()
	local started = self.RoundStarted or 0
	return CurTime() - self.RoundStarted
end

function GM:CheckRoundTime()
	local max = self.RoundSettings.RoundMaxLength or 0
	if max == -1 then
		-- Disabled
		return true
	end

	local time = self:GetRoundTime()
	time = max - time

	if time <= 0 then
		-- Ran out of time
		return false
	else
		-- Still got time
		return true
	end
end

function GM:ChangeRoundMaxLength(seconds)
	net.Start("ChangeMaxLength")
	net.WriteInt(seconds, 32)
	net.Broadcast()

	self.RoundSettings.RoundMaxLength = seconds
end

function GM:SetRound(round)
	self.RoundStage = round
	self.RoundTime = CurTime()

	self.RoundSettings = {}

	self.RoundSettings.ShowAdminsOnScoreboard = self.ShowAdminsOnScoreboard:GetBool()
	self.RoundSettings.AdminPanelAllowed = self.AdminPanelAllowed:GetBool()
	self.RoundSettings.ShowSpectateInfo = self.ShowSpectateInfo:GetBool()
	self.RoundSettings.RoundMaxLength = self.RoundMaxLength:GetInt()

	self:NetworkRound()
end

function GM:NetworkRound(ply)
	net.Start("SetRound")
	net.WriteUInt(self.RoundStage, 8)
	net.WriteDouble(self.RoundTime)

	if self.RoundSettings then
		net.WriteUInt(1, 8)
		net.WriteUInt(self.RoundSettings.ShowAdminsOnScoreboard and 1 or 0, 8)
		net.WriteUInt(self.RoundSettings.AdminPanelAllowed and 1 or 0, 8)
		net.WriteUInt(self.RoundSettings.ShowSpectateInfo and 1 or 0, 8)
		net.WriteInt(self.RoundSettings.RoundMaxLength, 32)
	else
		net.WriteUInt(0, 8)
	end

	if self.RoundStage == 5 then
		net.WriteDouble(self.StartNewRoundTime)
	end

	if ply == nil then
		net.Broadcast()
	else
		net.Send(ply)
	end
end


function GM:RoundThink()
	local players = team_GetPlayers(2)
	if self.RoundStage == self.Round.NotEnoughPlayers then
		if #players > 1 and (not self.LastPlayerSpawn or self.LastPlayerSpawn + 1 < CurTime()) then 
			self.StartNewRoundTime = CurTime() + self.DelayAfterEnoughPlayers:GetFloat()
			self:SetRound(self.Round.RoundStarting)
		end
	elseif self.RoundStage == self.Round.Playing then
		if not self.RoundLastDeath or self.RoundLastDeath < CurTime() then
			self:RoundCheckForWin()
		end

		if self.RoundUnFreezePlayers and self.RoundUnFreezePlayers < CurTime() then
			self.RoundUnFreezePlayers = nil
			for k, ply in pairs(players) do
				if ply:Alive() then
					ply:Freeze(false)
					ply.Frozen = false
				end
			end
		end

		-- after x minutes without a kill reveal the murderer
		local time = self.MurdererFogTime:GetFloat()
		time = math_max(0, time)
		local players = team_GetPlayers(2)

		for k, ply in pairs(players) do
			if ply:GetMurderer() then
				if time > 0 and ply.MurdererLastKill and ply.MurdererLastKill + time < CurTime() then
					if not ply:GetMurdererRevealed() then
						ply:SetMurdererRevealed(true)
						ply.MurdererLastKill = nil
					end
				end
			end
		end
	elseif self.RoundStage == self.Round.RoundEnd then
		if self.RoundTime + 5 < CurTime() then
			self:StartNewRound()
		end

	elseif self.RoundStage == self.Round.RoundStarting then
		if #players <= 1 then
			self:SetRound(0)
		elseif CurTime() >= self.StartNewRoundTime then
			self:StartNewRound()

			for _, ply in pairs(player.GetAll()) do
				ply.MurdererLastKill = nil
			end
		end
	end	
end

function GM:RoundCheckForWin()
	local murderers = {}
	local players = team_GetPlayers(2)

	if #players <= 0 then 
		self:SetRound(0)
		return 
	end

	local survivors = {}
	for k,v in pairs(players) do
		if v:Alive() and not v:GetMurderer() then
			table.insert(survivors, v)
		end

		if v:GetMurderer() then
			murderers[#murderers + 1] = v
		end
	end

	-- check we have a murderer
	if #murderers < 1 then
		self:EndTheRound(3, murderers)
		return
	end

	-- has the murderer killed everyone?
	if #survivors < 1 then
		self:EndTheRound(1, murderers)
		return
	end

	local livingMurderer = false
	for _, ply in pairs(murderers) do
		if not IsValid(ply) then continue end
		if not ply:Alive() then continue end

		livingMurderer = true
	end

	-- is the murderer dead?
	if not livingMurderer then
		self:EndTheRound(2, murderers)
		return
	end

	-- Ran out of time?
	if not self:CheckRoundTime() then
		self:EndTheRound(2, murderers)
		return
	end

	-- keep playing.
end


function GM:DoRoundDeaths(dead, attacker)
	if self.RoundStage == self.Round.Playing then
		local time = CurTime() + 2
		
		self.RoundLastDeath = time
		attacker.LastKill = time
	end
end

-- 1 Murderer wins
-- 2 Murderer loses
-- 3 Murderer rage quit
function GM:EndTheRound(reason, murderers)
	if self.RoundStage ~= self.Round.Playing then return end

	local players = team_GetPlayers(2)
	for k, ply in pairs(players) do
		ply:SetTKer(false)
		ply:SetMurdererRevealed(false)
		ply:UnMurdererDisguise()
	end

	if reason == 3 then
		if murderers >= 1 then
			local hasAMurderer = false 

			for _, ply in pairs(murderers) do
				if not IsValid(ply) then continue end

				hasAMurderer = true

				local col = murderer:GetPlayerColor()
				local msgs = Translator:AdvVarTranslate(translate.murdererDisconnectKnown, {
					murderer = {text = murderer:Nick() .. ", " .. murderer:GetBystanderName(), color = Color(col.x * 255, col.y * 255, col.z * 255)}
				})

				local ct = ChatText(msgs)
				ct:SendAll()
				-- ct:Add(", it was ")
				-- ct:Add(murderer:Nick() .. ", " .. murderer:GetBystanderName(), Color(col.x * 255, col.y * 255, col.z * 255))
			end

			if not hasAMurderer then
				local ct = ChatText()
				ct:Add(translate.murdererDisconnect)
				ct:SendAll()
			end
		else
			local ct = ChatText()
			ct:Add(translate.murdererDisconnect)
			ct:SendAll()
		end
	elseif reason == 2 then
		for _, ply in pairs(murderers) do
			if IsValid(ply) then continue end

			local col = ply:GetPlayerColor()
			local msgs = Translator:AdvVarTranslate(translate.winBystandersMurdererWas, {
				murderer = {text = ply:Nick() .. ", " .. ply:GetBystanderName(), color = Color(col.x * 255, col.y * 255, col.z * 255)}
			})
			local ct = ChatText()
			ct:Add(translate.winBystanders, color_dblue or Color(20, 120, 255))
			ct:AddParts(msgs)
			ct:SendAll()
		end

		--[[
		for _, ply in pairs(team.GetPlayers(2)) do
			if ply:Alive() then
				ply:AddFrags(2)
			else
				ply:AddFrags(1)
			end
		end
		]]
	elseif reason == 1 then
		for _,ply in pairs(murderers) do
			if not IsValid(ply) then continue end
				
			local col = ply:GetPlayerColor()
			local msgs = Translator:AdvVarTranslate(translate.winMurdererMurdererWas, {
				murderer = {text = ply:Nick() .. ", " .. ply:GetBystanderName(), color = Color(col.x * 255, col.y * 255, col.z * 255)}
			})
			local ct = ChatText()
			ct:Add(translate.winMurderer, color_red or Color(190, 20, 20))
			ct:AddParts(msgs)
			ct:SendAll()

			--ply:AddFrags(2)
		end
	end

	net.Start("DeclareWinner")
	net.WriteUInt(reason, 8)
	if #murderers >= 1 then
		net.WriteTable(murderers)

		local murdererColors = {}
		for _, ply in pairs(murderers) do
			if not IsValid(ply) then return end

			murdererColors[#murdererColors + 1] = ply:GetPlayerColor()
		end

		net.WriteTable(murdererColors)

		local murdererNames = {}
		for _, ply in pairs(murderers) do
			if not IsValid(ply) then return end

			murdererNames[#murdererNames + 1] = ply:GetBystanderName()
		end

		net.WriteTable(murdererNames)
	else
		net.WriteEntity(Entity(0))
		net.WriteVector(Vector(1, 1, 1))
		net.WriteString("?")
	end

	for _, ply in pairs(team_GetPlayers(2)) do
		net.WriteUInt(1, 8)
		net.WriteEntity(ply)
		net.WriteUInt(ply.LootCollected, 32)
		net.WriteVector(ply:GetPlayerColor())
		net.WriteString(ply:GetBystanderName())
	end

	net.WriteUInt(0, 8)
	net.Broadcast()

	for k, ply in pairs(players) do
		if not ply.HasMoved and not ply.Frozen and self.AFKMoveToSpec:GetBool() then
			local oldTeam = ply:Team()
			ply:SetTeam(1)
			GAMEMODE:PlayerOnChangeTeam(ply, 1, oldTeam)

			local col = ply:GetPlayerColor()
			local msgs = Translator:AdvVarTranslate(translate.teamMovedAFK, {
				player = {text = ply:Nick(), color = Color(col.x * 255, col.y * 255, col.z * 255)},
				team = {text = team.GetName(1), color = team.GetColor(2)}
			})
			local ct = ChatText()
			ct:AddParts(msgs)
			ct:SendAll()
		end

		if ply:Alive() then
			ply:Freeze(false)
			ply.Frozen = false
		end
	end

	self.RoundUnFreezePlayers = nil
	self.MurdererLastKill = nil

	for _, ply in pairs(player.GetAll()) do 
		ply.MurdererLastKill = nil
	end

	hook.Call("OnEndRound")
	hook.Run("OnEndRoundResult", reason)
	self.RoundCount = self.RoundCount + 1
	local limit = self.RoundLimit:GetInt()
	if limit > 0 then
		if self.RoundCount >= limit then
			self:ChangeMap()
			self:SetRound(4)
			return
		end
	end
	self:SetRound(2)
end

function GM:StartNewRound()
	local players = team_GetPlayers(2)

	if #players <= 1 then 
		local ct = ChatText()
		ct:Add(translate.minimumPlayers, Color(255, 150, 50))
		ct:SendAll()
		self:SetRound(self.Round.NotEnoughPlayers)
		return
	end

	local ct = ChatText()
	ct:Add(translate.roundStarted)
	ct:SendAll()

	self.RoundUnFreezePlayers = CurTime() + 10

	local players = team_GetPlayers(2)
	for k,ply in pairs(players) do
		ply:UnSpectate()
	end
	
	game.CleanUpMap()
	self:InitPostEntityAndMapCleanup()
	self:ClearAllFootsteps()

	local oldMurderers = {}
	for k,ply in pairs(players) do
		if ply:GetMurderer() then
			oldMurderers[ply] = true
		end
	end
	
	local murderers = {}

	-- get the weight multiplier
	local weightMul = self.MurdererWeight:GetFloat()

	-- pick a random murderer, weighted
	local rand = WeightedRandom()
	for k, ply in pairs(players) do
		rand:Add(ply.MurdererChance ^ weightMul, ply)
		ply.MurdererChance = ply.MurdererChance + 1
	end

	if #team_GetPlayers(2) >= 10 then
		for i = 1, (math.Round(#team_GetPlayers(2), -1) / 10) + 1 do  
			murderers[#murderers + 1] = rand:Roll()
		end
	else
		murderers[1] = rand:Roll()
	end

	-- allow admins to specify next murderer
	if self.ForceNextMurderer and IsValid(self.ForceNextMurderer) and self.ForceNextMurderer:Team() == 2 then
		murderers[1] = self.ForceNextMurderer
		self.ForceNextMurderer = nil
	end

	for _, ply in pairs(murderers) do 
		ply:SetMurderer(true)
	end

	for k, ply in pairs(players) do
		if not table.HasValue(murderers, ply) then
			ply:SetMurderer(false)
		end

		ply:StripWeapons()
		ply:KillSilent()
		ply:Spawn()
		ply:Freeze(true)
		local vec = Vector(0, 0, 0)
		vec.x = math.Rand(0, 1)
		vec.y = math.Rand(0, 1)
		vec.z = math.Rand(0, 1)
		ply:SetPlayerColor(vec)

		ply.LootCollected = 0
		ply.HasMoved = false
		ply.Frozen = true
		ply:SetTKer(false)
		ply:CalculateSpeed()
		ply:GenerateBystanderName()
	end

	local noobs = table.Copy(players)
	for _, ply in pairs(murderers) do 
		table.RemoveByValue(noobs, ply)
	end

	local magnum = table.Random(noobs)
	if IsValid(magnum) then
		magnum:Give("weapon_mu_magnum")
	end

	local startTime = CurTime()
	for _, ply in pairs(murderers) do 
		ply.MurdererLastKill = startTime
	end

	self.MurdererLastKill = startTime

	self:SetRound(self.Round.Playing)
	self.RoundStarted = CurTime()
	hook.Call("OnStartRound")
end

function GM:PlayerLeavePlay(ply)
	if ply:HasWeapon("weapon_mu_magnum") then
		ply:DropWeapon(ply:GetWeapon("weapon_mu_magnum"))
	end

	local murderers = {}

	if self.RoundStage == 1 then
		if ply:GetMurderer() then
			murderers[1] = ply
		end
	end

	local hasMurderer = false
	for _, ply in pairs(team_GetPlayers(2)) do
		if not IsValid(ply) then continue end
		if ply == murderers[1] then continue end
		if not ply:GetMurderer() then continue end
		
		murderers[#murderers + 1] = ply
		hasMurderer = true
	end

	if not hasMurderer then
		self:EndTheRound(3, murderers)
	end
end

concommand.Add("mu_forcenextmurderer", function (ply, com, args)
	if not ply:IsAdmin() then return end
	if #args < 1 then return end

	local ent = Entity(tonumber(args[1]) or -1)
	if not IsValid(ent) or not ent:IsPlayer() then 
		ply:ChatPrint("not a player")
		return 
	end

	GAMEMODE.ForceNextMurderer = ent
	local msgs = Translator:AdvVarTranslate(translate.adminMurdererSelect, {
		player = {text = ent:Nick(), color = team.GetColor(2)}
	})
	local ct = ChatText()
	ct:AddParts(msgs)
	ct:Send(ply)
end)

function GM:ChangeMap()
	if #self.MapList > 0 then
		if MapVote then
			-- only match maps that we have specified
			local prefix = {}
			for k, map in pairs(self.MapList) do
				table.insert(prefix, map .. "%.bsp$")
			end
			MapVote.Start(nil, nil, nil, prefix)
			return
		end
		self:RotateMap()
	end
end

function GM:RotateMap()
	local map = game.GetMap()
	local index 
	for k, map2 in pairs(self.MapList) do
		if map == map2 then
			index = k
		end
	end
	if not index then index = 1 end
	index = index + 1
	if index > #self.MapList then
		index = 1
	end
	local nextMap = self.MapList[index]
	print("[Murder] Rotate changing map to " .. nextMap)
	local ct = ChatText()
	ct:Add(Translator:QuickVar(translate.mapChange, "map", nextMap))
	ct:SendAll()
	hook.Call("OnChangeMap", GAMEMODE)
	timer.Simple(5, function ()
		RunConsoleCommand("changelevel", nextMap)
	end)
end

GM.MapList = {}

local defaultMapList = {
	"clue",
	"cs_italy",
	"ttt_clue",
	"cs_office",
	"de_chateau",
	"de_tides",
	"de_prodigy",
	"mu_nightmare_church",
	"dm_lockdown",
	"housewithgardenv2",
	"de_forest"
}

function GM:SaveMapList()

	-- ensure the folders are there
	if not file.Exists("murder/","DATA") then
		file.CreateDir("murder")
	end

	local txt = ""
	for k, map in pairs(self.MapList) do
		txt = txt .. map .. "\r\n"
	end
	file.Write("murder/maplist.txt", txt)
end

function GM:LoadMapList() 
	local jason = file.ReadDataAndContent("murder/maplist.txt")
	if jason then
		local tbl = {}
		local i = 1
		for map in jason:gmatch("[^\r\n]+") do
			table.insert(tbl, map)
		end
		self.MapList = tbl
	else
		local tbl = {}
		for k, map in pairs(defaultMapList) do
			if file.Exists("maps/" .. map .. ".bsp", "GAME") then
				table.insert(tbl, map)
			end
		end
		self.MapList = tbl
		self:SaveMapList()
	end
end

concommand.Add("mu_update_length", function(ply, cmd, args, argStr)
	if not ply:IsSuperAdmin() then return end

	local seconds = tonumber(args[1])
	if seconds ~= nil then
		if seconds ~= -1 then
			seconds = seconds + GAMEMODE:GetRoundTime()
		end
		GAMEMODE:ChangeRoundMaxLength(seconds)
	end
end)