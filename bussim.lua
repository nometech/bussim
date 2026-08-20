--[[
    AXIOM BUS TOOL
    Place as a LocalScript inside:
    StarterPlayer > StarterPlayerScripts

    Requirements:
    - Your bus model should be tagged "Bus" with CollectionService
      OR contain a VehicleSeat.
    - Key: SEPDEPTRAI
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local CONFIG = {
	KEY = "SEPDEPTRAI",

	DEFAULT_BUS_SPEED = 80,
	MAX_BUS_SPEED = 400,
	MIN_BUS_SPEED = 20,

	UI_NAME = "AxiomBusTool"
}

-- =========================================================
-- STATE
-- =========================================================

local State = {
	Authenticated = false,
	Noclip = false,
	SpeedEnabled = false,
	BusSpeed = CONFIG.DEFAULT_BUS_SPEED,

	OriginalCollision = {},
	Connections = {},
}

-- =========================================================
-- UTILS
-- =========================================================

local function addConnection(connection)
	table.insert(State.Connections, connection)
	return connection
end

local function round(number)
	return math.floor(number + 0.5)
end

local function clampSpeed(speed)
	return math.clamp(speed, CONFIG.MIN_BUS_SPEED, CONFIG.MAX_BUS_SPEED)
end

local function findCurrentBus()
	local character = Player.Character
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end

	local seat = humanoid.SeatPart
	if not seat then
		return nil
	end

	local model = seat:FindFirstAncestorOfClass("Model")

	if model then
		return model
	end

	return nil
end

local function getVehicleSeat(bus)
	if not bus then
		return nil
	end

	for _, obj in ipairs(bus:GetDescendants()) do
		if obj:IsA("VehicleSeat") then
			return obj
		end
	end

	return nil
end

local function notify(title, message)
	local StarterGui = game:GetService("StarterGui")

	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = message,
			Duration = 3
		})
	end)
end

-- =========================================================
-- NOCLIP
-- =========================================================

local function enableNoclip(bus)
	if not bus then
		return
	end

	for _, part in ipairs(bus:GetDescendants()) do
		if part:IsA("BasePart") then

			if State.OriginalCollision[part] == nil then
				State.OriginalCollision[part] = part.CanCollide
			end

			part.CanCollide = false
		end
	end
end

local function restoreCollision()
	for part, originalValue in pairs(State.OriginalCollision) do
		if part and part.Parent then
			part.CanCollide = originalValue
		end
	end

	table.clear(State.OriginalCollision)
end

-- =========================================================
-- BUS SPEED
-- =========================================================

local function applyBusSpeed(bus)
	local vehicleSeat = getVehicleSeat(bus)

	if vehicleSeat then
		vehicleSeat.MaxSpeed = State.BusSpeed
	end
end

-- =========================================================
-- MAIN LOOP
-- =========================================================

addConnection(
	RunService.Heartbeat:Connect(function()

		if not State.Authenticated then
			return
		end

		local bus = findCurrentBus()

		if not bus then
			return
		end

		if State.Noclip then
			enableNoclip(bus)
		end

		if State.SpeedEnabled then
			applyBusSpeed(bus)
		end
	end)
)

-- =========================================================
-- GUI
-- =========================================================

local oldGui = PlayerGui:FindFirstChild(CONFIG.UI_NAME)

if oldGui then
	oldGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = CONFIG.UI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

-- MAIN
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(460, 330)
Main.Position = UDim2.new(
	0.5,
	-230,
	0.5,
	-165
)

Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(70, 70, 90)
Stroke.Thickness = 1
Stroke.Transparency = 0.2
Stroke.Parent = Main

-- HEADER
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 48)
Header.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
Header.BorderSizePixel = 0
Header.Parent = Main

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 14)
HeaderCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.fromOffset(16, 0)
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextColor3 = Color3.fromRGB(240, 240, 245)
Title.Text = "AXIOM BUS TOOL"
Title.Parent = Header

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(36, 36)
Close.Position = UDim2.new(1, -42, 0, 6)
Close.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
Close.Text = "×"
Close.TextSize = 25
Close.TextColor3 = Color3.new(1, 1, 1)
Close.Font = Enum.Font.GothamBold
Close.BorderSizePixel = 0
Close.Parent = Header

Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 8)

Close.MouseButton1Click:Connect(function()
	restoreCollision()
	ScreenGui:Destroy()
end)

-- =========================================================
-- DRAGGING
-- =========================================================

do
	local dragging = false
	local dragStart
	local startPosition

	Header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			dragging = true
			dragStart = input.Position
			startPosition = Main.Position
		end
	end)

	Header.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local delta = input.Position - dragStart

		Main.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end)
end

-- =========================================================
-- LOGIN PAGE
-- =========================================================

local LoginPage = Instance.new("Frame")
LoginPage.Size = UDim2.new(1, -30, 1, -70)
LoginPage.Position = UDim2.fromOffset(15, 60)
LoginPage.BackgroundTransparency = 1
LoginPage.Parent = Main

local KeyTitle = Instance.new("TextLabel")
KeyTitle.Size = UDim2.new(1, 0, 0, 40)
KeyTitle.BackgroundTransparency = 1
KeyTitle.Text = "Nhập key"
KeyTitle.Font = Enum.Font.GothamBold
KeyTitle.TextSize = 23
KeyTitle.TextColor3 = Color3.fromRGB(235, 235, 240)
KeyTitle.Parent = LoginPage

local KeyBox = Instance.new("TextBox")
KeyBox.Size = UDim2.new(1, -40, 0, 48)
KeyBox.Position = UDim2.new(0, 20, 0, 65)
KeyBox.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
KeyBox.BorderSizePixel = 0
KeyBox.PlaceholderText = "Key..."
KeyBox.Text = ""
KeyBox.ClearTextOnFocus = false
KeyBox.TextColor3 = Color3.new(1, 1, 1)
KeyBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
KeyBox.Font = Enum.Font.Gotham
KeyBox.TextSize = 17
KeyBox.Parent = LoginPage

Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0, 10)

local Login = Instance.new("TextButton")
Login.Size = UDim2.new(1, -40, 0, 48)
Login.Position = UDim2.new(0, 20, 0, 125)
Login.BackgroundColor3 = Color3.fromRGB(65, 90, 255)
Login.Text = "UNLOCK"
Login.TextColor3 = Color3.new(1, 1, 1)
Login.Font = Enum.Font.GothamBold
Login.TextSize = 16
Login.BorderSizePixel = 0
Login.Parent = LoginPage

Instance.new("UICorner", Login).CornerRadius = UDim.new(0, 10)

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, 0, 0, 35)
Status.Position = UDim2.new(0, 0, 0, 185)
Status.BackgroundTransparency = 1
Status.Text = "Key: SEPDEPTRAI"
Status.TextColor3 = Color3.fromRGB(145, 145, 160)
Status.Font = Enum.Font.Gotham
Status.TextSize = 14
Status.Parent = LoginPage

-- =========================================================
-- TOOL PAGE
-- =========================================================

local ToolPage = Instance.new("Frame")
ToolPage.Size = LoginPage.Size
ToolPage.Position = LoginPage.Position
ToolPage.BackgroundTransparency = 1
ToolPage.Visible = false
ToolPage.Parent = Main

local function createButton(text, y)
	local button = Instance.new("TextButton")

	button.Size = UDim2.new(1, -40, 0, 42)
	button.Position = UDim2.new(0, 20, 0, y)
	button.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
	button.BorderSizePixel = 0

	button.Text = text
	button.TextColor3 = Color3.fromRGB(230, 230, 235)
	button.Font = Enum.Font.GothamSemibold
	button.TextSize = 15

	button.Parent = ToolPage

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = button

	return button
end

local SpeedToggle = createButton(
	"Unlock Bus Speed: OFF",
	0
)

local NoclipToggle = createButton(
	"Bus Noclip: OFF",
	52
)

local SpeedMinus = createButton(
	"- 20 Speed",
	104
)

SpeedMinus.Size = UDim2.new(0.5, -25, 0, 42)

local SpeedPlus = createButton(
	"+ 20 Speed",
	104
)

SpeedPlus.Size = UDim2.new(0.5, -25, 0, 42)
SpeedPlus.Position = UDim2.new(0.5, 5, 0, 104)

local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(1, -40, 0, 40)
SpeedLabel.Position = UDim2.new(0, 20, 0, 156)
SpeedLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
SpeedLabel.BorderSizePixel = 0

SpeedLabel.Text =
	"Bus Speed: " .. State.BusSpeed

SpeedLabel.TextColor3 =
	Color3.fromRGB(245, 245, 250)

SpeedLabel.Font =
	Enum.Font.GothamBold

SpeedLabel.TextSize = 16
SpeedLabel.Parent = ToolPage

Instance.new(
	"UICorner",
	SpeedLabel
).CornerRadius = UDim.new(0, 9)

local ResetButton = createButton(
	"RESET BUS SETTINGS",
	208
)

-- =========================================================
-- LOGIN LOGIC
-- =========================================================

local function authenticate()
	local enteredKey =
		string.upper(
			string.gsub(
				KeyBox.Text,
				"%s+",
				""
			)
		)

	if enteredKey == CONFIG.KEY then

		State.Authenticated = true

		Status.Text = "✓ ACCESS GRANTED"
		Status.TextColor3 =
			Color3.fromRGB(80, 255, 140)

		task.wait(0.25)

		LoginPage.Visible = false
		ToolPage.Visible = true

		notify(
			"Axiom Bus Tool",
			"Key accepted."
		)

	else

		Status.Text = "✕ KEY KHÔNG HỢP LỆ"
		Status.TextColor3 =
			Color3.fromRGB(255, 80, 80)

		local original =
			KeyBox.Position

		for _ = 1, 3 do

			KeyBox.Position =
				original +
				UDim2.fromOffset(5, 0)

			task.wait(0.04)

			KeyBox.Position =
				original -
				UDim2.fromOffset(5, 0)

			task.wait(0.04)
		end

		KeyBox.Position = original
	end
end

Login.MouseButton1Click:Connect(
	authenticate
)

KeyBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		authenticate()
	end
end)

-- =========================================================
-- BUTTON LOGIC
-- =========================================================

SpeedToggle.MouseButton1Click:Connect(function()

	State.SpeedEnabled =
		not State.SpeedEnabled

	if State.SpeedEnabled then

		SpeedToggle.Text =
			"Unlock Bus Speed: ON"

	else

		SpeedToggle.Text =
			"Unlock Bus Speed: OFF"

	end

end)

NoclipToggle.MouseButton1Click:Connect(function()

	State.Noclip =
		not State.Noclip

	if State.Noclip then

		NoclipToggle.Text =
			"Bus Noclip: ON"

	else

		NoclipToggle.Text =
			"Bus Noclip: OFF"

		restoreCollision()

	end

end)

SpeedPlus.MouseButton1Click:Connect(function()

	State.BusSpeed =
		clampSpeed(
			State.BusSpeed + 20
		)

	SpeedLabel.Text =
		"Bus Speed: "
		.. round(State.BusSpeed)

end)

SpeedMinus.MouseButton1Click:Connect(function()

	State.BusSpeed =
		clampSpeed(
			State.BusSpeed - 20
		)

	SpeedLabel.Text =
		"Bus Speed: "
		.. round(State.BusSpeed)

end)

ResetButton.MouseButton1Click:Connect(function()

	State.Noclip = false
	State.SpeedEnabled = false

	State.BusSpeed =
		CONFIG.DEFAULT_BUS_SPEED

	restoreCollision()

	SpeedToggle.Text =
		"Unlock Bus Speed: OFF"

	NoclipToggle.Text =
		"Bus Noclip: OFF"

	SpeedLabel.Text =
		"Bus Speed: "
		.. State.BusSpeed

	local bus = findCurrentBus()
	local seat = getVehicleSeat(bus)

	if seat then
		seat.MaxSpeed =
			CONFIG.DEFAULT_BUS_SPEED
	end

	notify(
		"Axiom Bus Tool",
		"Settings reset."
	)

end)

-- =========================================================
-- KEYBOARD UI TOGGLE
-- RightShift = Hide / Show
-- =========================================================

UserInputService.InputBegan:Connect(function(input, processed)

	if processed then
		return
	end

	if input.KeyCode ==
		Enum.KeyCode.RightShift then

		Main.Visible =
			not Main.Visible
	end

end)
