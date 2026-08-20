--!strict
-- BusDevUI_LocalScript.lua
-- Put THIS FILE CONTENT directly inside a LocalScript at:
-- StarterPlayer > StarterPlayerScripts
-- Then press Play.
--
-- Intended for a Roblox experience/place you own or are authorized to test.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("[BusDevUI] LocalScript started for:", player.Name)

-- Clean previous copy
local oldGui = playerGui:FindFirstChild("BusDevPanel")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "BusDevPanel"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Enabled = true
gui.DisplayOrder = 999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(420, 470)
main.Position = UDim2.new(0.5, -210, 0.5, -235)
main.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
main.BorderSizePixel = 0
main.ZIndex = 10
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 18)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(85, 95, 135)
mainStroke.Transparency = 0.25
mainStroke.Thickness = 1
mainStroke.Parent = main

local topGlow = Instance.new("Frame")
topGlow.Name = "TopGlow"
topGlow.Size = UDim2.new(1, 0, 0, 4)
topGlow.Position = UDim2.new(0, 0, 0, 0)
topGlow.BackgroundColor3 = Color3.fromRGB(87, 105, 255)
topGlow.BorderSizePixel = 0
topGlow.ZIndex = 11
topGlow.Parent = main

local topGlowCorner = Instance.new("UICorner")
topGlowCorner.CornerRadius = UDim.new(0, 18)
topGlowCorner.Parent = topGlow

local function makeLabel(
	text: string,
	x: number,
	y: number,
	w: number,
	h: number,
	size: number,
	bold: boolean?,
	color: Color3?
)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(x, y)
	label.Size = UDim2.fromOffset(w, h)
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(240, 242, 250)
	label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	label.TextSize = size
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 12
	label.Parent = main
	return label
end

local function makeButton(
	text: string,
	x: number,
	y: number,
	w: number,
	h: number
)
	local button = Instance.new("TextButton")
	button.Position = UDim2.fromOffset(x, y)
	button.Size = UDim2.fromOffset(w, h)
	button.BackgroundColor3 = Color3.fromRGB(35, 39, 52)
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(245, 245, 250)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.AutoButtonColor = false
	button.ZIndex = 12
	button.Parent = main

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 11)
	corner.Parent = button

	return button
end

local title = makeLabel(
	"BUS DEV CONTROL",
	22, 18, 300, 30,
	22, true
)
title.Active = true

makeLabel(
	"LocalScript UI build • private QA",
	22, 52, 320, 22,
	12, false,
	Color3.fromRGB(140, 145, 165)
)

local closeButton = makeButton("×", 360, 16, 40, 40)
closeButton.TextSize = 24

local keyBox = Instance.new("TextBox")
keyBox.Position = UDim2.fromOffset(22, 92)
keyBox.Size = UDim2.fromOffset(376, 48)
keyBox.BackgroundColor3 = Color3.fromRGB(24, 27, 37)
keyBox.BorderSizePixel = 0
keyBox.TextColor3 = Color3.fromRGB(245, 245, 250)
keyBox.PlaceholderText = "Nhập key..."
keyBox.PlaceholderColor3 = Color3.fromRGB(100, 105, 120)
keyBox.Text = ""
keyBox.ClearTextOnFocus = false
keyBox.Font = Enum.Font.GothamMedium
keyBox.TextSize = 15
keyBox.ZIndex = 12
keyBox.Parent = main

local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0, 11)
keyCorner.Parent = keyBox

local keyPadding = Instance.new("UIPadding")
keyPadding.PaddingLeft = UDim.new(0, 14)
keyPadding.PaddingRight = UDim.new(0, 14)
keyPadding.Parent = keyBox

local authButton = makeButton("XÁC THỰC", 22, 152, 376, 46)
authButton.BackgroundColor3 = Color3.fromRGB(68, 88, 255)

local speed = 120
local speedLabel = makeLabel(
	"Tốc độ: 120",
	22, 220, 200, 24,
	15, true
)

local minusButton = makeButton("-", 22, 255, 76, 44)
minusButton.TextSize = 22

local applyButton = makeButton("ÁP DỤNG", 110, 255, 200, 44)

local plusButton = makeButton("+", 322, 255, 76, 44)
plusButton.TextSize = 22

local noClipButton = makeButton("NO-CLIP XE: OFF", 22, 320, 376, 50)

local statusLabel = makeLabel(
	"UI đã hiển thị. Chưa xác thực.",
	22, 392, 376, 24,
	13, false,
	Color3.fromRGB(160, 166, 188)
)

local hintLabel = makeLabel(
	"RightShift: Ẩn / hiện UI",
	22, 425, 376, 18,
	11, false,
	Color3.fromRGB(92, 98, 118)
)

local authenticated = false
local noClipEnabled = false

local function tweenColor(button: GuiButton, color: Color3)
	TweenService:Create(
		button,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundColor3 = color}
	):Play()
end

-- Optional remotes.
-- The UI still appears even if the server system does not exist.
local remotes = ReplicatedStorage:FindFirstChild("BusAdminRemotes")

local AuthRemote: RemoteEvent? = nil
local SpeedRemote: RemoteEvent? = nil
local NoClipRemote: RemoteEvent? = nil
local StatusRemote: RemoteEvent? = nil

if remotes then
	local a = remotes:FindFirstChild("Auth")
	local s = remotes:FindFirstChild("SetSpeed")
	local n = remotes:FindFirstChild("SetNoClip")
	local st = remotes:FindFirstChild("Status")

	if a and a:IsA("RemoteEvent") then AuthRemote = a end
	if s and s:IsA("RemoteEvent") then SpeedRemote = s end
	if n and n:IsA("RemoteEvent") then NoClipRemote = n end
	if st and st:IsA("RemoteEvent") then StatusRemote = st end
else
	statusLabel.Text = "UI OK • chưa có BusAdminRemotes trên server."
end

local function authenticate()
	local key = keyBox.Text

	if key == "" then
		statusLabel.Text = "Nhập key trước."
		return
	end

	-- UI verification for the owner's fixed key.
	if key == "SEPDEPTRAI" then
		authenticated = true
		authButton.Text = "ĐÃ XÁC THỰC"
		tweenColor(authButton, Color3.fromRGB(42, 145, 84))
		statusLabel.Text = "Key hợp lệ. Quyền DEV đã mở."
	else
		authenticated = false
		authButton.Text = "SAI KEY"
		tweenColor(authButton, Color3.fromRGB(180, 55, 65))
		statusLabel.Text = "Sai key."
		return
	end

	if AuthRemote then
		AuthRemote:FireServer(key)
	end
end

authButton.MouseButton1Click:Connect(authenticate)

keyBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		authenticate()
	end
end)

minusButton.MouseButton1Click:Connect(function()
	speed = math.max(60, speed - 20)
	speedLabel.Text = "Tốc độ: " .. tostring(speed)
end)

plusButton.MouseButton1Click:Connect(function()
	speed = math.min(300, speed + 20)
	speedLabel.Text = "Tốc độ: " .. tostring(speed)
end)

applyButton.MouseButton1Click:Connect(function()
	if not authenticated then
		statusLabel.Text = "Chưa xác thực."
		return
	end

	if SpeedRemote then
		SpeedRemote:FireServer(speed)
		statusLabel.Text = "Đã gửi tốc độ lên server: " .. tostring(speed)
	else
		statusLabel.Text = "UI OK • chưa có server handler tốc độ."
	end
end)

noClipButton.MouseButton1Click:Connect(function()
	if not authenticated then
		statusLabel.Text = "Chưa xác thực."
		return
	end

	noClipEnabled = not noClipEnabled
	noClipButton.Text = noClipEnabled
		and "NO-CLIP XE: ON"
		or "NO-CLIP XE: OFF"

	tweenColor(
		noClipButton,
		noClipEnabled
			and Color3.fromRGB(42, 145, 84)
			or Color3.fromRGB(35, 39, 52)
	)

	if NoClipRemote then
		NoClipRemote:FireServer(noClipEnabled)
		statusLabel.Text = noClipEnabled and "No-clip: ON" or "No-clip: OFF"
	else
		statusLabel.Text = "UI OK • chưa có server handler no-clip."
	end
end)

if StatusRemote then
	StatusRemote.OnClientEvent:Connect(function(data)
		if typeof(data) ~= "table" then
			return
		end

		statusLabel.Text = tostring(data.message or statusLabel.Text)

		if data.code == "AUTH_OK" then
			authenticated = true
			authButton.Text = "ĐÃ XÁC THỰC"
			tweenColor(authButton, Color3.fromRGB(42, 145, 84))
		end
	end)
end

closeButton.MouseButton1Click:Connect(function()
	gui.Enabled = false
end)

-- Drag window
local dragging = false
local dragStart: Vector2? = nil
local originalPosition: UDim2? = nil

title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
	then
		dragging = true
		dragStart = input.Position
		originalPosition = main.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging or not dragStart or not originalPosition then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseMovement
		and input.UserInputType ~= Enum.UserInputType.Touch
	then
		return
	end

	local delta = input.Position - dragStart

	main.Position = UDim2.new(
		originalPosition.X.Scale,
		originalPosition.X.Offset + delta.X,
		originalPosition.Y.Scale,
		originalPosition.Y.Offset + delta.Y
	)
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
	then
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

print("[BusDevUI] UI created successfully:", gui:GetFullName())
