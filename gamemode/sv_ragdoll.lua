local PLAYER = FindMetaTable("Player")
local ENTITY = FindMetaTable("Entity")

local IsValid = IsValid
local util_IsValidRagdoll = util.IsValidRagdoll
local table_insert = table.insert

if not PLAYER.CreateRagdollOld then
	PLAYER.CreateRagdollOld = PLAYER.CreateRagdoll
end

local function clearupRagdolls(ragdolls, max)
	local count = 1
	for k, rag in pairs(ragdolls) do
		if IsValid(rag) then
			count = count + 1
		else
			rag[k] = nil
		end
	end

	if max >= 0 and count > max then
		while true do
			if count > max then
				if IsValid(ragdolls[1]) then
					ragdolls[1]:Remove()
				end
				
				table.remove(ragdolls, 1)
				count = count - 1
			else
				break
			end
		end
	end
end

function PLAYER:CreateRagdoll(attacker, dmginfo)
	local ent = self:GetNWEntity("DeathRagdoll")

	-- remove old player ragdolls
	if not self.DeathRagdolls then self.DeathRagdolls = {} end
	local max = hook.Run("MaxDeathRagdollsPerPlayer", self)
	clearupRagdolls(self.DeathRagdolls, max or 1)

	-- remove old server ragdolls
	if not GAMEMODE.DeathRagdolls then GAMEMODE.DeathRagdolls = {} end
	local max = hook.Run("MaxDeathRagdolls")
	clearupRagdolls(GAMEMODE.DeathRagdolls, max or 1)

	local data = duplicator.CopyEntTable(self)
	if not util_IsValidRagdoll(data.Model) then
		data.Model = "models/player/skeleton.mdl"
		-- if use pointshop or something similar to handle character models, just return could be problem with disguise.
	end

	local ent = ents.Create( "prop_ragdoll" )
	data.ModelScale = 1 -- doesn't work on ragdolls
	duplicator.DoGeneric(ent, data)
	
	self:SetNWEntity("DeathRagdoll", ent )
	ent:SetNWEntity("RagdollOwner", self)
	table_insert(self.DeathRagdolls,ent)
	table_insert(GAMEMODE.DeathRagdolls,ent)
	
	if ent.SetPlayerColor then
		ent:SetPlayerColor(self:GetPlayerColor())
	end
	ent.PlayerRagdoll = true
	hook.Run("PreDeathRagdollSpawn", self, ent)
	ent:Spawn()
	ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	
	hook.Run("OnDeathRagdollCreated", self, ent)
	ent:Fire("kill", "", 60 * 8)

	local vel = self:GetVelocity()
	for bone = 0, ent:GetPhysicsObjectCount() - 1 do
		local phys = ent:GetPhysicsObjectNum( bone )
		if IsValid(phys) then
			local pos, ang = self:GetBonePosition( ent:TranslatePhysBoneToBone( bone ) )
			phys:SetPos(pos)
			phys:SetAngles(ang)
			phys:AddVelocity(vel)
		end
	end
end

if not PLAYER.GetRagdollEntityOld then
	PLAYER.GetRagdollEntityOld = PLAYER.GetRagdollEntity
end
function PLAYER:GetRagdollEntity()
	local ent = self:GetNWEntity("DeathRagdoll")
	if IsValid(ent) then
		return ent
	end

	return self:GetRagdollEntityOld()
end

if not PLAYER.GetRagdollOwnerOld then
	PLAYER.GetRagdollOwnerOld = PLAYER.GetRagdollOwner
end
function ENTITY:GetRagdollOwner()
	local ent = self:GetNWEntity("RagdollOwner")
	if IsValid(ent) then
		return ent
	end

	return self:GetRagdollOwnerOld()
end
