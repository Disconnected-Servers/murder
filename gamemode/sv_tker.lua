local PLAYER = FindMetaTable("Player")
local ENTITY = FindMetaTable("Entity")

util.AddNetworkString("mu_tker")

local IsValid = IsValid

function PLAYER:SetTKer(bool)
	if bool then
		self.LastTKTime = CurTime()

		timer.Simple(0, function () 
			if IsValid(self) and self:HasWeapon("weapon_mu_magnum") then
				local wep = self:GetWeapon("weapon_mu_magnum")
				wep.LastTK = self
				wep.LastTKTime = CurTime()
				self:DropWeapon(wep)
			end
		end)

		net.Start("mu_tker")
		net.WriteUInt(1, 8)
		net.Send(self)
	else
		self.LastTKTime = nil

		net.Start("mu_tker")
		net.WriteUInt(0, 8)
		net.Send(self)
	end
	
	self:CalculateSpeed()
end

function PLAYER:GetTKer()
	return self.LastTKTime and true or false
end