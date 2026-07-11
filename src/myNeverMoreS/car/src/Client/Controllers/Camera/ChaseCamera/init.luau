--[[
	The ChaseCamera follows the car at a set distance and height, aligning itself with the car's
	movement direction. The player can control it like the standard camera (i.e. orbit around the car).
	When the player starts controlling, it switches to manual mode and does not align with the car's
	movement direction. After a few seconds without player input, the camera will return to automatic mode.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ControllerBaseClient =
	require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllerBaseClient)
local ControllersTypeClient =
	require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllersTypeClient)
local InputCategorizer = require(ReplicatedStorage.Nevermore.Custom.car.src.Client.InputCategorizer)

local InputModules = {
	[InputCategorizer.InputCategory.KeyboardAndMouse] = require(script.KeyboardAndMouse),
	[InputCategorizer.InputCategory.Gamepad] = require(script.Gamepad),
	[InputCategorizer.InputCategory.Touch] = require(script.Touch),
}
local pitchAndYawFromDirection = require(script.pitchAndYawFromDirection)

local camera = Workspace.CurrentCamera

local RENDER_STEPPED_BIND_NAME = "CarChaseCamera"
local RENDER_STEPPED_BIND_PRIORITY = Enum.RenderPriority.Camera.Value

local RESET_TO_AUTOMATIC_TIME = 3 -- Time it takes to reset back to automatic control once the player stops controlling the camera
local LOOK_AHEAD_AMOUNT = 3
local LOOK_AHEAD_HEIGHT_SCALE = 0.5
local LOOK_AHEAD_SPEED = 10
local TRAILING_CATCHUP_SPEED = 15
local GIMBAL_SPEED_AUTOMATIC = 5
local GIMBAL_SPEED_MANUAL = 15
local CAMERA_SPEED_AUTOMATIC = 5
local CAMERA_SPEED_MANUAL = 15
local USE_VELOCITY_DIRECTION_THRESHOLD = 10

local MAX_PITCH = math.rad(80)
local MIN_PITCH = math.rad(-80)

local ChaseCamera = setmetatable({}, ControllerBaseClient)
ChaseCamera.__index = ChaseCamera
ChaseCamera.ClassName = "ChaseCamera"

function ChaseCamera.new(config: ControllersTypeClient.ControllConstructor): ControllersTypeClient.ChaseCamera
	local self = setmetatable(ControllerBaseClient.new(config), ChaseCamera)

	self._gimbalCFrame = CFrame.new()
	self._relativeCameraCFrame = CFrame.new()
	self._trailingOffset = Vector3.zero
	self._lookAhead = Vector3.zero
	self._isManualControl = false
	self._lastManualControl = 0
	self._pitch = 0
	self._yaw = 0

	self._lastInputCategoryChangedConnection = nil
	self._currentInputCategory = InputCategorizer.getLastInputCategory()
	self._enabled = false
	self._parameters = {
		height = 7,
		distance = 15,
	}

	return self
end

-- Enable/disable input modules when the input category changes
function ChaseCamera._onLastInputCategoryChanged(self: ControllersTypeClient.ChaseCamera, lastInputCategory)
	self._currentInputCategory = lastInputCategory

	for inputCategory, module in InputModules do
		if inputCategory == lastInputCategory then
			module:enable()
		else
			module:disable()
		end
	end
end

function ChaseCamera._update(self: ControllersTypeClient.ChaseCamera, deltaTime: number)
	local chassisVelocity = self.chassis.AssemblyLinearVelocity
	local targetVector = chassisVelocity
	-- If the chassis is not moving fast enough, look forward rather than in the velocity direction
	if chassisVelocity.Magnitude < USE_VELOCITY_DIRECTION_THRESHOLD then
		targetVector = self.chassis.CFrame.LookVector
	end

	-- Read input
	local inputModule = InputModules[self._currentInputCategory]
	local inputVector = inputModule:getInput(deltaTime)
	local isInputting = inputVector.Magnitude ~= 0

	-- When the player makes a camera input (right click + drag, thumbstick, etc.), the camera is
	-- switched to manual mode, allowing the player to move it around freely. After a few seconds
	-- without player input, the camera switches back to automatic mode, where it is aligned with
	-- the car's movement direction.
	if isInputting then
		self._isManualControl = true
		self._lastManualControl = os.clock()
		self._pitch = math.clamp(self._pitch - inputVector.Y, MIN_PITCH, MAX_PITCH)
		self._yaw = (self._yaw - inputVector.X) % (math.pi * 2)
	end

	if self._isManualControl then
		-- If in manual (i.e. player) control mode and no inputs have been made recently, reset
		-- back to automatic mode.
		local elapsed = os.clock() - self._lastManualControl
		if elapsed > RESET_TO_AUTOMATIC_TIME then
			self._isManualControl = false
		end
	else
		-- When in automatic mode, calculate the new pitch and yaw from the target direction
		local newPitch, newYaw = pitchAndYawFromDirection(targetVector)
		self._pitch, self._yaw = newPitch, newYaw
	end

	-- Update gimbal cframe
	local gimbalSpeed = if self._isManualControl then GIMBAL_SPEED_MANUAL else GIMBAL_SPEED_AUTOMATIC
	local newGimbalCFrame = CFrame.fromEulerAnglesYXZ(self._pitch, self._yaw, 0)
	self._gimbalCFrame = self._gimbalCFrame:Lerp(newGimbalCFrame, math.min(deltaTime * gimbalSpeed, 1))

	-- Update look ahead
	local lookAheadFactor = if self._isManualControl then 0 else 1
	local newLookAhead = targetVector * LOOK_AHEAD_AMOUNT * lookAheadFactor
	self._lookAhead = self._lookAhead:Lerp(newLookAhead, math.min(deltaTime * LOOK_AHEAD_SPEED, 1))

	-- Update trailing offset
	local trailingOffset = self._trailingOffset - (targetVector * deltaTime)
	self._trailingOffset = trailingOffset:Lerp(Vector3.zero, math.min(deltaTime * TRAILING_CATCHUP_SPEED, 1))
	-- Update virtual camera cframe
	local cameraSpeed = if self._isManualControl then CAMERA_SPEED_MANUAL else CAMERA_SPEED_AUTOMATIC
	local cameraPosition = self._trailingOffset
		+ Vector3.new(0, self._parameters.height, 0)
		+ self._gimbalCFrame:PointToWorldSpace(Vector3.new(0, 0, self._parameters.distance))
	local lookAheadPosition = self._lookAhead + Vector3.new(0, self._parameters.height * LOOK_AHEAD_HEIGHT_SCALE, 0)
	local newVirtualCameraCFrame = CFrame.lookAt(cameraPosition, lookAheadPosition, Vector3.yAxis)
	self._relativeCameraCFrame =
		self._relativeCameraCFrame:Lerp(newVirtualCameraCFrame, math.min(deltaTime * cameraSpeed, 1))

	-- Update actual camera cframe
	camera.CFrame = CFrame.new(self.chassis.Position) * self._relativeCameraCFrame
	camera.Focus = CFrame.new(self.chassis.Position)
end

function ChaseCamera._initializeValues(self: ControllersTypeClient.ChaseCamera)
	-- Initialize values so the camera is positioned correctly when the module is enabled
	self._gimbalCFrame = self.chassis.CFrame - self.chassis.CFrame.Position
	local chassisCFrame = CFrame.new(self.chassis.Position)
	self._relativeCameraCFrame = chassisCFrame:ToObjectSpace(camera.CFrame)
	self._trailingOffset = Vector3.zero
	self._lookAhead = Vector3.zero
end

function ChaseCamera:SetParameters(newParameters: ControllersTypeClient.ChaseCameraParams)
	self._parameters = newParameters
end

function ChaseCamera.Enable(self: ControllersTypeClient.ChaseCamera)
	if self._enabled then
		return
	end
	self._enabled = true

	self._lastInputCategoryChangedConnection = InputCategorizer.lastInputCategoryChanged:Connect(function(...)
		self:_onLastInputCategoryChanged(...)
	end)

	self:_onLastInputCategoryChanged(InputCategorizer.getLastInputCategory())
	self:_initializeValues()
	RunService:BindToRenderStep(RENDER_STEPPED_BIND_NAME, RENDER_STEPPED_BIND_PRIORITY, function(dt)
		self:_update(dt)
	end)
end

function ChaseCamera:Disable()
	if not self._enabled then
		return
	end
	self._enabled = false

	if self._lastInputCategoryChangedConnection then
		self._lastInputCategoryChangedConnection:Disconnect()
		self._lastInputCategoryChangedConnection = nil
	end

	-- Disable all InputModules
	for _, module in InputModules do
		module:disable()
	end

	RunService:UnbindFromRenderStep(RENDER_STEPPED_BIND_NAME)
end

-- Polymorphic Destroy: release Enable-time bindings (RenderStep, input modules)
-- even when destroyed mid-drive, then run the base cleanup.
function ChaseCamera.Destroy(self: ControllersTypeClient.ChaseCamera)
	self:Disable()
	ControllerBaseClient.Destroy(self)
end

return ChaseCamera
