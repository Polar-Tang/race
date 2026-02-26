local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseObject = require(ReplicatedStorage.Nevermore.Quenty.baseobject.Shared.BaseObject)
local Maid = require(ReplicatedStorage.Nevermore.Quenty.maid.Shared.Maid)
local Controllers = ReplicatedStorage.Nevermore.Custom.carClient.src.Server.Controllers

local CarClient = {}
CarClient.ClassName = "CarClient"
CarClient.__index = CarClient

export type CarClient = typeof(setmetatable(
	{} :: {
		_obj: Instance?,
		_maid: Maid.Maid,
	},
	{} :: typeof({ __index = CarClient })
))

function CarClient.new(obj: Instance?): CarClient
	local self = setmetatable(BaseObject.new(obj) :: any, CarClient)
	self:_initControllers()
	return self
end

function CarClient._initControllers(self)
	local controllers = {}
	local controller_constructor = {
		carClientt = self._obj,
	}

	for _, file: Instance in ipairs(Controllers:GetDescendants()) do
		if file:IsA("ModuleScript") then
			local controllerFile = require(file)
			local controller = controllerFile.new(controller_constructor)
			controllers[controller.ClassName] = controllers
			-- TODO: Call controller init
		end
	end
	self._controllers = controllers
end

function CarClient.OnSetNitroEnabledEvent(self, player, enable)
	self._controllers["Replication"]:OnSetNitroEnabledEvent(player, enable)
end

function CarClient.Start(self)
	for _, controller in pairs(self._controllers) do
		controller:Start()
	end
end

return CarClient
