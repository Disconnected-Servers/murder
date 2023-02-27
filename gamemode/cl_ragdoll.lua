local PLAYER = FindMetaTable("Player")
local ENTITY = FindMetaTable("Entity")

local IsValid = IsValid

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