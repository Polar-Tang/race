--[[
	The FixedCamera rigidly attaches the camera to an attachment on the car.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ControllerBaseClient = require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllerBaseClient)
local ControllersTypeClient = require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllersTypeClient)

local camera = Workspace.CurrentCamera

local RENDER_STEPPED_BIND_NAME = "CarFixedCamera"
local RENDER_STEPPED_BIND_PRIORITY = Enum.RenderPriority.Camera.Value

local FixedCamera = setmetatable({}, ControllerBaseClient)
FixedCamera.__index = FixedCamera
FixedCamera.ClassName = "FixedCamera"

function FixedCamera.new(config: ControllersTypeClient.ControllConstructor): ControllersTypeClient.FixedCamera
	local self = setmetatable(ControllerBaseClient.new(config), FixedCamera)

	self._enabled = false
	self._parameters = {
		attachment = nil,
	}

	return self
end

function FixedCamera._update(self: ControllersTypeClient.FixedCamera, _deltaTime: number)
	-- Set the camera CFrame to the currently set attachment's WorldCFrame
	camera.CFrame = self._parameters.attachment.WorldCFrame
end

function FixedCamera.SetParameters(self: ControllersTypeClient.FixedCamera, newParameters: { attachment: Attachment })
	self._parameters = newParameters
end

function FixedCamera.Enable(self: ControllersTypeClient.FixedCamera)
	if self._enabled then
		return
	end
	self._enabled = true

	RunService:BindToRenderStep(RENDER_STEPPED_BIND_NAME, RENDER_STEPPED_BIND_PRIORITY, function(delta: number)
		self:_update(delta)
	end)
end

function FixedCamera.Disable(self: ControllersTypeClient.FixedCamera)
	if not self._enabled then
		return
	end
	self._enabled = false

	RunService:UnbindFromRenderStep(RENDER_STEPPED_BIND_NAME)
end

-- Polymorphic Destroy: release the RenderStep binding even when destroyed
-- mid-drive, then run the base cleanup.
function FixedCamera.Destroy(self: ControllersTypeClient.FixedCamera)
	self:Disable()
	ControllerBaseClient.Destroy(self)
end

return FixedCamera
