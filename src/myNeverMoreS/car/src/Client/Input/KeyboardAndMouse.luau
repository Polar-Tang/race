local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local CarConstants = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.CarConstants)
local cycleCameraModeHandler = require(script.Parent.utils.cycleCameraModeHandler)
local exitHandlerAsync = require(script.Parent.utils.exitHandlerAsync)
local nitroHandler = require(script.Parent.utils.nitroHandler)
local handBrakeHandler = require(script.Parent.utils.handBrakeHandler)
local getStringForKeyCode = require(script.Parent.utils.getStringForKeyCode)

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local controlsGuiTemplate = script.Parent.ControlsGui
local car = script.Parent.Parent.Parent.Parent
local inputs = car.Inputs

local FORWARD_KEY = Enum.KeyCode.W
local BACKWARD_KEY = Enum.KeyCode.S
local RIGHT_KEY = Enum.KeyCode.D
local LEFT_KEY = Enum.KeyCode.A
local FORWARD_KEY_ALT = Enum.KeyCode.Up
local BACKWARD_KEY_ALT = Enum.KeyCode.Down
local RIGHT_KEY_ALT = Enum.KeyCode.Right
local LEFT_KEY_ALT = Enum.KeyCode.Left

local enabled = false
local controlsGui = nil

local KeyboardAndMouse = {}

function KeyboardAndMouse:getThrottleAndSteering(): (number, number)
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

function KeyboardAndMouse:enable()
	if enabled then
		return
	end
	enabled = true

	local cycleCameraModeKeyCode = inputs:GetAttribute(CarConstants.KEYBOARD_CYCLE_CAMERA_MODE_KEY_CODE_ATTRIBUTE)
	local exitKeyCode = inputs:GetAttribute(CarConstants.KEYBOARD_EXIT_KEY_CODE_ATTRIBUTE)
	local nitroKeyCode = inputs:GetAttribute(CarConstants.KEYBOARD_NITRO_KEY_CODE_ATTRIBUTE)
	local handBrakeKeyCode = inputs:GetAttribute(CarConstants.KEYBOARD_HAND_BRAKE_KEY_CODE_ATTRIBUTE)

	controlsGui = controlsGuiTemplate:Clone()
	controlsGui.Parent = playerGui

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
	ContextActionService:BindAction(CarConstants.KEYBOARD_EXIT_BIND_NAME, exitHandlerAsync, false, exitKeyCode)
	ContextActionService:BindAction(CarConstants.KEYBOARD_NITRO_BIND_NAME, nitroHandler, false, nitroKeyCode)
	ContextActionService:BindAction(
		CarConstants.KEYBOARD_HAND_BRAKE_BIND_NAME,
		handBrakeHandler,
		false,
		handBrakeKeyCode
	)
end

function KeyboardAndMouse:disable()
	if not enabled then
		return
	end
	enabled = false

	ContextActionService:UnbindAction(CarConstants.KEYBOARD_CYCLE_CAMERA_MODE_BIND_NAME)
	ContextActionService:UnbindAction(CarConstants.KEYBOARD_EXIT_BIND_NAME)
	ContextActionService:UnbindAction(CarConstants.KEYBOARD_NITRO_BIND_NAME)
	ContextActionService:UnbindAction(CarConstants.KEYBOARD_HAND_BRAKE_BIND_NAME)

	if controlsGui then
		controlsGui:Destroy()
		controlsGui = nil
	end
end

return KeyboardAndMouse
