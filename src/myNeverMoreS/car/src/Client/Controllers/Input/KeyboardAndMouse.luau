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
local getStringForKeyCode = require(script.Parent.utils.getStringForKeyCode)

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local controlsGuiTemplate = script.Parent.ControlsGui

local FORWARD_KEY = Enum.KeyCode.W
local BACKWARD_KEY = Enum.KeyCode.S
local RIGHT_KEY = Enum.KeyCode.D
local LEFT_KEY = Enum.KeyCode.A
local FORWARD_KEY_ALT = Enum.KeyCode.Up
local BACKWARD_KEY_ALT = Enum.KeyCode.Down
local RIGHT_KEY_ALT = Enum.KeyCode.Right
local LEFT_KEY_ALT = Enum.KeyCode.Left

local KeyboardAndMouse = setmetatable({}, ControllerBaseClient)
KeyboardAndMouse.__index = KeyboardAndMouse
KeyboardAndMouse.ClassName = "KeyboardAndMouse"

function KeyboardAndMouse.new(config: ControllersTypeClient.ControllConstructor): ControllersTypeClient.KeyboardAndMouse
	local self = setmetatable(ControllerBaseClient.new(config), KeyboardAndMouse)

	self._currentGamepad = Enum.UserInputType.Gamepad1
	self._enabled = false
	self._lastInputTypeChangedConnection = nil
	self._controlsGui = nil

	return self
end

function KeyboardAndMouse.GetThrottleAndSteering(self: ControllersTypeClient.KeyboardAndMouse): (number, number)
	local throttle = 0
	local steering = 0

	if UserInputService:IsKeyDown(FORWARD_KEY) or UserInputService:IsKeyDown(FORWARD_KEY_ALT) then
		throttle += 1
	end
	if UserInputService:IsKeyDown(BACKWARD_KEY) or UserInputService:IsKeyDown(BACKWARD_KEY_ALT) then
		throttle -= 1
	end
	if UserInputService:IsKeyDown(RIGHT_KEY) or UserInputService:IsKeyDown(RIGHT_KEY_ALT) then
		steering += 1
	end
	if UserInputService:IsKeyDown(LEFT_KEY) or UserInputService:IsKeyDown(LEFT_KEY_ALT) then
		steering -= 1
	end

	return throttle, steering
end

function KeyboardAndMouse.Enable(self: ControllersTypeClient.KeyboardAndMouse)
	if self._enabled then
		return
	end
	self._enabled = true

	local cycleCameraModeKeyCode = self.inputs:GetAttribute(CarConstants.KEYBOARD_CYCLE_CAMERA_MODE_KEY_CODE_ATTRIBUTE)
	local exitKeyCode = self.inputs:GetAttribute(CarConstants.KEYBOARD_EXIT_KEY_CODE_ATTRIBUTE)
	local nitroKeyCode = self.inputs:GetAttribute(CarConstants.KEYBOARD_NITRO_KEY_CODE_ATTRIBUTE)
	local handBrakeKeyCode = self.inputs:GetAttribute(CarConstants.KEYBOARD_HAND_BRAKE_KEY_CODE_ATTRIBUTE)

	local controlsGui = controlsGuiTemplate:Clone()

	-- Get the strings to display for each of the keycodes
	local cycleCameraModeString = getStringForKeyCode(cycleCameraModeKeyCode)
	local exitString = getStringForKeyCode(exitKeyCode)
	local nitroString = getStringForKeyCode(nitroKeyCode)
	local handBrakeString = getStringForKeyCode(handBrakeKeyCode)

	-- Display the keyboard bindings for the car's controls
	controlsGui.Controls.CameraFrame.KeyboardLabel.TextLabel.Text = string.upper(cycleCameraModeString)
	controlsGui.Controls.ExitFrame.KeyboardLabel.TextLabel.Text = string.upper(exitString)
	controlsGui.Controls.NitroFrame.KeyboardLabel.TextLabel.Text = string.upper(nitroString)
	controlsGui.Controls.HandBrakeFrame.KeyboardLabel.TextLabel.Text = string.upper(handBrakeString)
	controlsGui.Controls.CameraFrame.KeyboardLabel.Visible = true
	controlsGui.Controls.ExitFrame.KeyboardLabel.Visible = true
	controlsGui.Controls.NitroFrame.KeyboardLabel.Visible = true
	controlsGui.Controls.HandBrakeFrame.KeyboardLabel.Visible = true

	ContextActionService:BindAction(
		CarConstants.KEYBOARD_CYCLE_CAMERA_MODE_BIND_NAME,
		cycleCameraModeHandler,
		false,
		cycleCameraModeKeyCode
	)
	ContextActionService:BindAction(
		CarConstants.KEYBOARD_EXIT_BIND_NAME,
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
	ContextActionService:BindAction(CarConstants.KEYBOARD_NITRO_BIND_NAME, function(
			actionName: string,
			inputState: Enum.UserInputState,
			inputObject: InputObject
		): Enum.ContextActionResult?
			return nitroHandler(inputState, self.inputs)
		end, false, nitroKeyCode)
	ContextActionService:BindAction(
		CarConstants.KEYBOARD_HAND_BRAKE_BIND_NAME,
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
	controlsGui.Parent = playerGui
	self._controlsGui = controlsGui
end

function KeyboardAndMouse.Disable(self: ControllersTypeClient.KeyboardAndMouse)
	if not self._enabled then
		return
	end
	self._enabled = false

	ContextActionService:UnbindAction(CarConstants.KEYBOARD_CYCLE_CAMERA_MODE_BIND_NAME)
	ContextActionService:UnbindAction(CarConstants.KEYBOARD_EXIT_BIND_NAME)
	ContextActionService:UnbindAction(CarConstants.KEYBOARD_NITRO_BIND_NAME)
	ContextActionService:UnbindAction(CarConstants.KEYBOARD_HAND_BRAKE_BIND_NAME)

	if self._controlsGui then
		self._controlsGui:Destroy()
		self._controlsGui = nil
	end
end

return KeyboardAndMouse
