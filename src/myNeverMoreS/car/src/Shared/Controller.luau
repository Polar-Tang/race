local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControllerBaseClient =
	require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllerBaseClient)
local ControllersTypeClient =
	require(ReplicatedStorage.Nevermore.Custom.car.src.Client.ControllersUtils.ControllersTypeClient)
local Constants = require(script.Parent.CarConstants)
local Units = require(script.Parent.Units)
local lerp = require(script.Parent.lerp)

local engineParameters: { [string]: number } = {
	forwardMaxSpeed = 0,
	reverseMaxSpeed = 0,
	acceleration = 0,
	deceleration = 0,
	braking = 0,
	engineSpeedCorrection = 0,
	minSpeedTorque = 0,
	maxSpeedTorque = 0,
	handBrakeTorque = 0,
	nitroTorque = 0,
	nitroTime = 0,
	nitroRechargeTime = 0,
	nitroMaxSpeed = 0,
	nitroAcceleration = 100,
}

local steeringParameters: { [string]: number } = {
	steeringReduction = 0,
}

local wheelParameters: { [string]: number } = {
	density = 0, -- Wheel density
	elasticity = 0, -- Wheel elasticity
	staticFriction = 0, -- Wheel friction while it is not sliding
	kineticFriction = 0, -- Wheel friction while it is sliding
	slipThreshold = 0, -- Threshold for the wheel to start sliding
}

local DriveController = setmetatable({}, ControllerBaseClient)
DriveController.__index = DriveController
DriveController.ClassName = "DriveController"

function DriveController.new(config: ControllersTypeClient.ControllConstructor)
	local self = setmetatable(ControllerBaseClient.new(config), DriveController) :: ControllersTypeClient.ControllerBase

	self.wheels = self.car.Wheels
	self.steering = self.car.Steering

	self._engineParameters = table.clone(engineParameters)
	self._steeringParameters = table.clone(steeringParameters)
	self._wheelParameters = table.clone(wheelParameters)

	self._wheelParts = {
		self.wheels.WheelFR.Wheel,
		self.wheels.WheelFL.Wheel,
		self.wheels.WheelRR.Wheel,
		self.wheels.WheelRL.Wheel,
	}
	-- Calculate wheel radius based on the front right wheel
	self._wheelRadius = self._wheelParts[1].Size.Y / 2

	self._steeringRack = self.steering:FindFirstChild("SteeringRack")
	return self
end

-- Return the current chassis speed on the local Z axis in miles per hour
function DriveController.getChassisForwardSpeed(self: ControllersTypeClient.DriverController): number
	local relativeVelocity = self.chassis.CFrame:VectorToObjectSpace(self.chassis.AssemblyLinearVelocity)
	local milesPerHour = Units.studsPerSecondToMilesPerHour(-relativeVelocity.Z)
	return milesPerHour
end

-- Update the amount of nitro available
function DriveController.updateNitro(self: ControllersTypeClient.DriverController, deltaTime: number)
	local nitroInput = self.inputs:GetAttribute(Constants.NITRO_INPUT_ATTRIBUTE)
	local engineNitro = self.engine:GetAttribute(Constants.ENGINE_NITRO_ATTRIBUTE)
	local isNitroEnabled = nitroInput and engineNitro > 0
	-- If the nitro input is enabled, lower the nitro level
	if isNitroEnabled then
		local amount = 1 / self._engineParameters.nitroTime
		engineNitro = math.max(engineNitro - amount * deltaTime, 0)
		-- If the nitro level reaches 0, disable the nitro input
		if engineNitro == 0 then
			self.inputs:SetAttribute(Constants.NITRO_INPUT_ATTRIBUTE, false)
			nitroInput = false
		end
	else
		-- Recharge the nitro level
		local amount = 1 / self._engineParameters.nitroRechargeTime
		engineNitro = math.min(engineNitro + amount * deltaTime, 1)
	end
	self.engine:SetAttribute(Constants.ENGINE_NITRO_ATTRIBUTE, engineNitro)

	self.engine:SetAttribute(Constants.NITRO_ENABLED_ATTRIBUTE, isNitroEnabled)

	-- Update the nitro constraint
	local NitroVelocity = assert(self.engine:FindFirstChild("NitroVelocity"))
	NitroVelocity.Enabled = isNitroEnabled
	NitroVelocity.VectorVelocity = Vector3.new(0, 0, -self._engineParameters.nitroMaxSpeed)
end

-- Update the car's target speed and wheel motors' torque and angular velocity
function DriveController.updateEngine(self: ControllersTypeClient.DriverController, deltaTime: number)
	local handBrakeInput = self.inputs:GetAttribute(Constants.HAND_BRAKE_INPUT_ATTRIBUTE)
	local throttleInput = self.inputs:GetAttribute(Constants.THROTTLE_INPUT_ATTRIBUTE)
	throttleInput = math.clamp(throttleInput, -1, 1)
	local throttleDirection = math.sign(throttleInput)
	local engineSpeed = self.engine:GetAttribute(Constants.ENGINE_SPEED_ATTRIBUTE)
	local isNitroEnabled = self.engine:GetAttribute(Constants.NITRO_ENABLED_ATTRIBUTE)
	local maxSpeed = math.max(self._engineParameters.forwardMaxSpeed, self._engineParameters.reverseMaxSpeed)
	local targetSpeed = throttleInput
		* (
			if throttleDirection >= 0
				then self._engineParameters.forwardMaxSpeed
				else self._engineParameters.reverseMaxSpeed
		)
	local forwardSpeed = self:getChassisForwardSpeed()
	local isBraking = throttleDirection ~= 0
		and math.abs(forwardSpeed) > 1
		and throttleDirection ~= math.sign(forwardSpeed)
	local acceleration = self._engineParameters.acceleration

	-- Adjust the acceleration based on whether the car is using nitro, braking, or slowing down
	if isNitroEnabled then
		acceleration = self._engineParameters.nitroAcceleration
		targetSpeed = self._engineParameters.nitroMaxSpeed
	elseif isBraking then
		-- When the car is switching directions, we apply braking until it comes to a stop.
		-- This is essentially engine braking, and accelerates the engine speed to 0.
		acceleration = self._engineParameters.braking
		targetSpeed = 0
	elseif math.abs(targetSpeed) < math.abs(engineSpeed) then
		-- When the car is slowing down in either direction, we use a separate deceleration
		-- parameter to slow the car down slowly, rather than using the higher acceleration value.
		-- This allows the car to glide to a stop when releasing the throttle.
		acceleration = self._engineParameters.deceleration
	end

	-- Proportionally adjust the engine speed towards the car's actual speed. This prevents the
	-- wheels from continuing to spin after e.g. the car runs into a wall and stops suddenly.
	engineSpeed = lerp(engineSpeed, forwardSpeed, math.min(deltaTime * self._engineParameters.engineSpeedCorrection, 1))
	if targetSpeed > engineSpeed then
		engineSpeed = math.min(engineSpeed + acceleration * deltaTime, targetSpeed)
	else
		engineSpeed = math.max(engineSpeed - acceleration * deltaTime, targetSpeed)
	end
	self.engine:SetAttribute(Constants.ENGINE_SPEED_ATTRIBUTE, engineSpeed)

	-- Calculate the torque and angular velocity required to reach the target linear velocity
	local chassisSpeed = self:getChassisForwardSpeed()
	local torqueAlpha = math.min(chassisSpeed, maxSpeed) / maxSpeed
	local torque = lerp(self._engineParameters.minSpeedTorque, self._engineParameters.maxSpeedTorque, torqueAlpha)
	if isNitroEnabled then
		torque = self._engineParameters.nitroTorque
	end
	local studsSpeed = Units.milesPerHourToStudsPerSecond(engineSpeed)
	local angularVelocity = studsSpeed / self._wheelRadius
	-- Update the wheel motor constraints
	local engine = self.engine
	engine.WheelFRMotor.AngularVelocity = angularVelocity
	engine.WheelFRMotor.MotorMaxTorque = torque
	engine.WheelFLMotor.AngularVelocity = -angularVelocity
	engine.WheelFLMotor.MotorMaxTorque = torque
	if handBrakeInput then
		engine.WheelRRMotor.AngularVelocity = 0
		engine.WheelRRMotor.MotorMaxTorque = self._engineParameters.handBrakeTorque
		engine.WheelRLMotor.AngularVelocity = 0
		engine.WheelRLMotor.MotorMaxTorque = self._engineParameters.handBrakeTorque
	else
		engine.WheelRRMotor.AngularVelocity = angularVelocity
		engine.WheelRRMotor.MotorMaxTorque = torque
		engine.WheelRLMotor.AngularVelocity = -angularVelocity
		engine.WheelRLMotor.MotorMaxTorque = torque
	end
	print(torque, "torque")
	print("angularVelocity", angularVelocity)
end

-- Update the steering rack position based on the steering input and current speed of the car
function DriveController.updateSteering(self: ControllersTypeClient.DriverController)
	local steerInput = self.inputs:GetAttribute(Constants.STEERING_INPUT_ATTRIBUTE)
	local steeringInput = math.clamp(steerInput, -1, 1)
	local maxSpeed = math.max(self._engineParameters.forwardMaxSpeed, self._engineParameters.reverseMaxSpeed)
	local speed = math.min(self:getChassisForwardSpeed(), maxSpeed)
	-- Steering is reduced at higher speeds to provide smoother handling
	local steeringFactor = math.max(1 - (speed / maxSpeed) * self._steeringParameters.steeringReduction, 0)
	local steeringAmount = steeringInput * steeringFactor

	if steeringAmount > 0 then
		self._steeringRack.TargetPosition = steeringAmount * self._steeringRack.LowerLimit
	else
		self._steeringRack.TargetPosition = -steeringAmount * self._steeringRack.UpperLimit
	end
end

function DriveController.updateWheelFriction(self: ControllersTypeClient.DriverController)
	for _, wheelPart in self._wheelParts do
		-- Find the difference between the wheel's actual linear speed and the speed it should be moving
		-- based on its current angular velocity.
		local speed = wheelPart.AssemblyLinearVelocity.Magnitude
		local angularVelocity = wheelPart.AssemblyAngularVelocity
		local targetSpeed = self._wheelRadius * angularVelocity.Magnitude
		local speedDiff = math.abs(speed - targetSpeed)

		local isKineticFriction = speedDiff > self._wheelParameters.slipThreshold
		local friction = if isKineticFriction
			then self._wheelParameters.kineticFriction
			else self._wheelParameters.staticFriction
		wheelPart.CustomPhysicalProperties =
			PhysicalProperties.new(self._wheelParameters.density, friction, self._wheelParameters.elasticity)
	end
end

function DriveController.initialize(self: ControllersTypeClient.DriverController)
	-- Cache all parameters in tables and update them when the corresponding Attribute updates.
	-- Parameters aren't going to change very often so there's no reason to call :GetAttribute() constantly.

	for parameter in engineParameters do
		self.engine:GetAttributeChangedSignal(parameter):Connect(function()
			local newAtt = self.engine:GetAttribute(parameter)
			self._engineParameters[parameter] = newAtt
		end)
		local newAtt = self.engine:GetAttribute(parameter)
		self._engineParameters[parameter] = newAtt
		print("self._engineParameters[parameter] ", self._engineParameters[parameter])
		print("parameter ", parameter)
	end

	for parameter in steeringParameters do
		self._maid:GiveTask(self.steering:GetAttributeChangedSignal(parameter):Connect(function()
			local newAtt = self.steering:GetAttribute(parameter)
			self._steeringParameters[parameter] = newAtt
		end))
		self._maid:GiveTask(self.steering:GetAttributeChangedSignal(parameter):Connect(function()
			local wheelAtt = self.steering:GetAttribute(parameter)
			self._steeringParameters[parameter] = wheelAtt
		end))
	end

	for parameter in wheelParameters do
		self._maid:GiveTask(self.wheels:GetAttributeChangedSignal(parameter):Connect(function()
			local newAtt = self.wheels:GetAttribute(parameter)
			self._wheelParameters[parameter] = newAtt
		end))
		local newAtt = self.wheels:GetAttribute(parameter)
		self._wheelParameters[parameter] = newAtt
	end
end

function DriveController.reset(self: ControllersTypeClient.DriverController)
	local engine = self.engine
	-- Reset engine attributes
	engine:SetAttribute(Constants.ENGINE_SPEED_ATTRIBUTE, 0)
	engine:SetAttribute(Constants.ENGINE_NITRO_ATTRIBUTE, 1)
	-- Reset motors
	engine.WheelFRMotor.AngularVelocity = 0
	engine.WheelFRMotor.MotorMaxTorque = self._engineParameters.minSpeedTorque
	engine.WheelFLMotor.AngularVelocity = 0
	engine.WheelFLMotor.MotorMaxTorque = self._engineParameters.minSpeedTorque
	engine.WheelRRMotor.AngularVelocity = 0
	engine.WheelRRMotor.MotorMaxTorque = self._engineParameters.minSpeedTorque
	engine.WheelRLMotor.AngularVelocity = 0
	engine.WheelRLMotor.MotorMaxTorque = self._engineParameters.minSpeedTorque
	-- Reset nitro
	engine.NitroVelocity.Enabled = false
	-- Reset steering
	self._steeringRack.TargetPosition = 0
	-- Reset wheel friction
	for _, wheelPart in self._wheelParts do
		wheelPart.CustomPhysicalProperties = PhysicalProperties.new(
			self._wheelParameters.density,
			self._wheelParameters.staticFriction,
			self._wheelParameters.elasticity
		)
	end
end

function DriveController.update(self: ControllersTypeClient.DriverController, deltaTime: number)
	self:updateNitro(deltaTime)
	self:updateEngine(deltaTime)
	self:updateSteering()
	self:updateWheelFriction()
end

return DriveController
