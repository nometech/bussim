--[[
BUS DEV CONTROL - STUDIO INSTALLER v2
=====================================
Use only in a Roblox experience/place you own or are authorized to test.

IMPORTANT:
- Run this in Roblox Studio -> View -> Command Bar while NOT in Play mode.
- After it prints "INSTALLED", press Play.
- UI is installed under StarterGui so it appears immediately for LocalPlayer.
- RightShift toggles the UI.
- Master key: SEPDEPTRAI
]]

local ServerScriptService = game:GetService("ServerScriptService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function ensureFolder(parent, name)
	local obj = parent:FindFirstChild(name)
	if obj and not obj:IsA("Folder") then
		obj:Destroy()
		obj = nil
	end
	if not obj then
		obj = Instance.new("Folder")
		obj.Name = name
		obj.Parent = parent
	end
	return obj
end

local remoteFolder = ensureFolder(ReplicatedStorage, "BusAdminRemotes")

for _, name in ipairs({"Auth", "SetSpeed", "SetNoClip", "Status"}) do
	local obj = remoteFolder:FindFirstChild(name)
	if obj and not obj:IsA("RemoteEvent") then
		obj:Destroy()
		obj = nil
	end
	if not obj then
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remoteFolder
	end
end

local serverSource = [==[
--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")

local remotes = ReplicatedStorage:WaitForChild("BusAdminRemotes")
local AuthRemote = remotes:WaitForChild("Auth") :: RemoteEvent
local SpeedRemote = remotes:WaitForChild("SetSpeed") :: RemoteEvent
local NoClipRemote = remotes:WaitForChild("SetNoClip") :: RemoteEvent
local StatusRemote = remotes:WaitForChild("Status") :: RemoteEvent

local MASTER_KEY = "SEPDEPTRAI"
local MIN_SPEED = 60
local MAX_SPEED = 300
local NOCLIP_GROUP = "BusAdminNoClip"

local authorized: {[Player]: boolean} = {}

pcall(function()
	PhysicsService:RegisterCollisionGroup(NOCLIP_GROUP)
end)

PhysicsService:CollisionGroupSetCollidable(NOCLIP_GROUP, "Default", false)

local function send(player: Player, ok: boolean, message: string, code: string?)
	StatusRemote:FireClient(player, {
		ok = ok,
		message = message,
		code = code,
	})
end

local function getSeat(player: Player): VehicleSeat?
	local char = player.Character
	if not char then return nil end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return nil end

	local seat = hum.SeatPart
	if seat and seat:IsA("VehicleSeat") then
		return seat
	end

	return nil
end

local function getVehicle(seat: BasePart): Model?
	local node: Instance? = seat
	while node do
		if node:IsA("Model") then
			return node
		end
		node = node.Parent
	end
	return nil
end

local function eachPart(root: Instance, fn: (BasePart) -> ())
	if root:IsA("BasePart") then
		fn(root)
	end

	for _, obj in ipairs(root:GetDescendants()) do
		if obj:IsA("BasePart") then
			fn(obj)
		end
	end
end

local function setNoClip(vehicle: Model, enabled: boolean)
	eachPart(vehicle, function(part)
		if enabled then
			if part:GetAttribute("BusAdminOriginalCollisionGroup") == nil then
				part:SetAttribute("BusAdminOriginalCollisionGroup", part.CollisionGroup)
			end
			part.CollisionGroup = NOCLIP_GROUP
		else
			local original = part:GetAttribute("BusAdminOriginalCollisionGroup")
			if typeof(original) == "string" and original ~= "" then
				part.CollisionGroup = original
			else
				part.CollisionGroup = "Default"
			end
			part:SetAttribute("BusAdminOriginalCollisionGroup", nil)
		end
	end)
end

AuthRemote.OnServerEvent:Connect(function(player, key)
	if typeof(key) ~= "string" then
		send(player, false, "Key không hợp lệ.", "AUTH_INVALID")
		return
	end

	if key == MASTER_KEY then
		authorized[player] = true
		send(player, true, "Đã xác thực quyền DEV.", "AUTH_OK")
	else
		authorized[player] = nil
		send(player, false, "Sai key.", "AUTH_FAILED")
	end
end)

SpeedRemote.OnServerEvent:Connect(function(player, requestedSpeed)
	if not authorized[player] then
		send(player, false, "Chưa xác thực.", "NOT_AUTHORIZED")
		return
	end

	if typeof(requestedSpeed) ~= "number" then
		return
	end

	local seat = getSeat(player)
	if not seat then
		send(player, false, "Chưa ngồi VehicleSeat.", "NO_SEAT")
		return
	end

	local speed = math.clamp(math.floor(requestedSpeed), MIN_SPEED, MAX_SPEED)

	seat.MaxSpeed = speed
	seat:SetAttribute("DevMaxSpeed", speed)

	local vehicle = getVehicle(seat)
	if vehicle then
		vehicle:SetAttribute("DevMaxSpeed", speed)
	end

	send(player, true, ("Tốc độ: %d"):format(speed), "SPEED_OK")
end)

NoClipRemote.OnServerEvent:Connect(function(player, enabled)
	if not authorized[player] then
		send(player, false, "Chưa xác thực.", "NOT_AUTHORIZED")
		return
	end

	if typeof(enabled) ~= "boolean" then
		return
	end

	local seat = getSeat(player)
	if not seat then
		send(player, false, "Chưa ngồi VehicleSeat.", "NO_SEAT")
		return
	end

	local vehicle = getVehicle(seat)
	if not vehicle then
		send(player, false, "Không tìm thấy model xe.", "NO_MODEL")
		return
	end

	setNoClip(vehicle, enabled)

	send(
		player,
		true,
		enabled and "No-clip xe: ON" or "No-clip xe: OFF",
		enabled and "NOCLIP_ON" or "NOCLIP_OFF"
	)
end)

Players.PlayerRemoving:Connect(function(player)
	authorized[player] = nil
end)

print("[BusAdmin] Server ready")
]==]

local clientSource = [==[
--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = script.Parent

assert(gui:IsA("ScreenGui"), "BusAdmin client must be inside ScreenGui")

gui.Enabled = true
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local old = gui:FindFirstChild("Main")
if old then
	old:Destroy()
end

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(400, 440)
main.Position = UDim2.new(0, 24, 0.5, -220)
main.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
main.BorderSizePixel = 0
main.ZIndex = 10
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 18)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(75, 84, 115)
stroke.Transparency = 0.25
stroke.Thickness = 1
stroke.Parent = main

local function label(text, pos, size, font, textSize, color)
	local o = Instance.new("TextLabel")
	o.BackgroundTransparency = 1
	o.Text = text
	o.Position = pos
	o.Size = size
	o.Font = font or Enum.Font.Gotham
	o.TextSize = textSize or 14
	o.TextColor3 = color or Color3.new(1,1,1)
	o.TextXAlignment = Enum.TextXAlignment.Left
	o.ZIndex = 11
	o.Parent = main
	return o
end

local function button(text, pos, size)
	local o = Instance.new("TextButton")
	o.Text = text
	o.Position = pos
	o.Size = size
	o.BackgroundColor3 = Color3.fromRGB(36, 40, 54)
	o.TextColor3 = Color3.fromRGB(245,245,250)
	o.Font = Enum.Font.GothamBold
	o.TextSize = 14
	o.AutoButtonColor = false
	o.ZIndex = 11
	o.Parent = main
	Instance.new("UICorner", o).CornerRadius = UDim.new(0, 11)
	return o
end

local title = label(
	"BUS DEV CONTROL",
	UDim2.fromOffset(20, 14),
	UDim2.new(1, -80, 0, 32),
	Enum.Font.GothamBold,
	21,
	Color3.fromRGB(245,247,255)
)
title.Active = true

label(
	"Studio / private QA panel",
	UDim2.fromOffset(20, 46),
	UDim2.new(1, -40, 0, 22),
	Enum.Font.Gotham,
	12,
	Color3.fromRGB(135,140,160)
)

local close = button("×", UDim2.new(1,-58,0,14), UDim2.fromOffset(38,38))
close.TextSize = 24

local keyBox = Instance.new("TextBox")
keyBox.Position = UDim2.fromOffset(20, 88)
keyBox.Size = UDim2.new(1, -40, 0, 48)
keyBox.BackgroundColor3 = Color3.fromRGB(24,27,36)
keyBox.TextColor3 = Color3.fromRGB(245,245,250)
keyBox.PlaceholderText = "Nhập key..."
keyBox.PlaceholderColor3 = Color3.fromRGB(105,110,125)
keyBox.Text = ""
keyBox.ClearTextOnFocus = false
keyBox.Font = Enum.Font.GothamMedium
keyBox.TextSize = 15
keyBox.ZIndex = 11
keyBox.Parent = main
Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0,11)

local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0,14)
pad.PaddingRight = UDim.new(0,14)
pad.Parent = keyBox

local authButton = button(
	"XÁC THỰC",
	UDim2.fromOffset(20, 146),
	UDim2.new(1,-40,0,44)
)
authButton.BackgroundColor3 = Color3.fromRGB(68,88,255)

local speed = 120
local speedLabel = label(
	"Tốc độ: 120",
	UDim2.fromOffset(20, 215),
	UDim2.new(1,-40,0,24),
	Enum.Font.GothamMedium,
	15,
	Color3.fromRGB(235,237,248)
)

local minus = button("-", UDim2.fromOffset(20,250), UDim2.fromOffset(72,42))
minus.TextSize = 22

local apply = button("ÁP DỤNG", UDim2.fromOffset(104,250), UDim2.new(1,-208,0,42))

local plus = button("+", UDim2.new(1,-92,0,250), UDim2.fromOffset(72,42))
plus.TextSize = 22

local noclip = button(
	"NO-CLIP XE: OFF",
	UDim2.fromOffset(20,312),
	UDim2.new(1,-40,0,48)
)

local status = label(
	"UI đã tải. Chưa xác thực.",
	UDim2.fromOffset(20,378),
	UDim2.new(1,-40,0,24),
	Enum.Font.Gotham,
	13,
	Color3.fromRGB(160,165,185)
)

label(
	"RightShift: Ẩn / hiện UI",
	UDim2.fromOffset(20,409),
	UDim2.new(1,-40,0,18),
	Enum.Font.Gotham,
	11,
	Color3.fromRGB(95,100,118)
)

local authenticated = false
local noclipEnabled = false

local remotes = ReplicatedStorage:FindFirstChild("BusAdminRemotes")

if not remotes then
	status.Text = "Lỗi: không tìm thấy BusAdminRemotes."
	status.TextColor3 = Color3.fromRGB(255,100,100)
	return
end

local AuthRemote = remotes:WaitForChild("Auth", 5)
local SpeedRemote = remotes:WaitForChild("SetSpeed", 5)
local NoClipRemote = remotes:WaitForChild("SetNoClip", 5)
local StatusRemote = remotes:WaitForChild("Status", 5)

if not (AuthRemote and SpeedRemote and NoClipRemote and StatusRemote) then
	status.Text = "Lỗi: thiếu RemoteEvent."
	status.TextColor3 = Color3.fromRGB(255,100,100)
	return
end

local function setButtonColor(btn, color)
	TweenService:Create(
		btn,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad),
		{BackgroundColor3 = color}
	):Play()
end

authButton.MouseButton1Click:Connect(function()
	if keyBox.Text == "" then
		status.Text = "Nhập key trước."
		return
	end
	status.Text = "Đang xác thực..."
	AuthRemote:FireServer(keyBox.Text)
end)

keyBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		authButton:Activate()
	end
end)

minus.MouseButton1Click:Connect(function()
	speed = math.max(60, speed - 20)
	speedLabel.Text = "Tốc độ: " .. speed
end)

plus.MouseButton1Click:Connect(function()
	speed = math.min(300, speed + 20)
	speedLabel.Text = "Tốc độ: " .. speed
end)

apply.MouseButton1Click:Connect(function()
	if not authenticated then
		status.Text = "Chưa xác thực."
		return
	end
	SpeedRemote:FireServer(speed)
end)

noclip.MouseButton1Click:Connect(function()
	if not authenticated then
		status.Text = "Chưa xác thực."
		return
	end

	noclipEnabled = not noclipEnabled
	noclip.Text = noclipEnabled and "NO-CLIP XE: ON" or "NO-CLIP XE: OFF"
	setButtonColor(
		noclip,
		noclipEnabled and Color3.fromRGB(42,145,84) or Color3.fromRGB(36,40,54)
	)

	NoClipRemote:FireServer(noclipEnabled)
end)

close.MouseButton1Click:Connect(function()
	gui.Enabled = false
end)

StatusRemote.OnClientEvent:Connect(function(data)
	if typeof(data) ~= "table" then
		return
	end

	status.Text = tostring(data.message or "")

	if data.code == "AUTH_OK" then
		authenticated = true
		authButton.Text = "ĐÃ XÁC THỰC"
		keyBox.Text = ""
		setButtonColor(authButton, Color3.fromRGB(42,145,84))
	elseif data.code == "AUTH_FAILED" then
		authenticated = false
		authButton.Text = "XÁC THỰC"
		setButtonColor(authButton, Color3.fromRGB(180,55,65))
	end
end)

-- Dragging
local dragging = false
local dragStart: Vector2? = nil
local startPos: UDim2? = nil

title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging or not dragStart or not startPos then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseMovement
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local delta = input.Position - dragStart
	main.Position = UDim2.new(
		startPos.X.Scale,
		startPos.X.Offset + delta.X,
		startPos.Y.Scale,
		startPos.Y.Offset + delta.Y
	)
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.RightShift then
		gui.Enabled = not gui.Enabled
	end
end)

print("[BusAdmin] UI loaded for", player.Name)
]==]

local function replaceSourceScript(parent, className, name, source)
	local old = parent:FindFirstChild(name)
	if old then
		old:Destroy()
	end

	local obj = Instance.new(className)
	obj.Name = name

	local ok, err = pcall(function()
		obj.Source = source
	end)

	if not ok then
		obj:Destroy()
		error(
			"Không thể ghi Source. Hãy chạy installer bằng Roblox Studio Command Bar ở Edit Mode. "
			.. tostring(err)
		)
	end

	obj.Parent = parent
	return obj
end

replaceSourceScript(
	ServerScriptService,
	"Script",
	"BusAdminServer",
	serverSource
)

local oldGui = StarterGui:FindFirstChild("BusDevPanel")
if oldGui then
	oldGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BusDevPanel"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999999
screenGui.Enabled = true
screenGui.Parent = StarterGui

replaceSourceScript(
	screenGui,
	"LocalScript",
	"BusAdminClient",
	clientSource
)

print("==============================================")
print("BUS DEV CONTROL v2 INSTALLED")
print("Key: SEPDEPTRAI")
print("UI: StarterGui/BusDevPanel")
print("Server: ServerScriptService/BusAdminServer")
print("STOP Play mode if active, then press Play again.")
print("==============================================")
