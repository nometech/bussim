--[[
=========================================================
              AXIOM DRIVING ASSIST
=========================================================

Dùng dưới dạng LocalScript:

StarterPlayer
└── StarterPlayerScripts
    └── AxiomDrivingAssist.client.lua

Hỗ trợ:
✓ HUD tốc độ
✓ Speed Limiter
✓ Cruise Control
✓ Auto Brake
✓ Forward Collision Warning
✓ Steering Assist
✓ Parking Brake
✓ UI ON/OFF
✓ PC + Mobile-friendly UI

Phím:
RightShift = Ẩn / hiện UI
P          = Park
C          = Cruise
=========================================================
]]

---------------------------------------------------------
-- SERVICES
---------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

---------------------------------------------------------
-- CONFIG
---------------------------------------------------------

local Config = {

	NormalSpeed = 65,

	SpeedLimit = 50,

	CruiseMinSpeed = 10,

	ObstacleWarningDistance = 45,

	AutoBrakeDistance = 20,

	RaycastHeight = 2.5,

	SteeringAssistStrength = 0.12,

	UIKey = Enum.KeyCode.RightShift,

}

---------------------------------------------------------
-- FEATURES
---------------------------------------------------------

local Features = {

	SpeedLimiter = true,

	Cruise = false,

	AutoBrake = true,

	CollisionWarning = true,

	SteeringAssist = false,

	ParkingBrake = false,

}

---------------------------------------------------------
-- STATE
---------------------------------------------------------

local currentSeat = nil
local currentVehicle = nil

local cruiseSpeed = 0

local obstacleDistance = math.huge

---------------------------------------------------------
-- VEHICLE
---------------------------------------------------------

local function getSeat()

	local character = player.Character

	if not character then
		return nil
	end

	local humanoid =
		character:FindFirstChildOfClass(
			"Humanoid"
		)

	if not humanoid then
		return nil
	end

	local seat =
		humanoid.SeatPart

	if seat
		and seat:IsA("VehicleSeat")
	then

		return seat

	end

	return nil

end

local function findVehicle(seat)

	if not seat then
		return nil
	end

	local object =
		seat

	while object
		and object ~= workspace
	do

		if object:IsA("Model") then

			local vehicleSeat =
				object:FindFirstChildWhichIsA(
					"VehicleSeat",
					true
				)

			if vehicleSeat == seat then
				return object
			end

		end

		object =
			object.Parent

	end

	return seat.Parent

end

---------------------------------------------------------
-- SPEED
---------------------------------------------------------

local function getSpeed()

	if not currentSeat then
		return 0
	end

	return
		currentSeat
			.AssemblyLinearVelocity
			.Magnitude

end

local function toKMH(speed)

	return math.floor(
		speed * 1.008 + 0.5
	)

end

---------------------------------------------------------
-- PARK
---------------------------------------------------------

local function setParkingBrake(enabled)

	if not currentSeat then
		return
	end

	Features.ParkingBrake =
		enabled

	if enabled then

		Features.Cruise =
			false

		cruiseSpeed =
			0

		currentSeat.MaxSpeed =
			0

		if getSpeed() < 4 then

			currentSeat.AssemblyLinearVelocity =
				Vector3.zero

			currentSeat.AssemblyAngularVelocity =
				Vector3.zero

		end

	else

		currentSeat.MaxSpeed =
			Config.NormalSpeed

	end

end

---------------------------------------------------------
-- CRUISE
---------------------------------------------------------

local function toggleCruise()

	if not currentSeat then
		return
	end

	if Features.ParkingBrake then
		return
	end

	if Features.Cruise then

		Features.Cruise = false
		cruiseSpeed = 0

		return

	end

	local speed =
		getSpeed()

	if speed <
		Config.CruiseMinSpeed
	then

		return

	end

	Features.Cruise = true

	cruiseSpeed = speed

end

---------------------------------------------------------
-- OBSTACLE RAYCAST
---------------------------------------------------------

local rayParams =
	RaycastParams.new()

rayParams.FilterType =
	Enum.RaycastFilterType.Exclude

local function checkObstacle()

	if not currentSeat then

		obstacleDistance =
			math.huge

		return nil

	end

	local ignore = {}

	if currentVehicle then
		table.insert(
			ignore,
			currentVehicle
		)
	end

	if player.Character then
		table.insert(
			ignore,
			player.Character
		)
	end

	rayParams.FilterDescendantsInstances =
		ignore

	local origin =
		currentSeat.Position
		+ Vector3.new(
			0,
			Config.RaycastHeight,
			0
		)

	local direction =
		currentSeat.CFrame.LookVector
		* Config.ObstacleWarningDistance

	local result =
		workspace:Raycast(
			origin,
			direction,
			rayParams
		)

	if result then

		obstacleDistance =
			(
				result.Position
				- origin
			).Magnitude

		return result

	end

	obstacleDistance =
		math.huge

	return nil

end

---------------------------------------------------------
-- AUTO BRAKE
---------------------------------------------------------

local function applyAutoBrake()

	if not Features.AutoBrake then
		return
	end

	if not currentSeat then
		return
	end

	if Features.ParkingBrake then
		return
	end

	if obstacleDistance >
		Config.AutoBrakeDistance
	then

		return

	end

	local speed =
		getSpeed()

	if speed <= 1 then
		return
	end

	Features.Cruise =
		false

	cruiseSpeed =
		0

	local velocity =
		currentSeat
			.AssemblyLinearVelocity

	local distanceFactor =
		math.clamp(
			obstacleDistance
				/ Config.AutoBrakeDistance,
			0.15,
			1
		)

	currentSeat.AssemblyLinearVelocity =
		velocity
		* (
			0.72
			+ distanceFactor
			* 0.18
		)

end

---------------------------------------------------------
-- STEERING ASSIST
---------------------------------------------------------

local function applySteeringAssist()

	if not Features.SteeringAssist then
		return
	end

	if not currentSeat then
		return
	end

	if getSpeed() < 5 then
		return
	end

	-- Giảm rung/yaw nhẹ khi xe đang chạy thẳng.
	if math.abs(
		currentSeat.SteerFloat
	) < 0.1
	then

		local angular =
			currentSeat
				.AssemblyAngularVelocity

		currentSeat.AssemblyAngularVelocity =
			Vector3.new(
				angular.X,
				angular.Y
					* (
						1
						- Config.SteeringAssistStrength
					),
				angular.Z
			)

	end

end

---------------------------------------------------------
-- UI
---------------------------------------------------------

local old =
	playerGui:FindFirstChild(
		"AxiomDrivingAssist"
	)

if old then
	old:Destroy()
end

local gui =
	Instance.new("ScreenGui")

gui.Name =
	"AxiomDrivingAssist"

gui.ResetOnSpawn =
	false

gui.DisplayOrder =
	9999

gui.Parent =
	playerGui

---------------------------------------------------------
-- MAIN
---------------------------------------------------------

local main =
	Instance.new("Frame")

main.Size =
	UDim2.fromOffset(
		340,
		445
	)

main.Position =
	UDim2.new(
		0,
		25,
		0.5,
		-220
	)

main.BackgroundColor3 =
	Color3.fromRGB(
		15,
		17,
		22
	)

main.BorderSizePixel =
	0

main.Parent =
	gui

local mainCorner =
	Instance.new("UICorner")

mainCorner.CornerRadius =
	UDim.new(
		0,
		16
	)

mainCorner.Parent =
	main

local stroke =
	Instance.new("UIStroke")

stroke.Color =
	Color3.fromRGB(
		65,
		75,
		90
	)

stroke.Parent =
	main

---------------------------------------------------------
-- TITLE
---------------------------------------------------------

local title =
	Instance.new("TextLabel")

title.Position =
	UDim2.fromOffset(
		16,
		10
	)

title.Size =
	UDim2.new(
		1,
		-32,
		0,
		25
	)

title.BackgroundTransparency =
	1

title.Text =
	"AXIOM DRIVING ASSIST"

title.Font =
	Enum.Font.GothamBold

title.TextSize =
	17

title.TextColor3 =
	Color3.new(
		1,
		1,
		1
	)

title.TextXAlignment =
	Enum.TextXAlignment.Left

title.Parent =
	main

---------------------------------------------------------

local system =
	Instance.new("TextLabel")

system.Position =
	UDim2.fromOffset(
		16,
		35
	)

system.Size =
	UDim2.new(
		1,
		-32,
		0,
		18
	)

system.BackgroundTransparency =
	1

system.Text =
	"SYSTEM • ONLINE"

system.Font =
	Enum.Font.GothamMedium

system.TextSize =
	11

system.TextColor3 =
	Color3.fromRGB(
		80,
		235,
		140
	)

system.TextXAlignment =
	Enum.TextXAlignment.Left

system.Parent =
	main

---------------------------------------------------------
-- STATUS
---------------------------------------------------------

local status =
	Instance.new("TextLabel")

status.Position =
	UDim2.fromOffset(
		16,
		65
	)

status.Size =
	UDim2.new(
		1,
		-32,
		0,
		110
	)

status.BackgroundColor3 =
	Color3.fromRGB(
		22,
		25,
		32
	)

status.BorderSizePixel =
	0

status.Font =
	Enum.Font.Code

status.TextSize =
	12

status.TextColor3 =
	Color3.fromRGB(
		200,
		210,
		220
	)

status.TextXAlignment =
	Enum.TextXAlignment.Left

status.TextYAlignment =
	Enum.TextYAlignment.Top

status.Parent =
	main

local statusCorner =
	Instance.new("UICorner")

statusCorner.CornerRadius =
	UDim.new(
		0,
		10
	)

statusCorner.Parent =
	status

---------------------------------------------------------
-- BUTTON AREA
---------------------------------------------------------

local list =
	Instance.new("Frame")

list.Position =
	UDim2.fromOffset(
		16,
		188
	)

list.Size =
	UDim2.new(
		1,
		-32,
		0,
		240
	)

list.BackgroundTransparency =
	1

list.Parent =
	main

local layout =
	Instance.new("UIListLayout")

layout.Padding =
	UDim.new(
		0,
		7
	)

layout.Parent =
	list

---------------------------------------------------------
-- TOGGLE FACTORY
---------------------------------------------------------

local buttons = {}

local function createToggle(
	label,
	feature
)

	local button =
		Instance.new("TextButton")

	button.Size =
		UDim2.new(
			1,
			0,
			0,
			38
		)

	button.BorderSizePixel =
		0

	button.Font =
		Enum.Font.GothamMedium

	button.TextSize =
		13

	button.TextColor3 =
		Color3.new(
			1,
			1,
			1
		)

	button.Parent =
		list

	buttons[feature] =
		{
			Button = button,
			Label = label,
		}

	local corner =
		Instance.new("UICorner")

	corner.CornerRadius =
		UDim.new(
			0,
			10
		)

	corner.Parent =
		button

	local function refresh()

		local enabled =
			Features[feature]

		button.Text =
			label
			.. "      "
			.. (
				enabled
				and "[ ON ]"
				or "[ OFF ]"
			)

		button.BackgroundColor3 =
			enabled
				and Color3.fromRGB(
					35,
					78,
					52
				)
				or Color3.fromRGB(
					29,
					32,
					41
				)

	end

	button.MouseButton1Click:Connect(
		function()

			if feature ==
				"Cruise"
			then

				toggleCruise()

			else

				Features[feature] =
					not Features[feature]

			end

			refresh()

		end
	)

	refresh()

end

---------------------------------------------------------
-- BUTTONS
---------------------------------------------------------

createToggle(
	"Speed Limiter",
	"SpeedLimiter"
)

createToggle(
	"Cruise Control",
	"Cruise"
)

createToggle(
	"Auto Brake",
	"AutoBrake"
)

createToggle(
	"Collision Warning",
	"CollisionWarning"
)

createToggle(
	"Steering Assist",
	"SteeringAssist"
)

---------------------------------------------------------
-- PARK BUTTON
---------------------------------------------------------

local parkButton =
	Instance.new("TextButton")

parkButton.Size =
	UDim2.new(
		1,
		0,
		0,
		38
	)

parkButton.Text =
	"PARK / RELEASE P"

parkButton.Font =
	Enum.Font.GothamBold

parkButton.TextSize =
	13

parkButton.TextColor3 =
	Color3.new(
		1,
		1,
		1
	)

parkButton.BackgroundColor3 =
	Color3.fromRGB(
		58,
		46,
		30
	)

parkButton.BorderSizePixel =
	0

parkButton.Parent =
	list

local parkCorner =
	Instance.new("UICorner")

parkCorner.CornerRadius =
	UDim.new(
		0,
		10
	)

parkCorner.Parent =
	parkButton

parkButton.MouseButton1Click:Connect(
	function()

		if not currentSeat then
			return
		end

		if Features.ParkingBrake then

			setParkingBrake(
				false
			)

		else

			if getSpeed() <= 3 then

				setParkingBrake(
					true
				)

			end

		end

	end
)

---------------------------------------------------------
-- KEYBOARD
---------------------------------------------------------

UserInputService.InputBegan:Connect(
	function(
		input,
		processed
	)

		if processed then
			return
		end

		if input.KeyCode ==
			Config.UIKey
		then

			gui.Enabled =
				not gui.Enabled

		elseif input.KeyCode ==
			Enum.KeyCode.P
		then

			if currentSeat then

				if Features.ParkingBrake then

					setParkingBrake(
						false
					)

				elseif getSpeed() <= 3 then

					setParkingBrake(
						true
					)

				end

			end

		elseif input.KeyCode ==
			Enum.KeyCode.C
		then

			toggleCruise()

		end

	end
)

---------------------------------------------------------
-- MAIN LOOP
---------------------------------------------------------

RunService.RenderStepped:Connect(
	function(dt)

		-----------------------------------------------------
		-- VEHICLE
		-----------------------------------------------------

		local seat =
			getSeat()

		if seat ~= currentSeat then

			currentSeat =
				seat

			currentVehicle =
				findVehicle(
					seat
				)

			Features.Cruise =
				false

			Features.ParkingBrake =
				false

			cruiseSpeed =
				0

		end

		-----------------------------------------------------
		-- WAITING
		-----------------------------------------------------

		if not currentSeat then

			status.Text =
				"BUS       : WAITING"
				.. "\nSPEED     : 0 KM/H"
				.. "\nPARK      : OFF"
				.. "\nOBSTACLE  : ---"

			return

		end

		local speed =
			getSpeed()

		-----------------------------------------------------
		-- RAYCAST
		-----------------------------------------------------

		checkObstacle()

		-----------------------------------------------------
		-- PARK
		-----------------------------------------------------

		if Features.ParkingBrake then

			currentSeat.MaxSpeed =
				0

			if speed < 3 then

				currentSeat.AssemblyLinearVelocity =
					Vector3.zero

			end

		-----------------------------------------------------
		-- SPEED LIMITER
		-----------------------------------------------------

		elseif Features.SpeedLimiter then

			currentSeat.MaxSpeed =
				Config.SpeedLimit

		else

			currentSeat.MaxSpeed =
				Config.NormalSpeed

		end

		-----------------------------------------------------
		-- CRUISE
		-----------------------------------------------------

		if Features.Cruise
			and cruiseSpeed > 0
			and not Features.ParkingBrake
		then

			if speed <
				cruiseSpeed
			then

				local forward =
					currentSeat
						.CFrame
						.LookVector

				local difference =
					cruiseSpeed
					- speed

				currentSeat.AssemblyLinearVelocity =
					currentSeat
						.AssemblyLinearVelocity
					+ forward
					* difference
					* dt
					* 2

			end

		end

		-----------------------------------------------------
		-- AUTO BRAKE
		-----------------------------------------------------

		applyAutoBrake()

		-----------------------------------------------------
		-- STEERING
		-----------------------------------------------------

		applySteeringAssist()

		-----------------------------------------------------
		-- STATUS
		-----------------------------------------------------

		local warning =
			"SAFE"

		if obstacleDistance <
			Config.AutoBrakeDistance
		then

			warning =
				"BRAKE"

		elseif obstacleDistance <
			Config.ObstacleWarningDistance
		then

			warning =
				"WARNING"

		end

		status.Text =
			"BUS       : "
			.. (
				currentVehicle
				and currentVehicle.Name
				or "VEHICLE"
			)
			.. "\nSPEED     : "
			.. toKMH(speed)
			.. " KM/H"
			.. "\nPARK      : "
			.. (
				Features.ParkingBrake
					and "ON"
					or "OFF"
			)
			.. "\nCRUISE    : "
			.. (
				Features.Cruise
					and toKMH(
						cruiseSpeed
					)
						.. " KM/H"
					or "OFF"
			)
			.. "\nOBSTACLE  : "
			.. (
				obstacleDistance <
					math.huge
					and math.floor(
						obstacleDistance
					)
						.. " m"
					or "---"
			)
			.. "\nASSIST    : "
			.. warning

	end
)

---------------------------------------------------------
-- RESET
---------------------------------------------------------

player.CharacterAdded:Connect(
	function()

		currentSeat =
			nil

		currentVehicle =
			nil

		cruiseSpeed =
			0

	end
)

print(
	"[AXIOM DRIVING ASSIST] ONLINE"
)
