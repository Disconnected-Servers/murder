local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local surface_DrawOutlinedRect = surface.DrawOutlinedRect
local surface_setmaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect
local draw_DrawText = draw.DrawText
local IsValid = IsValid
local team_GetColor = team.GetColor
local CurTime = CurTime
local Color = Color
local pairs = pairs

local menu
local playerData

local talking = Material("icon32/unmuted.png")
local muted = Material("icon32/muted.png")
local admin = Material("icon32/wand.png")

local function addPlayerItem(self, mlist, ply, pteam)
	local but = vgui.Create("DButton")
	but.player = ply
	but.ctime = CurTime()
	but:SetTall(40)
	but:SetText("")
	function but:Paint(w, h)
		local showAdmins = GetConVarNumber("mu_scoreboard_show_admins") ~=  0

		local col = team_GetColor(pteam)
		if IsValid(ply) then
			col = ply:GetPlayerColor()
			col = Color(col.x * 255, col.y * 255, col.z * 255)
		end
		surface_SetDrawColor(col)
		surface_DrawRect(0, 0, w, h)

		surface_SetDrawColor(255,255,255,10)
		surface_DrawRect(0, 0, w, h * 0.45 )

		surface_SetDrawColor(color_black)
		surface_DrawOutlinedRect(0, 0, w, h)

		if IsValid(ply) and ply:IsPlayer() then
			local s = 0

			if showAdmins and ply:IsAdmin() then
				surface_SetMaterial(admin)
				surface_SetDrawColor(color_white)
				surface_DrawTexturedRect(s + 4, h / 2 - 16, 32, 32)
				s = s + 32
			end

			if ply:IsSpeaking() then
				surface_SetMaterial(talking)
				surface_SetDrawColor(color_white)
				surface_DrawTexturedRect(s + 4, h / 2 - 16, 32, 32)
				s = s + 32
			end

			if ply:IsMuted() then
				surface_SetMaterial(muted)
				surface_SetDrawColor(color_white)
				surface_DrawTexturedRect(s + 4, h / 2 - 16, 32, 32)
				s = s + 32
			end

			draw_DrawText(ply:Ping(), "ScoreboardPlayer", w - 9, 9, color_black, 2)
			draw_DrawText(ply:Ping(), "ScoreboardPlayer", w - 10, 8, color_white, 2)

			draw_DrawText(ply:Nick(), "ScoreboardPlayer", s + 11, 9, color_black, 0)
			draw_DrawText(ply:Nick(), "ScoreboardPlayer", s + 10, 8, color_white, 0)

			draw_DrawText(ply:GetBystanderName(), "ScoreboardPlayer", w * 0.4 + 1, 9, color_black, 0)
			draw_DrawText(ply:GetBystanderName(), "ScoreboardPlayer", w * 0.4, 8, color_white, 0)

			local status = translate.bystander
			local statusColor = team_GetColor(2)
			if not  ply:Alive() then
				status = translate.playerStatusDead
				statusColor = Color(120,120,120)
			elseif playerData and playerData.players[ply:EntIndex()] and playerData.players[ply:EntIndex()].murderer then
				status = translate.murderer
				statusColor = Color(190, 20, 20)
			end

			draw_DrawText(status, "ScoreboardPlayer", w * 0.64 + 1, 9, color_black, 0)
			draw_DrawText(status, "ScoreboardPlayer", w * 0.64, 8, statusColor, 0)

			local chance = "?"
			if playerData and playerData.players[ply:EntIndex()] then
				chance = math.Round(playerData.players[ply:EntIndex()].murdererChance * 100) .. "%"
			end
			draw_DrawText(chance, "ScoreboardPlayer", w * 0.86 + 1, 9, color_black, 0)
			draw_DrawText(chance, "ScoreboardPlayer", w * 0.86, 8, color_white, 0)
			
		end
	end
	function but:DoClick()
		GAMEMODE:DoScoreboardActionPopup(ply)
	end

	mlist:AddItem(but)
end

local function doPlayerItems(self, mlist, pteam)

	for k, ply in pairs(team.GetPlayers(pteam)) do
		local found = false

		for t,v in pairs(mlist:GetCanvas():GetChildren()) do
			if v.player == ply then
				found = true
				v.ctime = CurTime()
			end
		end

		if not  found then
			addPlayerItem(self, mlist, ply, pteam)
		end
	end
	local del = false

	for t,v in pairs(mlist:GetCanvas():GetChildren()) do
		if v.ctime ~=  CurTime() then
			v:Remove()
			del = true
		end
	end
	-- make sure the rest of the elements are moved up
	if del then
		timer.Simple(0, function() mlist:GetCanvas():InvalidateLayout() end)
	end
end

local function makeTeamList(parent, pteam)
	local mlist
	local chaos
	local pnl = vgui.Create("DPanel", parent)
	pnl:DockPadding(8,8,8,8)
	function pnl:Paint(w, h) 
		surface_SetDrawColor(Color(50,50,50,255))
		surface_DrawRect(2, 2, w - 4, h - 4)
	end

	function pnl:Think()
		if not  self.RefreshWait or self.RefreshWait < CurTime() then
			self.RefreshWait = CurTime() + 0.1
			doPlayerItems(self, mlist, pteam)

			-- update chaos/control
			if pteam == 2 then
				-- chaos:SetText("Control: " .. GAMEMODE:GetControl())
			else
				-- chaos:SetText("Chaos: " .. GAMEMODE:GetChaos())
			end
		end
	end

	local headp = vgui.Create("DPanel", pnl)
	headp:DockMargin(0,0,0,4)
	-- headp:DockPadding(4,0,4,0)
	headp:Dock(TOP)
	function headp:Paint(w, h)
		draw_DrawText(translate.scoreboardPing, "ScoreboardPlayer", w - 9, 2, color_black, 2)
		draw_DrawText(translate.scoreboardPing, "ScoreboardPlayer", w - 10, 2, color_white, 2)

		draw_DrawText(translate.scoreboardBystanderName, "ScoreboardPlayer", w * 0.4 + 1, 2, color_black, 0)
		draw_DrawText(translate.scoreboardBystanderName, "ScoreboardPlayer", w * 0.4, 2, color_white, 0)

		draw_DrawText(translate.scoreboardStatus, "ScoreboardPlayer", w * 0.64 + 1, 2, color_black, 0)
		draw_DrawText(translate.scoreboardStatus, "ScoreboardPlayer", w * 0.64, 2, color_white, 0)

		draw_DrawText(translate.scoreboardChance, "ScoreboardPlayer", w * 0.86 + 1, 2, color_black, 0)
		draw_DrawText(translate.scoreboardChance, "ScoreboardPlayer", w * 0.86, 2, color_white, 0)

		draw_DrawText(translate.scoreboardName, "ScoreboardPlayer", 11, 2, color_black, 0)
		draw_DrawText(translate.scoreboardName, "ScoreboardPlayer", 10, 2, color_white, 0)
	end

	function headp:PerformLayout()
		local h = draw.GetFontHeight("ScoreboardPlayer")
		self:SetTall(h)
	end

	-- local head = vgui.Create("DLabel", headp)
	-- head:SetText(team.GetName(pteam))
	-- head:SetFont("Trebuchet24")
	-- head:SetTextColor(team_GetColor(pteam))
	-- head:Dock(FILL)


	mlist = vgui.Create("DScrollPanel", pnl)
	mlist:Dock(FILL)

	-- child positioning
	local canvas = mlist:GetCanvas()
	function canvas:OnChildAdded( child )
		child:Dock( TOP )
		child:DockMargin( 0,0,0,4 )
	end

	return pnl
end


net.Receive("mu_adminpanel_details", function (ply, length)
	local json = net.ReadString()
	local tab = util.JSONToTable(json)

	playerData = tab
	-- PrintTable(tab)
end)


concommand.Add("mu_adminpanel", function (client)
	if not  client:IsSuperAdmin() then return end
	local canUse = GAMEMODE.RoundSettings.AdminPanelAllowed
	if not  canUse then return end

	if IsValid(menu) then
		menu:SetVisible(true)
	else
		menu = vgui.Create("DFrame")
		menu:SetSize(ScrW() * 0.9, ScrH() * 0.9)
		menu:Center()
		menu:MakePopup()
		menu:SetKeyboardInputEnabled(false)
		menu:SetDeleteOnClose(false)
		menu:SetDraggable(true)
		menu:ShowCloseButton(true)
		menu:SetTitle(translate.adminPanel)
		function menu:PerformLayout()
			if menu.Players then
				menu.Players:SetWidth(self:GetWide() * 0.5)
			end
		end

		local refresh = vgui.Create("DButton", menu)
		refresh:Dock(TOP)
		refresh:SetText(translate.scoreboardRefresh)
		refresh:SetTextColor(color_white)
		refresh:SetFont("Trebuchet18")
		function refresh:DoClick()
			net.Start("mu_adminpanel_details")
			net.SendToServer()
		end
		function refresh:Paint(w, h)
			surface_SetDrawColor(team_GetColor(2))
			surface_DrawRect(0, 0, w, h)

			surface_SetDrawColor(255,255,255,10)
			surface_DrawRect(0, 0, w, h * 0.45 )

			surface_SetDrawColor(color_black)
			surface_DrawOutlinedRect(0, 0, w, h)

			if self:IsDown() then
				surface_SetDrawColor(50,50,50,120)
				surface_DrawRect(1, 1, w - 2, h - 2)
			elseif self:IsHovered() then
				surface_SetDrawColor(255,255,255,30)
				surface_DrawRect(1, 1, w - 2, h - 2)
			end
		end

		function menu:Paint()
			surface_SetDrawColor(Color(40,40,40,255))
			surface_DrawRect(0, 0, menu:GetWide(), menu:GetTall())
		end

		menu.Players = makeTeamList(menu, 2)
		menu.Players:Dock(FILL)

	end
	
	net.Start("mu_adminpanel_details")
	net.SendToServer()
end)

