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
	local configuration: ControllersTypes.baseData = {
		_maid = Maid.new(),
		car = config.cart,
		chassis = config.cart:FindFirstChild("Chassis"),
		inputs = config.cart:FindFirstChild("Inputs"),
		driverSeat = config.cart:FindFirstChild("DriverSeat"),
		engine = config.cart:FindFirstChild("Engine"),
	}
	return setmetatable(configuration :: any, AbsController)
end

--[=[
	Cleans up the AbsController and sets the metatable to nil
]=]
function AbsController.Destroy(self: ControllersTypes.ControllerBase): ()
	self._maid:DoCleaning()
	setmetatable(self :: any, nil)
end

function AbsController.Init(self: ControllersTypes.ControllerBase): ()
	error("Most be override by child class")
end

return AbsController
