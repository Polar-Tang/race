local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local CarConstants = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.CarConstants)
local Maid = require(ReplicatedStorage.Nevermore.Quenty.loader.Maid)
local cycleCameraModeHandler = require(script.Parent.utils.cycleCameraModeHandler)
local exitHandlerAsync = require(script.Parent.utils.exitHandlerAsync)
local handBrakeHandler = require(script.Parent.utils.handBrakeHandler)
local nitroHandler = require(script.Parent.utils.nitroHandler)

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local touchGuiTemplate = script.TouchGui

local enabled = false
local gui = nil
local throttleAmount = 0
local brakeAmount = 0
local steeringTouchInputObject = nil
local gasPedalInputObject = nil
local brakePedalInputObject = nil
local nitroInputObject = nil
local handBrakeInputObject = nil

local maid = Maid.new()
-- A single UserInputService.InputEnded connection is used to handle input ending, since
-- lifting a finger after it has moved off a GuiObject will not fire InputEnded on that GuiObject.
local function onInputEnded(inputObject: InputObject)
	inputObject:RemoveTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG)

	if inputObject == steeringTouchInputObject then
		steeringTouchInputObject = nil
	elseif inputObject == gasPedalInputObject then
		gasPedalInputObject = nil
		throttleAmount = 0
	elseif inputObject == brakePedalInputObject then
		brakePedalInputObject = nil
		brakeAmount = 0
	elseif inputObject == nitroInputObject then
		nitroInputObject = nil
		-- Since we are not using the default ContextActionService touch controls, we need to
		-- emulate a ContextActionService call to nitroHandler, passing in the expected parameters.
		nitroHandler(CarConstants.TOUCH_NITRO_BIND_NAME, Enum.UserInputState.End)
	elseif inputObject == handBrakeInputObject then
		handBrakeInputObject = nil
		-- Emulate a ContextActionService call to handBrakeHandler, passing in the expected parameters
		handBrakeHandler(CarConstants.TOUCH_HAND_BRAKE_BIND_NAME, Enum.UserInputState.End)
	end
end

-- For each of the UI buttons, we keep track of the InputObject that touched so we
-- can avoid avoid triggering other buttons by sliding over them and accurately tell
-- when the input has stopped.
local function onGasPedalInputBegan(inputObject: InputObject)
	if inputObject:HasTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG) then
		return
	end
	inputObject:AddTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG)
	gasPedalInputObject = inputObject
	throttleAmount = 1
end

local function onBrakePedalInputBegan(inputObject: InputObject)
	if inputObject:HasTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG) then
		return
	end
	inputObject:AddTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG)
	brakePedalInputObject = inputObject
	brakeAmount = 1
end

local function onWheelInputBegan(inputObject: InputObject)
	if inputObject:HasTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG) then
		return
	end
	inputObject:AddTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG)
	-- We keep track of the InputObject that touched the wheel so that we
	-- can check its position later when :getThrottleAndSteering() is called
	steeringTouchInputObject = inputObject
end

local function onNitroButtonInputBegan(inputObject: InputObject)
	if inputObject:HasTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG) then
		return
	end
	inputObject:AddTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG)
	nitroInputObject = inputObject
	-- Emulate a ContextActionService call to nitroHandler, since that is what it expects
	nitroHandler(CarConstants.TOUCH_NITRO_BIND_NAME, Enum.UserInputState.Begin)
end

local function onHandBrakeInputBegan(inputObject: InputObject)
	if inputObject:HasTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG) then
		return
	end
	inputObject:AddTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG)
	handBrakeInputObject = inputObject
	-- Emulate a ContextActionService call to nitroHandler, since that is what it expects
	handBrakeHandler(CarConstants.TOUCH_HAND_BRAKE_BIND_NAME, Enum.UserInputState.Begin)
end

local function onExitButtonInputBegan(inputObject: InputObject)
	if inputObject:HasTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG) then
		return
	end
	-- Emulate a ContextActionService call to exitHandlerAsync, since that is what it expects
	exitHandlerAsync(CarConstants.TOUCH_EXIT_BIND_NAME, Enum.UserInputState.Begin)
end

local function onCycleCameraModeButtonInputBegan(inputObject: InputObject)
	if inputObject:HasTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG) then
		return
	end
	-- Emulate a ContextActionService call to cycleCameraModeHandler, since that is what it expects
	cycleCameraModeHandler(CarConstants.TOUCH_CYCLE_CAMERA_MODE_BIND_NAME, Enum.UserInputState.Begin)
end

local function updateScale()
	-- Update UI size. This is the same logic used by the default touch controls
	local minScreenSize = math.min(gui.AbsoluteSize.X, gui.AbsoluteSize.Y)
	local isSmallScreen = minScreenSize < CarConstants.UI_SMALL_SCREEN_THRESHOLD
	gui.UIScale.Scale = if isSmallScreen then CarConstants.UI_SMALL_SCREEN_SCALE else 1
end

local Touch = {}

function Touch:getThrottleAndSteering(): (number, number)
	local throttle = throttleAmount - brakeAmount
	local steering = 0

	-- If the player is currently touching the steering wheel, set the steering value
	if steeringTouchInputObject then
		local position = steeringTouchInputObject.Position.X
		local center = gui.Wheel.AbsolutePosition.X + gui.Wheel.AbsoluteSize.X / 2
		local offset = position - center
		local offsetAlpha = (offset / gui.Wheel.AbsoluteSize.X) * 2
		steering = math.clamp(offsetAlpha, -1, 1)
	end

	-- Update the steering wheel visual
	gui.Wheel.WheelLabel.Rotation = steering * 90

	return throttle, steering
end

function Touch:enable()
	if enabled then
		return
	end
	enabled = true

	gui = touchGuiTemplate:Clone()
	gui.Parent = playerGui

	-- Setup connections
	maid:GiveTask(gui.Wheel.InputButton.InputBegan:Connect(onWheelInputBegan))
	maid:GiveTask(gui.Controls.GasButton.InputBegan:Connect(onGasPedalInputBegan))
	maid:GiveTask(gui.Controls.BrakeButton.InputBegan:Connect(onBrakePedalInputBegan))
	maid:GiveTask(gui.Controls.HandBrakeButton.InputBegan:Connect(onHandBrakeInputBegan))
	maid:GiveTask(gui.Controls.NitroButton.InputBegan:Connect(onNitroButtonInputBegan))
	maid:GiveTask(gui.Misc.ExitButton.InputBegan:Connect(onExitButtonInputBegan))
	maid:GiveTask(gui.Misc.CycleCameraModeButton.InputBegan:Connect(onCycleCameraModeButtonInputBegan))
	maid:GiveTask(UserInputService.InputEnded:Connect(onInputEnded))
	maid:GiveTask(gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScale))

	updateScale()
end

function Touch:disable()
	if not enabled then
		return
	end
	enabled = false

	maid:DoCleaning()

	if gui then
		gui:Destroy()
		gui = nil
	end
end

return Touch
