local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControllersTypes = require(ReplicatedStorage.Nevermore.Custom.car.src.Server.Controllers.utils.ControllersTypes)
local BaseObject = require(ReplicatedStorage.Nevermore.Quenty.baseobject.Shared.BaseObject)
local Maid = require(ReplicatedStorage.Nevermore.Quenty.maid.Shared.Maid)
local Controllers = ReplicatedStorage.Nevermore.Custom.car.src.Server.Controllers

local Car = {}
Car.ClassName = "Car"
Car.__index = Car

export type Car = typeof(setmetatable(
	{} :: {
		_obj: Instance?,
		_maid: Maid.Maid,
	},
	{} :: typeof({ __index = Car })
))

--[=[
	Constructs a new Car

	@param obj? Instance
	@return Car
]=]
function Car.new(obj: Instance?): Car
	local self = setmetatable(BaseObject.new(obj) :: any, Car)
	self:_initControllers()
	return self
end

function Car._initControllers(self)
	local controllers = {}
	local controller_constructor: ControllersTypes.ControllConstructor = {
		cart = self._obj,
	}

	for _, file: Instance in ipairs(Controllers:GetDescendants()) do
		if file:IsA("ModuleScript") then
			local controllerFile: ControllersTypes.ControllerBase = require(file)
			local controller = controllerFile.new(controller_constructor)
			controllers[controller.ClassName] = controllers
			-- TODO: Call controller init
		end
	end
	self._controllers = controllers
end
function Car.OnSetNitroEnabledEvent(self, player, enable)
	self._controllers["Replication"]:OnSetNitroEnabledEvent(player, enable)
end
function Car.Start(self)
	for _, controller: ControllersTypes.ControllerBase in pairs(self._controllers) do
		controller:Start()
	end
end
return Car
