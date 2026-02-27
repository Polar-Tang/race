local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ControllerBaseClient = require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllerBaseClient)
local ControllersTypeClient = require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllersTypeClient)
local CarConstants = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.CarConstants)
local Units = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.Units)

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local guiTemplate = script.SpeedometerGui

local Speedometer = setmetatable({}, ControllerBaseClient)
Speedometer.__index = Speedometer
Speedometer.ClassName = "Speedometer"

function Speedometer.new(config: ControllersTypeClient.ControllConstructor): ControllersTypeClient.Speedometer
	local self = setmetatable(ControllerBaseClient.new(config), Speedometer)

	self._enabled = false
	self._gui = nil
	self._heartbeatConnection = nil

	return self
end

-- Update the speedometer dial and nitro bar
function Speedometer._update(self: ControllersTypeClient.Speedometer)
	if not self._gui then 
		print("no gui")
		return
	end
	-- Update UI size. This is the same logic used by the default touch controls
	local minScreenSize = math.min(self._gui.AbsoluteSize.X, self._gui.AbsoluteSize.Y)
	local isSmallScreen = minScreenSize < CarConstants.UI_SMALL_SCREEN_THRESHOLD
	local Speedometer = self._gui:FindFirstChild("Speedometer") :: Frame
	Speedometer.UIScale.Scale = if isSmallScreen then CarConstants.UI_SMALL_SCREEN_SCALE else 1

	-- Update speedometer dial
	local speed = self.chassis.AssemblyLinearVelocity.Magnitude
	-- Velocity is in studs per second by default, and needs to be converted to miles per hour
	local milesPerHour = Units.studsPerSecondToMilesPerHour(speed)
	local speedString = tostring(math.round(milesPerHour))
	Speedometer.SpeedFrame.SpeedLabel.Text = speedString

	-- Update the nitro meter
	local nitro = self.engine:GetAttribute(CarConstants.ENGINE_NITRO_ATTRIBUTE)
	Speedometer.NitroFrame.Nitro.Bar.Size = UDim2.fromScale(nitro, 1)
end

function Speedometer.Enable(self: ControllersTypeClient.Speedometer)
	if self._enabled then
		return
	end
	self._enabled = true

	local newGui = guiTemplate:Clone()
	newGui.Parent = playerGui
	self._gui = newGui

	self._heartbeatConnection = RunService.Heartbeat:Connect(function(a0: number)  
		self:_update()
	end)
end

function Speedometer.Disable(self: ControllersTypeClient.Speedometer)
	if not self._enabled then
		return
	end
	self._enabled = false

	if self._heartbeatConnection then
		self._heartbeatConnection:Disconnect()
		self._heartbeatConnection = nil
	end

	if self._gui then
		self._gui:Destroy()
		self._gui = nil
	end
end

return Speedometer
