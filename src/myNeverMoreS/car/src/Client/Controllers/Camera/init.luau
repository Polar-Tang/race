local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VRService = game:GetService("VRService")
local Workspace = game:GetService("Workspace")

local CameraModules = {
	ChaseCamera = require(script.ChaseCamera),
	InteriorCamera = require(script.InteriorCamera),
	FixedCamera = require(script.FixedCamera),
} 
local ControllerBaseClient = require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllerBaseClient)
local ControllersTypeClient = require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllersTypeClient)
local CameraModes = require(script.CameraModes)

local camera = Workspace.CurrentCamera
local cycleCameraModeEvent = game.ReplicatedStorage.RemoteEvents.CycleCameraMode

local CameraClass = setmetatable({}, ControllerBaseClient)
CameraClass.__index = CameraClass
CameraClass.ClassName = "CameraClass"

function CameraClass.new(config: ControllersTypeClient.ControllConstructor): ControllersTypeClient.CameraClass
	local self = setmetatable(ControllerBaseClient.new(config), CameraClass)

	self._cycleCameraModeConnection = nil
	self._currentCameraModeIndex = 1
	self._enabled = false

	

	return self
end

-- Set the current mode and enable/disable the correct CameraModules
function CameraClass.SetMode(self: ControllersTypeClient.CameraClass,modeIndex: number)
	self._currentCameraModeIndex = modeIndex
	self._cameraMode = CameraModes(self.car)
	self._currentModeInfo = self._cameraMode[self._currentCameraModeIndex]
	for name, module in CameraModules do
		if name == self._currentModeInfo.module then
			-- Enable the CameraModule and set parameters for the current mode
			module:SetParameters(self._currentModeInfo.parameters)
			module:Enable()
		else
			-- Disable other CameraModules
			module:Disable()
		end
	end
end

-- Cycle to the next camera mode, wrapping around at the end
function CameraClass.CycleCameraMode(self: ControllersTypeClient.CameraClass)
	local nextModeIndex = self._currentCameraModeIndex + 1
	if nextModeIndex > #self._cameraMode then
		nextModeIndex = 1
	end
	self:SetMode(nextModeIndex)
end

function CameraClass.Enable(self: ControllersTypeClient.CameraClass)
	if self._enabled then
		return
	end
	-- Custom camera is not enabled for VR devices, allowing the default VR vehicle camera to be used
	if VRService.VREnabled then
		return
	end

	self._enabled = true

	self._cycleCameraModeConnection = cycleCameraModeEvent.Event:Connect(function()
		self:CycleCameraMode()
	end)

	-- Set the CameraType to scriptable, since we are taking control of it
	camera.CameraType = Enum.CameraType.Scriptable
	-- Initialize with the current mode
	self:SetMode(self._currentCameraModeIndex)
end

function CameraClass.Disable(self: ControllersTypeClient.CameraClass)
	if not self._enabled then
		return
	end
	self._enabled = false

	if self._cycleCameraModeConnection then
		self._cycleCameraModeConnection:Disconnect()
		self._cycleCameraModeConnection = nil
	end

	-- Reset the camera back to CameraType.Custom to re-enable default camera controls
	camera.CameraType = Enum.CameraType.Custom

	-- Disable all CameraModules
	for _, module in CameraModules do
		module:Disable()
	end
end

return CameraClass
