local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbsController = require(ReplicatedStorage.Nevermore.Custom.car.src.Server.Controllers.utils.AbsController)
local ControllersTypes = require(ReplicatedStorage.Nevermore.Custom.car.src.Server.Controllers.utils.ControllersTypes)
local CarConstants = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.CarConstants)

local Replication = setmetatable({}, AbsController)
Replication.__index = Replication
Replication.ClassName = "Replication"

function Replication.new(config: ControllersTypes.ControllConstructor): ControllersTypes.Replication
	local self = setmetatable(AbsController.new(config), Replication)

	return self
end

function Replication._getDrivingPlayer(self: ControllersTypes.Replication): Player?
	local humanoid = self.driverSeat.Occupant
	if not humanoid then
		return nil
	end

	return Players:GetPlayerFromCharacter(humanoid.Parent)
end

function Replication._onOccupantChanged(self)
	-- Disable nitro whenever the car is exited
	local humanoid = self.driverSeat.Occupant
	if not humanoid then
		self.engine:SetAttribute(CarConstants.NITRO_ENABLED_ATTRIBUTE, false)
	end
end

function Replication.OnSetNitroEnabledEvent(self: ControllersTypes.Replication, player: Player, enabled: boolean)
	-- Make sure the remote cannot be exploited to set the attribute to an arbitrary value
	if typeof(enabled) ~= "boolean" then
		return
	end

	-- Make sure the remote event call is coming from the player who is actually driving the car
	local drivingPlayer = self:_getDrivingPlayer()
	if player ~= drivingPlayer then
		return
	end

	self.engine:SetAttribute(CarConstants.NITRO_ENABLED_ATTRIBUTE, enabled)
end

function Replication.Init(self: ControllersTypes.Replication)
	local con = self.driverSeat:GetPropertyChangedSignal("Occupant"):Connect(function(...)
		self:_onOccupantChanged()
	end)
	self._maid:GiveTask(con)
end
