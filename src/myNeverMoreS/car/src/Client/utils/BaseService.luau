local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControllerBaseClient = require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllerBaseClient)
local ControllersTypeClient = require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllersTypeClient)
local ControllersTypes = require(ReplicatedStorage.Nevermore.Custom.car.src.Server.Controllers.utils.ControllersTypes)
local ClientTypes = require(script.Parent.ClientTypes)
local Maid = require(ReplicatedStorage.Nevermore.Quenty.maid.Shared.Maid)

local BaseService = {}
BaseService.ClassName = "BaseService"
BaseService.__index = BaseService

export type BaseService = typeof(setmetatable(
	{} :: {
		_obj: Instance?,
		_maid: Maid.Maid,
	},
	{} :: typeof({ __index = BaseService })
))

function BaseService.new(config: ClientTypes.ControllConstructor): BaseService
	local self = setmetatable(
		ControllerBaseClient.new(config) :: any,
		BaseService
	)
	return self
end

function BaseService._initControllers(self, Controllers)
	local controllers = {}
	local controller_constructor: ClientTypes.ControllConstructor = {
		car = self.car,
	}

	for _, ctrller in pairs(Controllers) do
		local new_controller = ctrller.new(controller_constructor)
		controllers[new_controller.ClassName] = new_controller
		-- TODO: Call controller init
	end
	
	self._controllers = controllers
end

function BaseService.Start(self)
	print("self._controllers ", self._controllers)
	for _, controller: ControllersTypeClient.ControllerBase in pairs(self._controllers) do
		controller:Start()
	end
end

return BaseService
