local ENTITY = FindMetaTable("Entity")

function GM:PlayerFootstep(ply, pos, foot, sound, volume, filter)
	self:FootStepsFootstep(ply, pos, foot, sound, volume, filter)
end

function ENTITY:GetPlayerColor()
	return self:GetNWVector("playerColor") or Vector()
end

function ENTITY:GetBystanderName()
	local name = self:GetNWString("bystanderName")

	if not name or name == "" then
		return "Bystander" 
	end
	
	return name
end