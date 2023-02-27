local PLAYER = FindMetaTable("Player")

local IsValid = IsValid
local pairs = pairs
local team_GetPlayers = team.GetPlayers

util.AddNetworkString("your_are_a_murderer")

GM.MurdererWeight = CreateConVar("mu_murder_weight_multiplier", 2, bit.bor(FCVAR_NOTIFY), "Multiplier for the weight of the murderer chance" )

function PLAYER:SetMurderer(bool)
	self.Murderer = bool
	
	if bool then
		self.MurdererChance = 1
	end

	net.Start( "your_are_a_murderer" )
	net.WriteUInt(bool and 1 or 0, 8)
	net.Send( self )
end

function PLAYER:GetMurderer(bool)
	return self.Murderer
end

function PLAYER:SetMurdererRevealed(bool)
	self:SetNWBool("MurdererFog", bool)

	if bool then
		if not self.MurdererRevealed then
		end
	else
		if self.MurdererRevealed then
		end
	end

	self.MurdererRevealed = bool
end

function PLAYER:GetMurdererRevealed()
	return self.MurdererRevealed
end

local NO_KNIFE_TIME = 30
function GM:MurdererThink()
	local players = team_GetPlayers(2)
	local murderers = {}

	for k,ply in pairs(players) do
		if ply:GetMurderer() then
			murderers[#murderers + 1] = ply
			break
		end
	end

	-- regenerate knife if on ground
	for _, play in pairs(murderers) do
		if IsValid(ply) and ply:Alive() then
			if ply:HasWeapon("weapon_mu_knife") then
				ply.LastHadKnife = CurTime()
			else
				if ply.LastHadKnife and ply.LastHadKnife + NO_KNIFE_TIME < CurTime() then


					--add a check for if the knife is owned by the player
					for _, ent in pairs(ents.FindByClass("weapon_mu_knife")) do
						ent:Remove()
					end

					for _, ent in pairs(ents.FindByClass("mu_knife")) do
						ent:Remove()
					end

					ply:Give("weapon_mu_knife")
				end
			end
		end
	end
end