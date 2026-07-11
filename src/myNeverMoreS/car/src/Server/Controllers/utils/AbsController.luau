local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControllersTypes = require(script.Parent.ControllersTypes)
local Maid = require(ReplicatedStorage.Nevermore.Quenty.maid.Shared.Maid)

local AbsController = {}
AbsController.ClassName = "AbsController"
AbsController.__index = AbsController

--[=[
	Constructs a new AbsController

	@param obj? Instance
	@return AbsController
]=]
function AbsController.new(config: ControllersTypes.ControllConstructor): ControllersTypes.ControllerBase
	local maid = Maid.new()
	local configuration: ControllersTypes.baseData = {
		_maid = maid,
		car = config.cart,
		chassis = config.cart:FindFirstChild("Chassis"),
		inputs = config.cart:FindFirstChild("Inputs"),
		driverSeat = config.cart:FindFirstChild("DriverSeat"),
		engine = config.cart:FindFirstChild("Engine"),
	}
	-- No AncestryChanged watcher here: controllers are owned by the Car binder's
	-- maid, which destroys them. A per-controller watcher would race the owner and
	-- fire callbacks on already-destroyed (metatable-stripped) controllers.
	local self = setmetatable(configuration :: any, AbsController)
	return self
end

--[=[
	Cleans up the AbsController and sets the metatable to nil
]=]
function AbsController.Destroy(self: ControllersTypes.ControllerBase): ()
	self._maid:DoCleaning()
	setmetatable(self :: any, nil)
end

return AbsController
