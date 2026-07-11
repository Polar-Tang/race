local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControllersTypes = require(ReplicatedStorage.Nevermore.Custom.car.src.Server.Controllers.utils.ControllersTypes)
local BaseObject = require(ReplicatedStorage.Nevermore.Quenty.baseobject.Shared.BaseObject)
local Maid = require(ReplicatedStorage.Nevermore.Quenty.maid.Shared.Maid)
local Controllers = {
	["ConstraintUpdater"] = require(script.Parent.Parent.Controllers.ConstraintUpdater),
	["Occupant"] = require(script.Parent.Parent.Controllers.Occupant),
	["Redresser"] = require(script.Parent.Parent.Controllers.Redresser),
	["Replication"] = require(script.Parent.Parent.Controllers.Replication),
	["Hitbox"] = require(script.Parent.Parent.Controllers.Hitbox),
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
	--self._carInitializer = CarInitializer.new({
	--	cart = self._obj,
	--})

	-- Top of the server hierarchy: if the car model leaves the DataModel, destroy
	-- the whole tree. BaseObject.Destroy cleans self._maid, which disconnects this
	-- connection and destroys every controller given to the maid below.
	self._maid:GiveTask(self._obj.AncestryChanged:Connect(function(_, parent)
		if not parent then
			self:Destroy()
		end
	end))

	return self
end

function Car.Init(self)
	--self._carInitializer:Init()
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
		-- Owned by the Car's maid: BaseObject.Destroy -> maid cleaning -> destroys
		-- every controller, so one Destroy() cascades down the whole hierarchy.
		self._maid:GiveTask(new_controller)
		if new_controller.Init then
			new_controller:Init()
		end
	end

	self._controllers = controllers
end

function Car.OnSetNitroEnabledEvent(self, player, enable)
	self._controllers["Replication"]:OnSetNitroEnabledEvent(player, enable)
end

function Car.Start(self)
	for _, controller: ControllersTypes.ControllerBase in pairs(self._controllers) do
		print(controller)
		controller:Start()
	end
end
return Car
