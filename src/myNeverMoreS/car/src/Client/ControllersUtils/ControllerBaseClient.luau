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

	local self = setmetatable(configuration :: any, ControllerBaseClient)
	maid:GiveTask(config.car.AncestryChanged:Connect(function(_, parent)
		if not parent then
			self:Destroy()
		end
	end))
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
