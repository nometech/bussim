-- AXIOM DRIVING ASSIST UI V2
-- LocalScript -> StarterPlayer/StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local CFG = {
	NormalSpeed = 65,
	SpeedLimit = 50,
	CruiseMinSpeed = 10,
	WarnDistance = 45,
	BrakeDistance = 20,
	RaycastHeight = 2.5,
	SteerAssist = 0.12,
	ToggleKey = Enum.KeyCode.RightShift,
}

local F = {
	Limiter = true,
	Cruise = false,
	AutoBrake = true,
	Warning = true,
	SteerAssist = false,
	Park = false,
}

local seat, vehicle
local cruiseSpeed = 0
local obstacle = math.huge

local function getSeat()
	local c = player.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	local s = h and h.SeatPart
	return s and s:IsA("VehicleSeat") and s or nil
end

local function getVehicle(s)
	if not s then return nil end
	local p = s
	while p and p ~= workspace do
		if p:IsA("Model") and p:FindFirstChildWhichIsA("VehicleSeat", true) == s then
			return p
		end
		p = p.Parent
	end
	return s.Parent
end

local function speed()
	return seat and seat.AssemblyLinearVelocity.Magnitude or 0
end

local function kmh(v)
	return math.floor(v * 1.008 + 0.5)
end

local function park(on)
	if not seat then return end
	F.Park = on
	if on then
		F.Cruise = false
		cruiseSpeed = 0
		seat.MaxSpeed = 0
		if speed() < 4 then
			seat.AssemblyLinearVelocity = Vector3.zero
			seat.AssemblyAngularVelocity = Vector3.zero
		end
	else
		seat.MaxSpeed = CFG.NormalSpeed
	end
end

local function cruise()
	if not seat or F.Park then return end
	if F.Cruise then
		F.Cruise = false
		cruiseSpeed = 0
		return
	end
	local v = speed()
	if v >= CFG.CruiseMinSpeed then
		F.Cruise = true
		cruiseSpeed = v
	end
end

local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude

local function scan()
	if not seat then obstacle = math.huge return end
	local ignore = {}
	if vehicle then table.insert(ignore, vehicle) end
	if player.Character then table.insert(ignore, player.Character) end
	rp.FilterDescendantsInstances = ignore

	local origin = seat.Position + Vector3.new(0, CFG.RaycastHeight, 0)
	local hit = workspace:Raycast(origin, seat.CFrame.LookVector * CFG.WarnDistance, rp)
	obstacle = hit and (hit.Position - origin).Magnitude or math.huge
end

local function autoBrake()
	if not seat or not F.AutoBrake or F.Park or obstacle > CFG.BrakeDistance then return end
	if speed() <= 1 then return end
	F.Cruise = false
	cruiseSpeed = 0
	local factor = math.clamp(obstacle / CFG.BrakeDistance, 0.15, 1)
	seat.AssemblyLinearVelocity *= (0.72 + factor * 0.18)
end

local function steerAssist()
	if not seat or not F.SteerAssist or speed() < 5 then return end
	if math.abs(seat.SteerFloat) < 0.1 then
		local a = seat.AssemblyAngularVelocity
		seat.AssemblyAngularVelocity = Vector3.new(a.X, a.Y * (1 - CFG.SteerAssist), a.Z)
	end
end

-- UI
local old = pg:FindFirstChild("AxiomDriveV2")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "AxiomDriveV2"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9999
gui.Parent = pg

local main = Instance.new("Frame")
main.AnchorPoint = Vector2.new(0, .5)
main.Position = UDim2.new(0, 18, .5, 0)
main.Size = UDim2.fromOffset(390, 520)
main.BackgroundColor3 = Color3.fromRGB(13,15,20)
main.BorderSizePixel = 0
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,18)

local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(68,78,94)
stroke.Transparency = .3

local header = Instance.new("Frame")
header.Size = UDim2.new(1,0,0,64)
header.BackgroundTransparency = 1
header.Active = true
header.Parent = main

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(18,10)
title.Size = UDim2.new(1,-80,0,25)
title.BackgroundTransparency = 1
title.Text = "AXIOM DRIVING ASSIST"
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.TextColor3 = Color3.new(1,1,1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local sub = Instance.new("TextLabel")
sub.Position = UDim2.fromOffset(18,35)
sub.Size = UDim2.new(1,-80,0,16)
sub.BackgroundTransparency = 1
sub.Text = "SYSTEM • ONLINE"
sub.Font = Enum.Font.GothamMedium
sub.TextSize = 11
sub.TextColor3 = Color3.fromRGB(85,235,140)
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.Parent = header

local min = Instance.new("TextButton")
min.Position = UDim2.new(1,-50,0,13)
min.Size = UDim2.fromOffset(34,34)
min.BackgroundColor3 = Color3.fromRGB(29,33,42)
min.Text = "—"
min.TextColor3 = Color3.new(1,1,1)
min.Font = Enum.Font.GothamBold
min.TextSize = 18
min.BorderSizePixel = 0
min.Parent = header
Instance.new("UICorner", min).CornerRadius = UDim.new(0,9)

local tabs = Instance.new("Frame")
tabs.Position = UDim2.fromOffset(16,68)
tabs.Size = UDim2.new(1,-32,0,42)
tabs.BackgroundColor3 = Color3.fromRGB(20,23,30)
tabs.BorderSizePixel = 0
tabs.Parent = main
Instance.new("UICorner", tabs).CornerRadius = UDim.new(0,11)

local function tabButton(text, pos)
	local b = Instance.new("TextButton")
	b.Position = pos
	b.Size = UDim2.new(.5,-6,1,-8)
	b.BackgroundColor3 = Color3.fromRGB(28,31,40)
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.new(1,1,1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.Parent = tabs
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
	return b
end

local tabStatus = tabButton("TRẠNG THÁI", UDim2.fromOffset(4,4))
local tabAssist = tabButton("HỖ TRỢ", UDim2.new(.5,2,0,4))

local statusPage = Instance.new("Frame")
statusPage.Position = UDim2.fromOffset(16,122)
statusPage.Size = UDim2.new(1,-32,1,-140)
statusPage.BackgroundTransparency = 1
statusPage.Parent = main

local assistPage = Instance.new("ScrollingFrame")
assistPage.Position = statusPage.Position
assistPage.Size = statusPage.Size
assistPage.BackgroundTransparency = 1
assistPage.BorderSizePixel = 0
assistPage.ScrollBarThickness = 4
assistPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
assistPage.CanvasSize = UDim2.new()
assistPage.Visible = false
assistPage.Parent = main
local list = Instance.new("UIListLayout", assistPage)
list.Padding = UDim.new(0,8)

-- Speed card
local speedCard = Instance.new("Frame")
speedCard.Size = UDim2.new(1,0,0,150)
speedCard.BackgroundColor3 = Color3.fromRGB(20,23,30)
speedCard.BorderSizePixel = 0
speedCard.Parent = statusPage
Instance.new("UICorner", speedCard).CornerRadius = UDim.new(0,14)

local speedText = Instance.new("TextLabel")
speedText.Position = UDim2.fromOffset(20,15)
speedText.Size = UDim2.fromOffset(170,70)
speedText.BackgroundTransparency = 1
speedText.Text = "0"
speedText.Font = Enum.Font.GothamBlack
speedText.TextSize = 56
speedText.TextColor3 = Color3.new(1,1,1)
speedText.TextXAlignment = Enum.TextXAlignment.Left
speedText.Parent = speedCard

local unit = Instance.new("TextLabel")
unit.Position = UDim2.fromOffset(24,82)
unit.Size = UDim2.fromOffset(90,20)
unit.BackgroundTransparency = 1
unit.Text = "KM/H"
unit.Font = Enum.Font.GothamMedium
unit.TextSize = 13
unit.TextColor3 = Color3.fromRGB(155,165,180)
unit.TextXAlignment = Enum.TextXAlignment.Left
unit.Parent = speedCard

local gear = Instance.new("TextLabel")
gear.Position = UDim2.new(1,-84,0,20)
gear.Size = UDim2.fromOffset(60,60)
gear.BackgroundColor3 = Color3.fromRGB(35,78,52)
gear.Text = "D"
gear.TextColor3 = Color3.new(1,1,1)
gear.Font = Enum.Font.GothamBlack
gear.TextSize = 28
gear.BorderSizePixel = 0
gear.Parent = speedCard
Instance.new("UICorner", gear).CornerRadius = UDim.new(0,14)

local busName = Instance.new("TextLabel")
busName.Position = UDim2.fromOffset(20,112)
busName.Size = UDim2.new(1,-40,0,20)
busName.BackgroundTransparency = 1
busName.Text = "BUS: WAITING"
busName.Font = Enum.Font.GothamMedium
busName.TextSize = 12
busName.TextColor3 = Color3.fromRGB(185,195,210)
busName.TextXAlignment = Enum.TextXAlignment.Left
busName.Parent = speedCard

-- Warning card
local warnCard = Instance.new("Frame")
warnCard.Position = UDim2.fromOffset(0,164)
warnCard.Size = UDim2.new(1,0,0,82)
warnCard.BackgroundColor3 = Color3.fromRGB(22,25,32)
warnCard.BorderSizePixel = 0
warnCard.Parent = statusPage
Instance.new("UICorner", warnCard).CornerRadius = UDim.new(0,14)

local warnTitle = Instance.new("TextLabel")
warnTitle.Position = UDim2.fromOffset(16,12)
warnTitle.Size = UDim2.new(1,-32,0,22)
warnTitle.BackgroundTransparency = 1
warnTitle.Text = "PHÍA TRƯỚC AN TOÀN"
warnTitle.Font = Enum.Font.GothamBold
warnTitle.TextSize = 13
warnTitle.TextColor3 = Color3.fromRGB(100,235,150)
warnTitle.TextXAlignment = Enum.TextXAlignment.Left
warnTitle.Parent = warnCard

local warnInfo = Instance.new("TextLabel")
warnInfo.Position = UDim2.fromOffset(16,40)
warnInfo.Size = UDim2.new(1,-32,0,22)
warnInfo.BackgroundTransparency = 1
warnInfo.Text = "Khoảng cách vật cản: ---"
warnInfo.Font = Enum.Font.Gotham
warnInfo.TextSize = 12
warnInfo.TextColor3 = Color3.fromRGB(185,195,210)
warnInfo.TextXAlignment = Enum.TextXAlignment.Left
warnInfo.Parent = warnCard

-- Info card
local info = Instance.new("TextLabel")
info.Position = UDim2.fromOffset(0,260)
info.Size = UDim2.new(1,0,0,126)
info.BackgroundColor3 = Color3.fromRGB(20,23,30)
info.BorderSizePixel = 0
info.Text = ""
info.Font = Enum.Font.Code
info.TextSize = 13
info.TextColor3 = Color3.fromRGB(195,205,215)
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.Parent = statusPage
Instance.new("UICorner", info).CornerRadius = UDim.new(0,14)

local btns = {}
local function addToggle(label, key)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1,-5,0,50)
	b.BackgroundColor3 = Color3.fromRGB(28,31,40)
	b.BorderSizePixel = 0
	b.TextColor3 = Color3.new(1,1,1)
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 13
	b.Parent = assistPage
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,11)
	btns[key] = {b=b,label=label}

	b.MouseButton1Click:Connect(function()
		if key == "Cruise" then cruise() else F[key] = not F[key] end
	end)
end

addToggle("Giới hạn tốc độ", "Limiter")
addToggle("Giữ ga Cruise", "Cruise")
addToggle("Tự động phanh", "AutoBrake")
addToggle("Cảnh báo vật cản", "Warning")
addToggle("Hỗ trợ giữ hướng", "SteerAssist")

local parkBtn = Instance.new("TextButton")
parkBtn.Size = UDim2.new(1,-5,0,54)
parkBtn.BackgroundColor3 = Color3.fromRGB(60,47,30)
parkBtn.BorderSizePixel = 0
parkBtn.Text = "PARK / RELEASE P"
parkBtn.TextColor3 = Color3.new(1,1,1)
parkBtn.Font = Enum.Font.GothamBold
parkBtn.TextSize = 14
parkBtn.Parent = assistPage
Instance.new("UICorner", parkBtn).CornerRadius = UDim.new(0,11)

parkBtn.MouseButton1Click:Connect(function()
	if not seat then return end
	if F.Park then park(false) elseif speed() <= 3 then park(true) end
end)

local function refreshButtons()
	for k,d in pairs(btns) do
		local on = F[k]
		d.b.Text = d.label .. "                         " .. (on and "ON" or "OFF")
		d.b.BackgroundColor3 = on and Color3.fromRGB(35,78,52) or Color3.fromRGB(28,31,40)
	end
end

local page = "status"
local function switchPage(which)
	page = which
	statusPage.Visible = which == "status"
	assistPage.Visible = which == "assist"
	tabStatus.BackgroundColor3 = which == "status" and Color3.fromRGB(35,78,52) or Color3.fromRGB(28,31,40)
	tabAssist.BackgroundColor3 = which == "assist" and Color3.fromRGB(35,78,52) or Color3.fromRGB(28,31,40)
end
tabStatus.MouseButton1Click:Connect(function() switchPage("status") end)
tabAssist.MouseButton1Click:Connect(function() switchPage("assist") end)
switchPage("status")

-- minimize
local minimized = false
min.MouseButton1Click:Connect(function()
	minimized = not minimized
	main.Size = minimized and UDim2.fromOffset(390,64) or UDim2.fromOffset(390,520)
	tabs.Visible = not minimized
	if minimized then statusPage.Visible=false assistPage.Visible=false else switchPage(page) end
end)

-- drag
local dragging, dragStart, startPos = false, nil, nil
header.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		dragging=true dragStart=i.Position startPos=main.Position
	end
end)
UIS.InputChanged:Connect(function(i)
	if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
		local d=i.Position-dragStart
		main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
	end
end)
UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging=false end
end)

UIS.InputBegan:Connect(function(i,p)
	if p then return end
	if i.KeyCode == CFG.ToggleKey then
		gui.Enabled = not gui.Enabled
	elseif i.KeyCode == Enum.KeyCode.P then
		if seat then
			if F.Park then park(false) elseif speed() <= 3 then park(true) end
		end
	elseif i.KeyCode == Enum.KeyCode.C then
		cruise()
	end
end)

RunService.RenderStepped:Connect(function(dt)
	local s = getSeat()
	if s ~= seat then
		seat = s
		vehicle = getVehicle(s)
		F.Cruise = false
		F.Park = false
		cruiseSpeed = 0
	end

	if not seat then
		speedText.Text = "0"
		gear.Text = "-"
		busName.Text = "BUS: WAITING"
		warnTitle.Text = "CHƯA KẾT NỐI XE"
		warnTitle.TextColor3 = Color3.fromRGB(180,190,205)
		warnInfo.Text = "Ngồi vào VehicleSeat để kích hoạt."
		info.Text = "\n  PARK       : OFF\n  CRUISE     : OFF\n  LIMITER    : "..(F.Limiter and "ON" or "OFF").."\n  AUTO BRAKE : "..(F.AutoBrake and "ON" or "OFF")
		refreshButtons()
		return
	end

	local v = speed()
	scan()

	if F.Park then
		seat.MaxSpeed = 0
		if v < 3 then seat.AssemblyLinearVelocity = Vector3.zero end
	elseif F.Limiter then
		seat.MaxSpeed = CFG.SpeedLimit
	else
		seat.MaxSpeed = CFG.NormalSpeed
	end

	if F.Cruise and cruiseSpeed > 0 and not F.Park and v < cruiseSpeed then
		local diff = cruiseSpeed - v
		seat.AssemblyLinearVelocity += seat.CFrame.LookVector * diff * dt * 2
	end

	autoBrake()
	steerAssist()

	speedText.Text = tostring(kmh(v))
	gear.Text = F.Park and "P" or "D"
	gear.BackgroundColor3 = F.Park and Color3.fromRGB(115,45,45) or Color3.fromRGB(35,78,52)
	busName.Text = "BUS: "..(vehicle and vehicle.Name or "VEHICLE")

	if not F.Warning then
		warnTitle.Text = "CẢNH BÁO ĐÃ TẮT"
		warnTitle.TextColor3 = Color3.fromRGB(160,170,185)
	elseif obstacle < CFG.BrakeDistance then
		warnTitle.Text = "PHANH • VẬT CẢN RẤT GẦN"
		warnTitle.TextColor3 = Color3.fromRGB(255,95,95)
	elseif obstacle < CFG.WarnDistance then
		warnTitle.Text = "CẢNH BÁO VẬT CẢN"
		warnTitle.TextColor3 = Color3.fromRGB(255,195,90)
	else
		warnTitle.Text = "PHÍA TRƯỚC AN TOÀN"
		warnTitle.TextColor3 = Color3.fromRGB(100,235,150)
	end

	warnInfo.Text = "Khoảng cách vật cản: "..(obstacle < math.huge and math.floor(obstacle).." studs" or "---")

	info.Text =
		"\n  PARK       : "..(F.Park and "ON" or "OFF")..
		"\n  CRUISE     : "..(F.Cruise and kmh(cruiseSpeed).." KM/H" or "OFF")..
		"\n  LIMITER    : "..(F.Limiter and "ON" or "OFF")..
		"\n  AUTO BRAKE : "..(F.AutoBrake and "ON" or "OFF")

	refreshButtons()
end)

player.CharacterAdded:Connect(function()
	seat=nil vehicle=nil cruiseSpeed=0
end)

refreshButtons()
print("[AXIOM DRIVING ASSIST UI V2] ONLINE")
