local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControllersTypes = require(ReplicatedStorage.Nevermore.Custom.car.src.Server.Controllers.utils.ControllersTypes)
local BaseObject = require(ReplicatedStorage.Nevermore.Quenty.baseobject.Shared.BaseObject)
local Maid = require(ReplicatedStorage.Nevermore.Quenty.maid.Shared.Maid)
local Controllers = {
	["Occupant"] = require(script.Parent.Parent.Controllers.Occupant),
	["ConstraintUpdater"] = require(script.Parent.Parent.Controllers.ConstraintUpdater),
	["Redresser"] = require(script.Parent.Parent.Controllers.Redresser),
	["Replication"] = require(script.Parent.Parent.Controllers.Replication),
}

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
	return self
end

function Car.Init(self)
	self:_initControllers()
end

function Car._initControllers(self)
	local controllers = {}
	local controller_constructor: ControllersTypes.ControllConstructor = {
		cart = self._obj,
	}

	for _, ctrller in pairs(Controllers) do
		local new_controller = ctrller.new(controller_constructor)
		controllers[new_controller.ClassName] = new_controller
		-- TODO: Call controller init
	end
	
	self._controllers = controllers
end
function Car.OnSetNitroEnabledEvent(self, player, enable)
	self._controllers["Replication"]:OnSetNitroEnabledEvent(player, enable)
end
function Car.Start(self)
	print(self._controllers, "self._controllers")
	for _, controller: ControllersTypes.ControllerBase in pairs(self._controllers) do
		print(controller)
		controller:Start()
	end
end
return Car
