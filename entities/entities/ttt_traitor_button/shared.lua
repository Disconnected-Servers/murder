ENT.Type = "anim"
ENT.Base = "base_anim"

function ENT:SetupDataTables()
	-- this is a ridiculous amount of network vars
	self:NetworkVar("Float", 0, "Delay")
	self:NetworkVar("Float", 1, "NextUseTime")
	self:NetworkVar("Bool", 0, "Locked")
	self:NetworkVar("String", 0, "Description")
	self:NetworkVar("Int", 0, "UsableRange", {KeyName = "UsableRange"})
end

function ENT:IsUsable()
   return (not self:GetLocked()) and self:GetNextUseTime() < CurTime()
end

if CLIENT then
	net.Receive("TTT_ConfirmUseTButton", function ()
		surface.PlaySound("buttons/button24.wav")
	end)
end