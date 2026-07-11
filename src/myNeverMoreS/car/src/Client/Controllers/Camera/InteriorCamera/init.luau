--[[
	The InteriorCamera mimics a driver's view, turning slightly in tandem with the steering and
	looking back over the shoulder while reversing.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ControllerBaseClient = require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllerBaseClient)
local ControllersTypeClient = require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllersTypeClient)
local CarConstants = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.CarConstants)
local lerp = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.lerp)
local setCharacterVisible = require(script.setCharacterVisible)

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local RENDER_STEPPED_BIND_NAME = "CarInteriorCamera"
local RENDER_STEPPED_BIND_PRIORITY = Enum.RenderPriority.Camera.Value

local HEAD_TURN_SPEED = 4
local HEAD_ALIGN_SPEED = 30
local KEEP_UPRIGHT_PROPORTION = 0.2
local REVERSE_SPEED_THRESHOLD = 10

local InteriorCamera = setmetatable({}, ControllerBaseClient)
InteriorCamera.__index = InteriorCamera
InteriorCamera.ClassName = "InteriorCamera"

function InteriorCamera.new(config: ControllersTypeClient.ControllConstructor): ControllersTypeClient.InteriorCamera
	local self = setmetatable(ControllerBaseClient.new(config), InteriorCamera)

	self._forwardVector = Vector3.zero
	self._upVector = Vector3.zero
	self._headTurnAngle = 0

	self._enabled = false
	self._parameters = {
		attachment = nil,
		forwardHeadTurnAngle = 0,
		reverseHeadTurnAngle = 0,
	}

	self._gui = nil
	self._heartbeatConnection = nil

	return self
end

function InteriorCamera._update(self: ControllersTypeClient.InteriorCamera, deltaTime: number)
	local steeringInput = self.inputs:GetAttribute(CarConstants.STEERING_INPUT_ATTRIBUTE)
	local throttleInput = self.inputs:GetAttribute(CarConstants.THROTTLE_INPUT_ATTRIBUTE)
	local chassisLocalVelocity = self.chassis.CFrame:VectorToObjectSpace(self.chassis.AssemblyLinearVelocity)

	local targetHeadTurnAngle = steeringInput * self._parameters.forwardHeadTurnAngle

	-- If the throttle is in reverse and the car is actually moving backwards, turn the camer around.
	-- Note: because of the way CFrames are constructed, chassisLocalVelocity.Z is positive when the
	-- car is moving backward and negative when it is moving forward.
	if chassisLocalVelocity.Z > REVERSE_SPEED_THRESHOLD and throttleInput < 0 then
		targetHeadTurnAngle = self._parameters.reverseHeadTurnAngle
	end
	self._headTurnAngle = lerp(self._headTurnAngle, targetHeadTurnAngle, math.min(deltaTime * HEAD_TURN_SPEED, 1))

	-- Update the forward and up vectors
	local targetForwardVector = self._parameters.attachment.WorldCFrame.LookVector
	self._forwardVector = self._forwardVector:Lerp(targetForwardVector, math.min(deltaTime * HEAD_ALIGN_SPEED, 1))
	local targetUpVector = self._parameters.attachment.WorldCFrame.UpVector:Lerp(Vector3.yAxis, KEEP_UPRIGHT_PROPORTION)
	self._upVector = self._upVector:Lerp(targetUpVector, math.min(deltaTime * HEAD_ALIGN_SPEED, 1))

	-- Construct a cframe using the forward and up vectors, then apply headTurnAngle on top
	local centerPosition = self._parameters.attachment.WorldCFrame.Position
	local centerCFrame = CFrame.lookAt(centerPosition, centerPosition + self._forwardVector, self._upVector)
	camera.CFrame = centerCFrame * CFrame.Angles(0, -self._headTurnAngle, 0)
end

function InteriorCamera._initializeValues(self: ControllersTypeClient.InteriorCamera)
	self._forwardVector = self.chassis.CFrame.LookVector
	self._upVector = self.chassis.CFrame.UpVector
	self._headTurnAngle = 0
end

function InteriorCamera.SetParameters(self: ControllersTypeClient.InteriorCamera ,newParameters: ControllersTypeClient.InteriorCameraParams)
	self._parameters = newParameters
end

function InteriorCamera.Enable(self: ControllersTypeClient.InteriorCamera)
	if self._enabled then
		return
	end
	self._enabled = true

	self:_initializeValues()

	RunService:BindToRenderStep(RENDER_STEPPED_BIND_NAME, RENDER_STEPPED_BIND_PRIORITY, function(deltaTime)
self:_update(deltaTime)
	end)

	-- Because the default camera scripts change character transparency every frame,
	-- this must be deferred so it runs after the camera code is complete.
	task.defer(function()
		local character = player.Character
		if character then
			setCharacterVisible(character, false)
		end
	end)
end

function InteriorCamera.Disable(self: ControllersTypeClient.InteriorCamera)
	if not self._enabled then
		return
	end
	self._enabled = false

	RunService:UnbindFromRenderStep(RENDER_STEPPED_BIND_NAME)

	local character = player.Character
	if character then
		setCharacterVisible(character, true)
	end
end

-- Polymorphic Destroy: release the RenderStep binding and restore character
-- visibility even when destroyed mid-drive, then run the base cleanup.
function InteriorCamera.Destroy(self: ControllersTypeClient.InteriorCamera)
	self:Disable()
	ControllerBaseClient.Destroy(self)
end

return InteriorCamera
