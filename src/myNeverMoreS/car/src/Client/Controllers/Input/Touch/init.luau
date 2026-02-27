local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

---------------------------config---------------------------------
local ControllerBaseClient = require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllerBaseClient)
local ControllersTypeClient = require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllersTypeClient)
local CarConstants = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.CarConstants)
---------------------------utils---------------------------------
local Maid = require(ReplicatedStorage.Nevermore.Quenty.loader.Maid)
local cycleCameraModeHandler = require(script.Parent.utils.cycleCameraModeHandler)
local exitHandlerAsync = require(script.Parent.utils.exitHandlerAsync)
local handBrakeHandler = require(script.Parent.utils.handBrakeHandler)
local nitroHandler = require(script.Parent.utils.nitroHandler)
-----------------------------------------------------------------

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local touchGuiTemplate = script.TouchGui

local maid = Maid.new()
local TouchInput = setmetatable({}, ControllerBaseClient)
TouchInput.__index = TouchInput
TouchInput.ClassName = "TouchInput"

function TouchInput.new(config: ControllersTypeClient.ControllConstructor): ControllersTypeClient.TouchInput
	local self = setmetatable(ControllerBaseClient.new(config), TouchInput)

	self._enabled = false
	self._gui = nil
	self._throttleAmount = 0
	self._brakeAmount = 0
	self._steeringTouchInputObject = nil
	self._gasPedalInputObject = nil
	self._brakePedalInputObject = nil
	self._nitroInputObject = nil
	self._handBrakeInputObject = nil

	return self
end

-- A single UserInputService.InputEnded connection is used to handle input ending, since
-- lifting a finger after it has moved off a GuiObject will not fire InputEnded on that GuiObject.
function TouchInput._onInputEnded(self: ControllersTypeClient.TouchInput, inputObject: InputObject)
	inputObject:RemoveTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG)

	if inputObject == self._steeringTouchInputObject then
		self._steeringTouchInputObject = nil
	elseif inputObject == self._gasPedalInputObject then
		self._gasPedalInputObject = nil
		self._throttleAmount = 0
	elseif inputObject == self._brakePedalInputObject then
		self._brakePedalInputObject = nil
		self._brakeAmount = 0
	elseif inputObject == self._nitroInputObject then
		self._nitroInputObject = nil
		-- Since we are not using the default ContextActionService touch controls, we need to
		-- emulate a ContextActionService call to nitroHandler, passing in the expected parameters.
		nitroHandler(Enum.UserInputState.End, self.inputs)
	elseif inputObject == self._handBrakeInputObject then
		self._handBrakeInputObject = nil
		-- Emulate a ContextActionService call to handBrakeHandler, passing in the expected parameters
		handBrakeHandler(Enum.UserInputState.End, self.inputs)
	end
end

-- For each of the UI buttons, we keep track of the InputObject that touched so we
-- can avoid avoid triggering other buttons by sliding over them and accurately tell
-- when the input has stopped.
function TouchInput._onGasPedalInputBegan(self: ControllersTypeClient.TouchInput, inputObject: InputObject)
	if inputObject:HasTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG) then
		return
	end
	inputObject:AddTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG)
	self._gasPedalInputObject = inputObject
	self._throttleAmount = 1
end

function TouchInput._onBrakePedalInputBegan(self: ControllersTypeClient.TouchInput, inputObject: InputObject)
	if inputObject:HasTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG) then
		return
	end
	inputObject:AddTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG)
	self._brakePedalInputObject = inputObject
	self._brakeAmount = 1
end

function TouchInput._onWheelInputBegan(self: ControllersTypeClient.TouchInput, inputObject: InputObject)
	if inputObject:HasTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG) then
		return
	end
	inputObject:AddTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG)
	-- We keep track of the InputObject that touched the wheel so that we
	-- can check its position later when :getThrottleAndSteering() is called
	self._steeringTouchInputObject = inputObject
end

function TouchInput._onNitroButtonInputBegan(self: ControllersTypeClient.TouchInput, inputObject: InputObject)
	if inputObject:HasTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG) then
		return
	end
	inputObject:AddTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG)
	self._nitroInputObject = inputObject
	-- Emulate a ContextActionService call to nitroHandler, since that is what it expects
	nitroHandler(Enum.UserInputState.End, self.inputs)
end

function TouchInput._onHandBrakeInputBegan(self: ControllersTypeClient.TouchInput, inputObject: InputObject)
	if inputObject:HasTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG) then
		return
	end
	inputObject:AddTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG)
	self._handBrakeInputObject = inputObject
	-- Emulate a ContextActionService call to nitroHandler, since that is what it expects
	handBrakeHandler(CarConstants.TOUCH_HAND_BRAKE_BIND_NAME, Enum.UserInputState.Begin)
end

function TouchInput._onExitButtonInputBegan(self: ControllersTypeClient.TouchInput, inputObject: InputObject)
	if inputObject:HasTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG) then
		return
	end
	-- Emulate a ContextActionService call to exitHandlerAsync, since that is what it expects
	exitHandlerAsync(Enum.UserInputState.Begin, self.chassis)
end

function TouchInput._onCycleCameraModeButtonInputBegan(self: ControllersTypeClient.TouchInput, inputObject: InputObject)
	if inputObject:HasTag(CarConstants.TOUCH_INPUT_OBJECT_IGNORE_TAG) then
		return
	end
	-- Emulate a ContextActionService call to cycleCameraModeHandler, since that is what it expects
	cycleCameraModeHandler(CarConstants.TOUCH_CYCLE_CAMERA_MODE_BIND_NAME, Enum.UserInputState.Begin)
end

function TouchInput._updateScale(self: ControllersTypeClient.TouchInput)
	if not self._gui then
		return
	end
	-- Update UI size. This is the same logic used by the default touch controls
	local minScreenSize = math.min(self._gui.AbsoluteSize.X, self._gui.AbsoluteSize.Y)
	local isSmallScreen = minScreenSize < CarConstants.UI_SMALL_SCREEN_THRESHOLD
	local gui = self._gui
	gui.UIScale.Scale = if isSmallScreen then CarConstants.UI_SMALL_SCREEN_SCALE else 1
end

function TouchInput.GetThrottleAndSteering(self: ControllersTypeClient.TouchInput): (number, number)
	local throttle = self._throttleAmount - self._brakeAmount
	local steering = 0
	local gui = self._gui
	-- If the player is currently touching the steering wheel, set the steering value
	if self._steeringTouchInputObject then
		local position = self._steeringTouchInputObject.Position.X
		local center = gui.Wheel.AbsolutePosition.X + gui.Wheel.AbsoluteSize.X / 2
		local offset = position - center
		local offsetAlpha = (offset / gui.Wheel.AbsoluteSize.X) * 2
		steering = math.clamp(offsetAlpha, -1, 1)
	end

	-- Update the steering wheel visual
	gui.Wheel.WheelLabel.Rotation = steering * 90

	return throttle, steering
end

function TouchInput.Enable(self: ControllersTypeClient.TouchInput)
	if self._enabled then
		return
	end
	self._enabled = true

	local GUI = touchGuiTemplate:Clone()

	-- Setup connections
	maid:GiveTask(GUI.Wheel.InputButton.InputBegan:Connect(function(a0: InputObject)
		self:_onWheelInputBegan(a0)
	end))
	maid:GiveTask(GUI.Controls.GasButton.InputBegan:Connect(function(a0: InputObject)
		self:_onGasPedalInputBegan(a0)
	end))
	maid:GiveTask(GUI.Controls.BrakeButton.InputBegan:Connect(function(a0: InputObject)
		self:_onBrakePedalInputBegan(a0)
	end))
	maid:GiveTask(GUI.Controls.HandBrakeButton.InputBegan:Connect(function(a0: InputObject)
		self:_onHandBrakeInputBegan(a0)
	end))
	maid:GiveTask(GUI.Controls.NitroButton.InputBegan:Connect(function(a0: InputObject)
		self:_onNitroButtonInputBegan(a0)
	end))
	maid:GiveTask(GUI.Misc.ExitButton.InputBegan:Connect(function(a0: InputObject)
		self:_onExitButtonInputBegan(a0)
	end))
	maid:GiveTask(GUI.Misc.CycleCameraModeButton.InputBegan:Connect(function(a0: InputObject)
		self:_onCycleCameraModeButtonInputBegan(a0)
	end))
	maid:GiveTask(UserInputService.InputEnded:Connect(function(a0: InputObject)
		self:_onInputEnded(a0)
	end))
	maid:GiveTask(GUI:GetPropertyChangedSignal("AbsoluteSize"):Connect(function(a0: InputObject)
		self:_updateScale()
	end))
	GUI.Parent = playerGui
	self._gui = GUI
	self:_updateScale()
end

function TouchInput.Disable(self: ControllersTypeClient.TouchInput)
	if not self._enabled then
		return
	end
	self._enabled = false

	maid:DoCleaning()

	if self._gui then
		self._gui:Destroy()
		self._gui = nil
	end
end

return TouchInput
