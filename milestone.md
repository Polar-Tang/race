The car doesn't move. 
What moves the car?
basically the main line resposible for that is this one
```lua
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
```
engine is a Folder with WheelRRMotor, WheelRLMotor, WheelFRMotor, WheelFLMotor being a cylindrical constraint. Next from here everything are engine classes with attachments, we try to understand these engine classes, why they simulate a car using such attachments.
I try to copy all the engine classes while keeping their attachments relatives however the cart fly away from the map using the same parameters. We got the suffix for the wheel, let's see how we initialize the Engine Folder
```lua
local wheel_suffix = {
	"FL",
	"FR",
	"RL",
	"RR",
}
function CarInitializer._initializeEngineAtt(self: ControllersTypes.CarInitializer)

    local engine = self:ChangeChildren(self.car, "Engine", {
		ClassName = "Folder",
	})
	self.engine = engine

    -- we ensure creating for all the cyndrilical constraints
	for _, suffix in ipairs(wheel_suffix) do
		self:_ensureMotor(suffix)
	end
end

function CarInitializer._ensureMotor(self: ControllersTypes.CarInitializer, sufix: string)
	local spring_name = "Wheel" .. sufix .. "Motor" --WheelFLMotor
	if self.engine:FindFirstChild(spring_name) then
		return
	end

	local wheelMotor = Instance.new("CylindricalConstraint", self.engine)
	wheelMotor.Size = 0.15
	wheelMotor.Visible = false
	wheelMotor.Color = BrickColor.Yellow()
	wheelMotor.Name = spring_name
	wheelMotor.AngularVelocity = 0
	wheelMotor.MotorMaxAngularAcceleration = 500000
	wheelMotor.MotorMaxTorque = 10000
	wheelMotor.InclinationAngle = 90
	wheelMotor.AngularLimitsEnabled = false
	wheelMotor.AngularActuatorType = Enum.ActuatorType.Motor

	local wheel_name = "Wheel" .. sufix
	local the_wheel_model = assert(self._Wheels:FindFirstChild(wheel_name), " create a wheel model")
	--[[
	Wheel<suffix> Model
		Wheel Part
		Knuckle Part (only for start f suffix wheels)
		Mount Part
	]]

	local Knuckle = self:_ensureKnuckle(sufix)
	local Mount = the_wheel_model:FindFirstChild("Mount")
	print(Knuckle, " Knuckle")
	print(Mount, " Mount")

	-- uses the knuckle if is a fron wheel, otherwises uses the Mount wheel
	wheelMotor.Attachment0 = (
		if sufix:sub(1, 1) == "F"
			then self:ChangeChildren(Knuckle, "MotorAttachment")
			else self:ChangeChildren(Mount, "MotorAttachment")
	)

	local wheel_part = the_wheel_model:FindFirstChild("Wheel")

	wheelMotor.Attachment1 = self:ChangeChildren(wheel_part, "MotorAttachment")
end
```
What's a Knuckle and Mount in a real car? what are important to simulate the car phisics on roblox?
-- Understanding why the antiroll, why is a constraint 