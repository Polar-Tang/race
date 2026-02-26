local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControllerBaseClient = require(ReplicatedStorage.Nevermore.Custom.car.src.Client.Controllers.ControllerBaseClient)
local ClientTypes = require(script.Parent.ClientTypes)
local ControllersTypeClient =
	require(ReplicatedStorage.Nevermore.Custom.car.src.Client.Controllers.ControllersTypeClient)
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

function BaseService._initControllers(self, Controllers: Folder)
	local controllers = {}
	local controller_constructor: ClientTypes.ControllConstructor = {
		car = self._obj,
	}

	for _, file: Instance in ipairs(Controllers:GetDescendants()) do
		if file:IsA("ModuleScript") then
			local controllerFile: ControllersTypeClient.ControllerBase = require(file)
			local controller = controllerFile.new(controller_constructor)
			controllers[controller.ClassName] = controller
			if controller.Init then
				controller:Init()
			end
		end
	end
	self._controllers = controllers
end

function BaseService.Start(self)
	for _, controller: ControllersTypeClient.ControllerBase in pairs(self._controllers) do
		controller:Start()
	end
end

return BaseService
