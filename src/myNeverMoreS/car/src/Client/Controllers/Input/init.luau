local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


local ControllerBaseClient = require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllerBaseClient)
local ControllersTypeClient = require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllersTypeClient)
local CarConstants = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.CarConstants)
local Maid = require(ReplicatedStorage.Nevermore.Quenty.maid.Shared.Maid)
local InputCategorizer = require(script.Parent.Parent.InputCategorizer)
local InputModules = {
	[InputCategorizer.InputCategory.KeyboardAndMouse] = require(script.KeyboardAndMouse),
	[InputCategorizer.InputCategory.Gamepad] = require(script.Gamepad),
	[InputCategorizer.InputCategory.Touch] = require(script.Touch),
}
local maid = Maid.new()

local ClassInput = setmetatable({}, ControllerBaseClient)
ClassInput.__index = ClassInput
ClassInput.ClassName = "ClassInput"

function ClassInput.new(config: ControllersTypeClient.ControllConstructor): ControllersTypeClient.ClassInput
	local self = setmetatable(ControllerBaseClient.new(config), ClassInput)

	self._currentInputCategory = InputCategorizer.getLastInputCategory()
	self._enabled = false

	return self
end

function ClassInput._onLastInputCategoryChanged(self: ControllersTypeClient.ClassInput, lastInputCategory)
	self._currentInputCategory = lastInputCategory

	for inputCategory, module in InputModules do
		if inputCategory == lastInputCategory then
			module:Enable()
		else
			module:Disable()
		end
	end
end

function ClassInput._update(self: ControllersTypeClient.ClassInput)
	local inputModule = InputModules[self._currentInputCategory]
	if not inputModule then
		return
	end

	local throttle, steering = inputModule:getThrottleAndSteering()
	self.inputs:SetAttribute(CarConstants.THROTTLE_INPUT_ATTRIBUTE, throttle)
	self.inputs:SetAttribute(CarConstants.STEERING_INPUT_ATTRIBUTE, steering)
end

function ClassInput.Enable(self: ControllersTypeClient.ClassInput)
	if self._enabled then
		return
	end
	self._enabled = true

	-- Disable touch controls
	GuiService.TouchControlsEnabled = false

	maid:GiveTask(InputCategorizer.lastInputCategoryChanged:Connect(function(...)
		self:_onLastInputCategoryChanged(...)
	end))
	maid:GiveTask(RunService.Stepped:Connect(function(...)
		self:_update()
	end))

	self:_onLastInputCategoryChanged(InputCategorizer.getLastInputCategory())
end

function ClassInput:Disable()
	if not self._enabled then
		return
	end
	self._enabled = false

	maid:DoCleaning()
	-- Reenable touch controls
	GuiService.TouchControlsEnabled = true

	-- Disable all input modules
	for _, module in InputModules do
		module:Disable()
	end
end

return ClassInput
