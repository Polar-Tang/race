local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControllersTypeClient = require(script.Parent.ControllersTypeClient)
local Maid = require(ReplicatedStorage.Nevermore.Quenty.maid.Shared.Maid)

local ControllerBaseClient = {}
ControllerBaseClient.ClassName = "ControllerBaseClient"
ControllerBaseClient.__index = ControllerBaseClient

--[=[
	Constructs a new ControllerBaseClient

	@param obj? Instance
	@return ControllerBaseClient
]=]
function ControllerBaseClient.new(
	config: ControllersTypeClient.ControllConstructor
): ControllersTypeClient.ControllerBase
	local maid = Maid.new()
	print("config.car ", config.car)
	local configuration: ControllersTypeClient.baseData = {
		_maid = maid,
		car = config.car,
		chassis = config.car:WaitForChild("Chassis"),
		inputs = config.car:WaitForChild("Inputs"),
		driverSeat = config.car:WaitForChild("DriverSeat"),
		engine = config.car:WaitForChild("Engine"),
	}

	-- No AncestryChanged watcher here: every controller is owned by its service's
	-- maid (BaseService._initControllers), and only the top of the hierarchy
	-- (CarClient) watches the car's ancestry. A per-instance watcher would race the
	-- owner and fire on already-destroyed (metatable-stripped) controllers.
	local self = setmetatable(configuration :: any, ControllerBaseClient)
	return self
end

--[=[
	Cleans up the ControllerBaseClient and sets the metatable to nil
]=]
function ControllerBaseClient.Destroy(self: ControllersTypeClient.ControllerBase): ()
	self._maid:DoCleaning()
	setmetatable(self :: any, nil)
end

return ControllerBaseClient
