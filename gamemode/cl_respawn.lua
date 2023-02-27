local LocalPlayer = LocalPlayer
local ScrW = ScrW
local ScrH = ScrH
local CurTime = CurTime
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local render_SetColorModulation = render.SetColorModulation
local render_SetBlend = render.SetBlend

function GM:RenderDeathOverlay()
	local client = LocalPlayer()
	local sw, sh = ScrW(), ScrH()

	if GAMEMODE.SpectateTime > CurTime() then

		-- render black screen
		surface_SetDrawColor(0,0,0,255)
		surface_DrawRect(-1,-1,sw + 2,sh + 2)

		render_SetColorModulation(1, 1, 1)
		render_SetBlend(1)

		
		-- render body
		cam.Start3D( EyePos(), EyeAngles() )
		cam.IgnoreZ(true)
		local ent = client:GetRagdollEntity()
		if IsValid(ent) then
			ent:DrawModel()
		end
		cam.IgnoreZ(false)
		cam.End3D()
	end
end

GM.SpectateTime = 0
net.Receive("mu_death", function()
	GAMEMODE.SpectateTime = CurTime() + net.ReadUInt(4)
end)

function GM:RenderRespawnText()
	local client = LocalPlayer()
	local sw,sh = ScrW(),ScrH()
	
	local t = math.max(math.ceil(GAMEMODE.SpectateTime - CurTime()), 0)
	
	if t <= 0 then
		self:RenderSpectate()
	else
		draw.DrawText(tostring(t), "MersDeathBig",sw / 2,sh  * 0.25,color_white,1)
	end
end