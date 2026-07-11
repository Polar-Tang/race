local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ControllerBaseClient =
	require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllerBaseClient)
local ControllersTypeClient =
	require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllersTypeClient)
local CarConstants = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.CarConstants)
local Maid = require(ReplicatedStorage.Nevermore.Quenty.maid.Shared.Maid)
local InputCategorizer = require(script.Parent.Parent.InputCategorizer)
local InputModules = {
	[InputCategorizer.InputCategory.KeyboardAndMouse] = require(script.KeyboardAndMouse),
	[InputCategorizer.InputCategory.Gamepad] = require(script.Gamepad),
	[InputCategorizer.InputCategory.Touch] = require(script.Touch),
}

local ClassInput = setmetatable({}, ControllerBaseClient)
ClassInput.__index = ClassInput
ClassInput.ClassName = "ClassInput"

function ClassInput.new(config: ControllersTypeClient.ControllConstructor): ControllersTypeClient.ClassInput
	local self = setmetatable(ControllerBaseClient.new(config), ClassInput)

	self._currentInputCategory = InputCategorizer.getLastInputCategory()
	self._enabled = false

	self._controllers = {}
	for key, module in InputModules do
		self._controllers[key] = module.new(config)
		-- Owned by this controller's maid so Destroy cascades down
		self._maid:GiveTask(self._controllers[key])
	end

	-- Connections that only live while input is enabled; a per-instance maid
	-- (not a module-level one) so Destroy during an active session still cleans,
	-- and two cars never share cleanup state.
	self._enableMaid = Maid.new()
	self._maid:GiveTask(self._enableMaid)

	return self
end

function ClassInput._onLastInputCategoryChanged(self: ControllersTypeClient.ClassInput, lastInputCategory)
	self._currentInputCategory = lastInputCategory
	print("lastInputCategory ", lastInputCategory)
	for inputCategory, module in self._controllers do
		print("inputCategory ", inputCategory)
		print("inputCategory == lastInputCategory ", inputCategory == lastInputCategory)

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

	local throttle, steering = inputModule:GetThrottleAndSteering()
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

	self._enableMaid:GiveTask(InputCategorizer.lastInputCategoryChanged:Connect(function(...)
		self:_onLastInputCategoryChanged(...)
	end))
	self._enableMaid:GiveTask(RunService.Stepped:Connect(function(...)
		self:_update()
	end))

	self:_onLastInputCategoryChanged(InputCategorizer.getLastInputCategory())
end

function ClassInput:Disable()
	if not self._enabled then
		return
	end
	self._enabled = false

	self._enableMaid:DoCleaning()
	-- Reenable touch controls
	GuiService.TouchControlsEnabled = true

	-- Disable this car's input controllers (instances, not the shared modules)
	for _, controller in self._controllers do
		controller:Disable()
	end
end

-- Polymorphic Destroy: re-enable the default touch controls even when destroyed
-- mid-drive, then run the base cleanup, which destroys the input controllers
-- owned by self._maid.
function ClassInput.Destroy(self: ControllersTypeClient.ClassInput)
	self:Disable()
	ControllerBaseClient.Destroy(self)
end

return ClassInput
