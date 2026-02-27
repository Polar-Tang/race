local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ControllerBaseClient =
	require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllerBaseClient)
local ControllersTypeClient =
	require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllersTypeClient)

local CarConstants = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.CarConstants)
local cycleCameraModeHandler = require(script.Parent.utils.cycleCameraModeHandler)
local exitHandlerAsync = require(script.Parent.utils.exitHandlerAsync)
local nitroHandler = require(script.Parent.utils.nitroHandler)
local handBrakeHandler = require(script.Parent.utils.handBrakeHandler)

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local controlsGuiTemplate = script.Parent.ControlsGui

local LEFT_THUMBSTICK = Enum.KeyCode.Thumbstick1
local RIGHT_TRIGGER = Enum.KeyCode.ButtonR2
local LEFT_TRIGGER = Enum.KeyCode.ButtonL2
local STEERING_DEADZONE = 0.1

local function onLastInputTypeChanged(inputType: Enum.UserInputType)
	if string.find(inputType.Name, "Gamepad") then
		currentGamepad = inputType
	end
end

local Gamepad = setmetatable({}, ControllerBaseClient)
Gamepad.__index = Gamepad
Gamepad.ClassName = "Gamepad"

function Gamepad.new(config: ControllersTypeClient.ControllConstructor): ControllersTypeClient.Gamepad
	local self = setmetatable(ControllerBaseClient.new(config), Gamepad)

	self._currentGamepad = Enum.UserInputType.Gamepad1
	self._enabled = false
	self._lastInputTypeChangedConnection = nil
	self._controlsGui = nil

	return self
end

function Gamepad.GetThrottleAndSteering(self: ControllersTypeClient.Gamepad): (number, number)
	local throttle = 0
	local steering = 0
	local gamepadState = UserInputService:GetGamepadState(currentGamepad)

	for _, inputObject in gamepadState do
		if inputObject.KeyCode == LEFT_THUMBSTICK then
			local position = inputObject.Position.X
			if math.abs(position) > STEERING_DEADZONE then
				-- Apply deadzone
				steering = ((math.abs(position) - STEERING_DEADZONE) / (1 - STEERING_DEADZONE)) * math.sign(position)
			end
		elseif inputObject.KeyCode == RIGHT_TRIGGER then
			throttle += inputObject.Position.Z
		elseif inputObject.KeyCode == LEFT_TRIGGER then
			throttle -= inputObject.Position.Z
		end
	end

	return throttle, steering
end

function Gamepad.Enable(self: ControllersTypeClient.Gamepad)
	if self._enabled then
		return
	end
	self._enabled = true

	local cycleCameraModeKeyCode = self.inputs:GetAttribute(CarConstants.GAMEPAD_CYCLE_CAMERA_MODE_KEY_CODE_ATTRIBUTE)
	local exitKeyCode = self.inputs:GetAttribute(CarConstants.GAMEPAD_EXIT_KEY_CODE_ATTRIBUTE)
	local nitroKeyCode = self.inputs:GetAttribute(CarConstants.GAMEPAD_NITRO_KEY_CODE_ATTRIBUTE)
	local handBrakeKeyCode = self.inputs:GetAttribute(CarConstants.GAMEPAD_HAND_BRAKE_KEY_CODE_ATTRIBUTE)

	local controlsGui = controlsGuiTemplate:Clone()
	controlsGui.Parent = playerGui

	-- Get the gamepad button images to display on the controls UI. UserInputService:GetImageForKeycode() returns
	-- platform-specific icons to support various platforms.
	local cycleCameraModeImage = UserInputService:GetImageForKeyCode(cycleCameraModeKeyCode)
	local exitImage = UserInputService:GetImageForKeyCode(exitKeyCode)
	local nitroImage = UserInputService:GetImageForKeyCode(nitroKeyCode)
	local handBrakeImage = UserInputService:GetImageForKeyCode(handBrakeKeyCode)

	-- Display the gamepad bindings for the car's controls
	controlsGui.Controls.CameraFrame.GamepadLabel.Image = cycleCameraModeImage
	controlsGui.Controls.ExitFrame.GamepadLabel.Image = exitImage
	controlsGui.Controls.NitroFrame.GamepadLabel.Image = nitroImage
	controlsGui.Controls.HandBrakeFrame.GamepadLabel.Image = handBrakeImage
	controlsGui.Controls.CameraFrame.GamepadLabel.Visible = true
	controlsGui.Controls.ExitFrame.GamepadLabel.Visible = true
	controlsGui.Controls.NitroFrame.GamepadLabel.Visible = true
	controlsGui.Controls.HandBrakeFrame.GamepadLabel.Visible = true

	self._controlsGui = controlsGui

	ContextActionService:BindAction(
		CarConstants.GAMEPAD_CYCLE_CAMERA_MODE_BIND_NAME,
		cycleCameraModeHandler,
		false,
		cycleCameraModeKeyCode
	)
	ContextActionService:BindAction(
		CarConstants.GAMEPAD_EXIT_BIND_NAME,
		function(
			actionName: string,
			inputState: Enum.UserInputState,
			inputObject: InputObject
		): Enum.ContextActionResult?
			return exitHandlerAsync(inputState, self.chassis)
		end,
		false,
		exitKeyCode
	)
	ContextActionService:BindAction(
		CarConstants.GAMEPAD_NITRO_BIND_NAME,
		function(
			actionName: string,
			inputState: Enum.UserInputState,
			inputObject: InputObject
		): Enum.ContextActionResult?
			return nitroHandler(inputState, self.inputs)
		end,
		false,
		nitroKeyCode
	)
	ContextActionService:BindAction(
		CarConstants.GAMEPAD_HAND_BRAKE_BIND_NAME,
		function(
			actionName: string,
			inputState: Enum.UserInputState,
			inputObject: InputObject
		): Enum.ContextActionResult?
			return handBrakeHandler(inputState, self.inputs)
		end,
		false,
		handBrakeKeyCode
	)

	-- We listen to LastInputTypeChanged so we can specifically check which was the last gamepad being used.
	-- Simply calling GetLastInputType in getThrottleAndSteering would potentially return non-gamepad InputTypes.
	self._lastInputTypeChangedConnection = UserInputService.LastInputTypeChanged:Connect(onLastInputTypeChanged)

	local lastInputType = UserInputService:GetLastInputType()
	onLastInputTypeChanged(lastInputType)
end

function Gamepad.Disable(self: ControllersTypeClient.Gamepad)
	if not self._enabled then
		return
	end
	self._enabled = false

	ContextActionService:UnbindAction(CarConstants.GAMEPAD_CYCLE_CAMERA_MODE_BIND_NAME)
	ContextActionService:UnbindAction(CarConstants.GAMEPAD_EXIT_BIND_NAME)
	ContextActionService:UnbindAction(CarConstants.GAMEPAD_NITRO_BIND_NAME)
	ContextActionService:UnbindAction(CarConstants.GAMEPAD_HAND_BRAKE_BIND_NAME)

	if self._lastInputTypeChangedConnection then
		self._lastInputTypeChangedConnection:Disconnect()
		self._lastInputTypeChangedConnection = nil
	end

	if self._controlsGui then
		self._controlsGui:Destroy()
		self._controlsGui = nil
	end
end

return Gamepad
