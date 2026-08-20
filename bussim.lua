--[[
    AXIOM BUS TOOL - NO KEY VERSION

    Đặt LocalScript tại:
    StarterPlayer > StarterPlayerScripts

    Chức năng:
    - UI hiện trực tiếp khi vào game
    - Unlock Bus Speed
    - Tăng / giảm tốc độ
    - Bus Noclip
    - Reset settings
    - RightShift ẩn / hiện UI
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local CONFIG = {
	UI_NAME = "AxiomBusTool",

	DEFAULT_BUS_SPEED = 80,
	MAX_BUS_SPEED = 500,
	MIN_BUS_SPEED = 20,
	SPEED_STEP = 20,
}

local State = {
	Noclip = false,
	SpeedEnabled = false,
	BusSpeed = CONFIG.DEFAULT_BUS_SPEED,

	OriginalCollision = {},
}

-- =========================================================
-- UTILS
-- =========================================================

local function notify(title, text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = 3,
		})
	end)
end

local function getCharacter()
	return Player.Character
		or Player.CharacterAdded:Wait()
end

local function findCurrentBus()
	local character = Player.Character

	if not character then
		return nil
	end

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return nil
	end

	local seat =
		humanoid.SeatPart

	if not seat then
		return nil
	end

	return seat:FindFirstAncestorOfClass("Model")
end

local function getVehicleSeat(bus)
	if not bus then
		return nil
	end

	for _, object in ipairs(bus:GetDescendants()) do
		if object:IsA("VehicleSeat") then
			return object
		end
	end

	return nil
end

local function clampSpeed(value)
	return math.clamp(
		value,
		CONFIG.MIN_BUS_SPEED,
		CONFIG.MAX_BUS_SPEED
	)
end

-- =========================================================
-- COLLISION
-- =========================================================

local function enableNoclip(bus)
	if not bus then
		return
	end

	for _, object in ipairs(bus:GetDescendants()) do
		if object:IsA("BasePart") then

			if State.OriginalCollision[object] == nil then
				State.OriginalCollision[object] =
					object.CanCollide
			end

			object.CanCollide = false
		end
	end
end

local function restoreCollision()
	for part, oldValue in pairs(State.OriginalCollision) do
		if part and part.Parent then
			part.CanCollide = oldValue
		end
	end

	table.clear(State.OriginalCollision)
end

-- =========================================================
-- BUS SPEED
-- =========================================================

local function applyBusSpeed()
	local bus =
		findCurrentBus()

	if not bus then
		return
	end

	local seat =
		getVehicleSeat(bus)

	if seat then
		seat.MaxSpeed =
			State.BusSpeed
	end
end

-- =========================================================
-- MAIN LOOP
-- =========================================================

RunService.Heartbeat:Connect(function()

	local bus =
		findCurrentBus()

	if not bus then
		return
	end

	if State.Noclip then
		enableNoclip(bus)
	end

	if State.SpeedEnabled then
		applyBusSpeed()
	end

end)

-- =========================================================
-- CLEAN OLD UI
-- =========================================================

local oldUI =
	PlayerGui:FindFirstChild(CONFIG.UI_NAME)

if oldUI then
	oldUI:Destroy()
end

-- =========================================================
-- GUI
-- =========================================================

local ScreenGui =
	Instance.new("ScreenGui")

ScreenGui.Name =
	CONFIG.UI_NAME

ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior =
	Enum.ZIndexBehavior.Sibling

ScreenGui.Parent =
	PlayerGui

-- =========================================================
-- MAIN WINDOW
-- =========================================================

local Main =
	Instance.new("Frame")

Main.Name =
	"Main"

Main.Size =
	UDim2.fromOffset(470, 365)

Main.Position =
	UDim2.new(
		0.5,
		-235,
		0.5,
		-182
	)

Main.BackgroundColor3 =
	Color3.fromRGB(
		14,
		14,
		20
	)

Main.BorderSizePixel =
	0

Main.Parent =
	ScreenGui

local MainCorner =
	Instance.new("UICorner")

MainCorner.CornerRadius =
	UDim.new(0, 16)

MainCorner.Parent =
	Main

local MainStroke =
	Instance.new("UIStroke")

MainStroke.Color =
	Color3.fromRGB(
		75,
		75,
		105
	)

MainStroke.Thickness =
	1

MainStroke.Transparency =
	0.25

MainStroke.Parent =
	Main

-- =========================================================
-- HEADER
-- =========================================================

local Header =
	Instance.new("Frame")

Header.Size =
	UDim2.new(
		1,
		0,
		0,
		52
	)

Header.BackgroundColor3 =
	Color3.fromRGB(
		22,
		22,
		31
	)

Header.BorderSizePixel =
	0

Header.Parent =
	Main

local HeaderCorner =
	Instance.new("UICorner")

HeaderCorner.CornerRadius =
	UDim.new(0, 16)

HeaderCorner.Parent =
	Header

local Title =
	Instance.new("TextLabel")

Title.Size =
	UDim2.new(
		1,
		-100,
		1,
		0
	)

Title.Position =
	UDim2.fromOffset(
		18,
		0
	)

Title.BackgroundTransparency =
	1

Title.Text =
	"AXIOM BUS TOOL"

Title.TextXAlignment =
	Enum.TextXAlignment.Left

Title.TextColor3 =
	Color3.fromRGB(
		245,
		245,
		250
	)

Title.Font =
	Enum.Font.GothamBold

Title.TextSize =
	18

Title.Parent =
	Header

local Subtitle =
	Instance.new("TextLabel")

Subtitle.Size =
	UDim2.new(
		1,
		-40,
		0,
		24
	)

Subtitle.Position =
	UDim2.fromOffset(
		20,
		58
	)

Subtitle.BackgroundTransparency =
	1

Subtitle.Text =
	"Bus controls"

Subtitle.TextXAlignment =
	Enum.TextXAlignment.Left

Subtitle.TextColor3 =
	Color3.fromRGB(
		125,
		125,
		145
	)

Subtitle.Font =
	Enum.Font.Gotham

Subtitle.TextSize =
	13

Subtitle.Parent =
	Main

-- =========================================================
-- CLOSE
-- =========================================================

local Close =
	Instance.new("TextButton")

Close.Size =
	UDim2.fromOffset(
		36,
		36
	)

Close.Position =
	UDim2.new(
		1,
		-44,
		0,
		8
	)

Close.BackgroundColor3 =
	Color3.fromRGB(
		42,
		42,
		54
	)

Close.BorderSizePixel =
	0

Close.Text =
	"×"

Close.TextColor3 =
	Color3.fromRGB(
		245,
		245,
		250
	)

Close.TextSize =
	25

Close.Font =
	Enum.Font.GothamBold

Close.Parent =
	Header

local CloseCorner =
	Instance.new("UICorner")

CloseCorner.CornerRadius =
	UDim.new(0, 9)

CloseCorner.Parent =
	Close

Close.MouseButton1Click:Connect(function()
	restoreCollision()

	State.Noclip = false
	State.SpeedEnabled = false

	ScreenGui:Destroy()
end)

-- =========================================================
-- DRAG WINDOW
-- =========================================================

do

	local dragging = false
	local dragStart
	local startPosition

	Header.InputBegan:Connect(function(input)

		if
			input.UserInputType ==
				Enum.UserInputType.MouseButton1
			or
			input.UserInputType ==
				Enum.UserInputType.Touch
		then

			dragging = true

			dragStart =
				input.Position

			startPosition =
				Main.Position
		end

	end)

	Header.InputEnded:Connect(function(input)

		if
			input.UserInputType ==
				Enum.UserInputType.MouseButton1
			or
			input.UserInputType ==
				Enum.UserInputType.Touch
		then

			dragging = false
		end

	end)

	UserInputService.InputChanged:Connect(function(input)

		if not dragging then
			return
		end

		if
			input.UserInputType ~=
				Enum.UserInputType.MouseMovement
			and
			input.UserInputType ~=
				Enum.UserInputType.Touch
		then
			return
		end

		local delta =
			input.Position - dragStart

		Main.Position =
			UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,

				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)

	end)

end

-- =========================================================
-- CONTENT
-- =========================================================

local Content =
	Instance.new("Frame")

Content.Size =
	UDim2.new(
		1,
		-40,
		1,
		-105
	)

Content.Position =
	UDim2.fromOffset(
		20,
		90
	)

Content.BackgroundTransparency =
	1

Content.Parent =
	Main

local function createButton(text, y)

	local Button =
		Instance.new("TextButton")

	Button.Size =
		UDim2.new(
			1,
			0,
			0,
			44
		)

	Button.Position =
		UDim2.fromOffset(
			0,
			y
		)

	Button.BackgroundColor3 =
		Color3.fromRGB(
			29,
			29,
			41
		)

	Button.BorderSizePixel =
		0

	Button.Text =
		text

	Button.TextColor3 =
		Color3.fromRGB(
			235,
			235,
			242
		)

	Button.Font =
		Enum.Font.GothamSemibold

	Button.TextSize =
		15

	Button.AutoButtonColor =
		true

	Button.Parent =
		Content

	local Corner =
		Instance.new("UICorner")

	Corner.CornerRadius =
		UDim.new(0, 10)

	Corner.Parent =
		Button

	return Button
end

-- =========================================================
-- SPEED TOGGLE
-- =========================================================

local SpeedToggle =
	createButton(
		"Unlock Bus Speed: OFF",
		0
	)

-- =========================================================
-- NOCLIP
-- =========================================================

local NoclipToggle =
	createButton(
		"Bus Noclip: OFF",
		54
	)

-- =========================================================
-- SPEED CONTROL
-- =========================================================

local Minus =
	createButton(
		"-20",
		108
	)

Minus.Size =
	UDim2.new(
		0.25,
		-6,
		0,
		44
	)

local SpeedLabel =
	Instance.new("TextLabel")

SpeedLabel.Size =
	UDim2.new(
		0.5,
		-8,
		0,
		44
	)

SpeedLabel.Position =
	UDim2.new(
		0.25,
		4,
		0,
		108
	)

SpeedLabel.BackgroundColor3 =
	Color3.fromRGB(
		20,
		20,
		30
	)

SpeedLabel.BorderSizePixel =
	0

SpeedLabel.Text =
	"Speed: "
	.. State.BusSpeed

SpeedLabel.TextColor3 =
	Color3.fromRGB(
		245,
		245,
		250
	)

SpeedLabel.Font =
	Enum.Font.GothamBold

SpeedLabel.TextSize =
	15

SpeedLabel.Parent =
	Content

local SpeedCorner =
	Instance.new("UICorner")

SpeedCorner.CornerRadius =
	UDim.new(0, 10)

SpeedCorner.Parent =
	SpeedLabel

local Plus =
	createButton(
		"+20",
		108
	)

Plus.Size =
	UDim2.new(
		0.25,
		-6,
		0,
		44
	)

Plus.Position =
	UDim2.new(
		0.75,
		6,
		0,
		108
	)

-- =========================================================
-- RESET
-- =========================================================

local Reset =
	createButton(
		"RESET BUS SETTINGS",
		162
	)

-- =========================================================
-- STATUS
-- =========================================================

local Status =
	Instance.new("TextLabel")

Status.Size =
	UDim2.new(
		1,
		0,
		0,
		36
	)

Status.Position =
	UDim2.fromOffset(
		0,
		220
	)

Status.BackgroundTransparency =
	1

Status.Text =
	"Ready"

Status.TextColor3 =
	Color3.fromRGB(
		130,
		130,
		150
	)

Status.Font =
	Enum.Font.Gotham

Status.TextSize =
	13

Status.Parent =
	Content

-- =========================================================
-- LOGIC
-- =========================================================

SpeedToggle.MouseButton1Click:Connect(function()

	State.SpeedEnabled =
		not State.SpeedEnabled

	if State.SpeedEnabled then

		SpeedToggle.Text =
			"Unlock Bus Speed: ON"

		Status.Text =
			"Speed override enabled"

		applyBusSpeed()

	else

		SpeedToggle.Text =
			"Unlock Bus Speed: OFF"

		Status.Text =
			"Speed override disabled"

	end

end)

NoclipToggle.MouseButton1Click:Connect(function()

	State.Noclip =
		not State.Noclip

	if State.Noclip then

		NoclipToggle.Text =
			"Bus Noclip: ON"

		Status.Text =
			"Bus noclip enabled"

	else

		NoclipToggle.Text =
			"Bus Noclip: OFF"

		Status.Text =
			"Bus noclip disabled"

		restoreCollision()

	end

end)

Plus.MouseButton1Click:Connect(function()

	State.BusSpeed =
		clampSpeed(
			State.BusSpeed
				+ CONFIG.SPEED_STEP
		)

	SpeedLabel.Text =
		"Speed: "
		.. State.BusSpeed

	if State.SpeedEnabled then
		applyBusSpeed()
	end

end)

Minus.MouseButton1Click:Connect(function()

	State.BusSpeed =
		clampSpeed(
			State.BusSpeed
				- CONFIG.SPEED_STEP
		)

	SpeedLabel.Text =
		"Speed: "
		.. State.BusSpeed

	if State.SpeedEnabled then
		applyBusSpeed()
	end

end)

Reset.MouseButton1Click:Connect(function()

	State.SpeedEnabled = false
	State.Noclip = false
	State.BusSpeed =
		CONFIG.DEFAULT_BUS_SPEED

	restoreCollision()

	local bus =
		findCurrentBus()

	local seat =
		getVehicleSeat(bus)

	if seat then
		seat.MaxSpeed =
			CONFIG.DEFAULT_BUS_SPEED
	end

	SpeedToggle.Text =
		"Unlock Bus Speed: OFF"

	NoclipToggle.Text =
		"Bus Noclip: OFF"

	SpeedLabel.Text =
		"Speed: "
		.. State.BusSpeed

	Status.Text =
		"Settings reset"

	notify(
		"Axiom Bus Tool",
		"Bus settings reset."
	)

end)

-- =========================================================
-- RIGHT SHIFT -> SHOW / HIDE
-- =========================================================

UserInputService.InputBegan:Connect(function(
	input,
	gameProcessed
)

	if gameProcessed then
		return
	end

	if
		input.KeyCode ==
		Enum.KeyCode.RightShift
	then

		Main.Visible =
			not Main.Visible

	end

end)

-- =========================================================
-- SPAWN HANDLING
-- =========================================================

Player.CharacterAdded:Connect(function()

	restoreCollision()

	State.Noclip =
		false

	NoclipToggle.Text =
		"Bus Noclip: OFF"

end)

notify(
	"Axiom Bus Tool",
	"Loaded successfully."
)
