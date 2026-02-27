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
	local configuration: ControllersTypeClient.baseData = {
		_maid = Maid.new(),
		car = config.car,
		chassis = config.car:FindFirstChild("Chassis"),
		inputs = config.car:FindFirstChild("Inputs"),
		driverSeat = config.car:FindFirstChild("DriverSeat"),
		engine = config.car:FindFirstChild("Engine"),
	}
	return setmetatable(configuration :: any, ControllerBaseClient)
end

--[=[
	Cleans up the ControllerBaseClient and sets the metatable to nil
]=]
function ControllerBaseClient.Destroy(self: ControllersTypeClient.ControllerBase): ()
	self._maid:DoCleaning()
	setmetatable(self :: any, nil)
end

function ControllerBaseClient.Init(self: ControllersTypeClient.ControllerBase): ()
	error("Most be override by child class")
end

return ControllerBaseClient
