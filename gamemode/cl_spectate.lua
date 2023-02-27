local IsValid = IsValid
local draw_SimpleText = draw.SimpleText
local ScrW = ScrW
local ScrH = ScrH
local Color = Color

net.Receive("spectating_status", function (length)
	GAMEMODE.SpectateMode = net.ReadInt(8)
	GAMEMODE.Spectating = false
	GAMEMODE.Spectatee = nil
	if GAMEMODE.SpectateMode >= 0 then
		GAMEMODE.Spectating = true
		GAMEMODE.Spectatee = net.ReadEntity()
	end

end)

function GM:IsCSpectating() 
	return self.Spectating
end

function GM:GetCSpectatee() 
	return self.Spectatee
end

function GM:GetCSpectateMode() 
	return self.SpectateMode
end


local function drawTextShadow(t,f,x,y,c,px,py)
	color_black.a = c.a
	draw_SimpleText(t,f,x + 1,y + 1,color_black,px,py)
	draw_SimpleText(t,f,x,y,c,px,py)
	color_black.a = 255
end

function GM:RenderSpectate()
	if self:IsCSpectating() then
		local h = draw.GetFontHeight("MersRadial")
		drawTextShadow(translate.spectating, "MersRadial", ScrW() / 2, ScrH() - 30 - h * 2, color_dblue or Color(20,120,255), 1)

		if IsValid(self:GetCSpectatee()) and self:GetCSpectatee():IsPlayer() then
			
			if IsValid(LocalPlayer()) and LocalPlayer():IsAdmin() then
				drawTextShadow(self:GetCSpectatee():Nick(), "MersRadialSmall", ScrW() / 2, ScrH() - 30 - h, color_dgrey or Color(190, 190, 190), 1)
			end

			if self.DrawGameHUD and GAMEMODE.RoundSettings.ShowSpectateInfo then
				self:DrawGameHUD(self:GetCSpectatee())
			end
		end
	end
end