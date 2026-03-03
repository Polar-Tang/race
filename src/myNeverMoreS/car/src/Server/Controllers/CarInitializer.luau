local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbsController = require(ReplicatedStorage.Nevermore.Custom.car.src.Server.Controllers.utils.AbsController)
local ControllersTypes = require(ReplicatedStorage.Nevermore.Custom.car.src.Server.Controllers.utils.ControllersTypes)
local default_stats = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.default_stats)

local CarInitializer = setmetatable({}, AbsController)
CarInitializer.__index = CarInitializer
CarInitializer.ClassName = "CarInitializer"

function CarInitializer.new(config: ControllersTypes.ControllConstructor): ControllersTypes.CarInitializer
	local self = setmetatable(AbsController.new(config), CarInitializer)

	self._steering = self.car:FindFirstChild("Steering")
	self._suspension = self.car:FindFirstChild("Suspension")
	self._antiRoll = self.car:FindFirstChild("AntiRoll")
	self._redress = self.car:FindFirstChild("Redress")
	self._Wheels = self.car:FindFirstChild("Wheels")
	self.wheels_parametes = {}
	return self
end

function CarInitializer._createInstance(Parent: BasePart | Model, Name: string, properties): Attachment
	local newAttacment =
		Instance.new(if properties and properties.ClassName then properties.ClassName else "Attachment")
	newAttacment.Name = Name
	if properties then
		for key, value in pairs(properties) do
			print("key ", key)
			if key == "ClassName" then
				continue
			end
			newAttacment[key] = value
		end
		print("newAttacment ", newAttacment)
	end
	newAttacment.Parent = Parent
	return newAttacment
end

local function ensureAtt(folder: Folder, attName: string, parentName: ControllersTypes.parentType)
	local att = folder:GetAttribute(attName)
	if not att then
		local car_stats = table.clone(default_stats)
		att = car_stats[parentName][attName]
		folder:SetAttribute(attName, att)
	end

	return assert(att, "invalid attribute '" .. attName .. "' on " .. parentName)
end

function CarInitializer._ensureAtt(
	self: ControllersTypes.CarInitializer,
	attName: string,
	parent: ControllersTypes.parentType
): number
	if parent == "suspension" then
		return ensureAtt(self._suspension, attName, parent)
	end
	if parent == "antiRoll" then
		return ensureAtt(self._antiRoll, attName, parent)
	end
	if parent == "steering" then
		return ensureAtt(self._steering, attName, parent)
	end
	if parent == "redress" then
		return ensureAtt(self._redress, attName, parent)
	end
	if parent == "engine" then
		return ensureAtt(self.engine, attName, parent)
	end

	if parent == "wheels_parametes" then
		return ensureAtt(self._Wheels, attName, parent)
	end
	warn("Invalid parent name ", parent)
	return 0
end

function CarInitializer._ensureKnuckle(self: ControllersTypes.CarInitializer, sufix: string)
	local suffix = sufix:lower()
	if suffix:sub(1, 1) ~= "f" then
		return
	end
	local rightSuffix = "F" .. sufix:sub(2)

	local wheel_name = "Wheel" .. rightSuffix
	local the_wheel = assert(self._Wheels:FindFirstChild(wheel_name), " create a wheel model")
	local Knuckle = assert(the_wheel:FindFirstChild("Knuckle"), " wheel '" .. wheel_name .. "' must have Knuckles")

	local Mount = assert(the_wheel:FindFirstChild("Mount"), " wheel '" .. wheel_name .. "' must have Mount")
	local HingeAttachmentMount = self:ChangeChildren(Mount, "HingeAttachment")
	local HingeAttachmentKnuckle = self:ChangeChildren(Knuckle, "HingeAttachment")

	local hingeCOnstraint = self:ChangeChildren(Knuckle, "HingeConstraint", {
		ClassName = "HingeConstraint",
		LowerAngle = -60,
		UpperAngle = 60,
		Restitution = 0,
		Attachment0 = HingeAttachmentMount,
		Attachment1 = HingeAttachmentKnuckle,
		ActuatorType = Enum.ActuatorType.None,
	})
	print("hingeCOnstraint ", hingeCOnstraint)
	print("Attachment0 ", hingeCOnstraint.Attachment0)

	return Knuckle
end

function CarInitializer._ensureSteerRack(self: ControllersTypes.CarInitializer, sufix: string)
	local SteeringRack = assert(self.car:FindFirstChild("SteeringRack"), "Cars should have an 'SteeringRack'")

	print(SteeringRack)
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
	wheelModel
		Wheel
		Knuckle (only for start f suffix wheels)
		Mount
	]]

	local Knuckle = self:_ensureKnuckle(sufix)
	local Mount = the_wheel_model:FindFirstChild("Mount")
	print(Knuckle, " Knuckle")
	print(Mount, " Mount")

	-- uses the knuckle if is a fron wheel, otherwises uses the Mount wheel
	-- Attachment world cframe most be the same
	local wheel_part = the_wheel_model:FindFirstChild("Wheel")
	local properties = {
		WorldPosition = wheel_part.Position,
		Axis = Vector3.new(-0, 1, 0),
	}
	wheelMotor.Attachment0 = (
		if sufix:sub(1, 1) == "F"
			then self:ChangeChildren(Knuckle, "MotorAttachment", properties)
			else self:ChangeChildren(Mount, "MotorAttachment", properties)
	)


	wheelMotor.Attachment1 = self:ChangeChildren(wheel_part, "MotorAttachment", {
		WorldPosition = wheel_part.Position,
		Axis = Vector3.new(-1, 0, 0),
	})
	print(wheelMotor.Attachment0.WorldPosition)
	print(wheelMotor.Attachment1.WorldPosition)
end

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

	local nitroV = Instance.new("LinearVelocity", self.engine)
	nitroV.MaxForce = 10000
	nitroV.Visible = false
	nitroV.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
	nitroV.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	nitroV.ForceLimitMode = Enum.ForceLimitMode.Magnitude
	nitroV.Attachment0 = self:ChangeChildren(self.chassis, "NitroAttachment")
	nitroV.Name = "NitroVelocity"

	for _, suffix in ipairs(wheel_suffix) do
		self:_ensureMotor(suffix)
	end
	local engine_parameters = {}
	local engine_stats = table.clone(default_stats["engine"])
	for key, _ in pairs(engine_stats) do
		engine_parameters[key] = self:_ensureAtt(key, "engine")
	end
	return engine_parameters
end

function CarInitializer.ChangeChildren(self, parent: Model | BasePart, childName: string, properties)
	if childName == "MotorAttachment" then
		print()
	end
	local attachment = parent:FindFirstChild(childName)
	if not attachment then
		attachment = self._createInstance(parent, childName, properties)
		print("return attachment ", attachment)
	end

	return attachment
end

function CarInitializer._ensureSpringConstraing(self: ControllersTypes.CarInitializer, sufix: string)
	local spring_name = "Wheel" .. sufix .. "Suspension"
	if self._suspension:FindFirstChild(spring_name) then
		--print("Omitting create springs")
		return
	end
	local sppring = Instance.new("SpringConstraint", self._suspension)
	sppring.Coils = 8
	sppring.Color = BrickColor.Yellow()
	sppring.Radius = 0.2
	sppring.Thickness = 0.15
	sppring.Visible = false
	sppring.Name = spring_name

	local wheel_name = "Wheel" .. sufix
	local the_wheel = assert(self._Wheels:FindFirstChild(wheel_name), " create a wheel model")
	local mount = assert(the_wheel:FindFirstChild("Mount"), " wheel '" .. wheel_name .. "' must have mounts")
	sppring.Attachment0 = self:ChangeChildren(mount, "SpringAttachment")

	local wheel_part = the_wheel:FindFirstChild("Wheel")
	sppring.Attachment1 = self:ChangeChildren(wheel_part, "MotorAttachment")

	
	local no_collide_chassis = Instance.new("NoCollisionConstraint")
	no_collide_chassis.Part0 = self.chassis
	no_collide_chassis.Part1 = wheel_part
end

function CarInitializer._ensureSteeringRack(self: ControllersTypes.CarInitializer)
	local Steering = self:ChangeChildren(self.car, "Steering", {
		ClassName = "Folder",
	})
	self._steering = Steering

	local SteeringRack = Steering:FindFirstChild("SteeringRack")
	if SteeringRack then
		--print("omiting steering initailization")
		return
	end
	SteeringRack = Instance.new("PrismaticConstraint", Steering)
	SteeringRack.Size = 0.15
	SteeringRack.Visible = false
	SteeringRack.LinearResponsiveness = 30
	SteeringRack.ServoMaxForce = 500000
	SteeringRack.Speed = 10
	SteeringRack.TargetPosition = 0
	SteeringRack.ActuatorType = Enum.ActuatorType.Servo
	SteeringRack.LimitsEnabled = true
	SteeringRack.Visible = false
	SteeringRack.Name = "SteeringRack"

	SteeringRack.Attachment0 = self:ChangeChildren(self.chassis, "SteeringAttachment")
	local steerRack = self.car:FindFirstChild("SteeringRack")
	SteeringRack.Attachment1 = self:ChangeChildren(steerRack, "SteeringAttachment")
end

function CarInitializer._initSteering(self: ControllersTypes.CarInitializer)
	self:_ensureSteeringRack()

	return {
		steeringRackLength = self:_ensureAtt("steeringRackLength", "steering"),
		steeringRackResponsiveness = self:_ensureAtt("steeringRackResponsiveness", "steering"),
		steeringRackSpeed = self:_ensureAtt("steeringRackSpeed", "steering"),
		steeringRackMaxForce = self:_ensureAtt("steeringRackMaxForce", "steering"),
	}
end

function CarInitializer._initSuspension(self: ControllersTypes.CarInitializer)
	local Suspension = self:ChangeChildren(self.car, "Suspension", {
		ClassName = "Folder",
	})
	self._suspension = Suspension

	local wheelsParameters = {}
	local wheels_parametes = table.clone(default_stats["wheels_parametes"])
	for key, _ in pairs(wheels_parametes) do
		wheelsParameters[key] = self:_ensureAtt(key, "wheels_parametes")
	end

	for _, suffix in ipairs(wheel_suffix) do
		self:_ensureSpringConstraing(suffix)
	end

	return {
		frontSuspensionLength = self:_ensureAtt("frontSuspensionLength", "suspension"),
		frontSuspensionStiffness = self:_ensureAtt("frontSuspensionStiffness", "suspension"),
		frontSuspensionDamping = self:_ensureAtt("frontSuspensionDamping", "suspension"),
		rearSuspensionLength = self:_ensureAtt("rearSuspensionLength", "suspension"),
		rearSuspensionStiffness = self:_ensureAtt("rearSuspensionStiffness", "suspension"),
		rearSuspensionDamping = self:_ensureAtt("rearSuspensionDamping", "suspension"),
		frontCamber = self:_ensureAtt("frontCamber", "suspension"),
		rearCamber = self:_ensureAtt("rearCamber", "suspension"),
	}
end

function CarInitializer._ensureAntirollbar(self: ControllersTypes.CarInitializer, sufix: string)
	local suffix = sufix:lower()
	local antiroll_name = "AntiRollBar" .. "F"
	if suffix:sub(1, 1) == "f" then
		antiroll_name = "AntiRollBar" .. "F"
	elseif suffix:sub(1, 1) == "r" then
		antiroll_name = "AntiRollBar" .. "R"
	end
	local antiroll_bar = self.car:FindFirstChild(antiroll_name)
	assert(antiroll_bar, "create an " .. antiroll_name)
	return antiroll_bar
end

function CarInitializer._ensureAntiroll(self: ControllersTypes.CarInitializer, sufix: string)
	local antiroll_bar = self:_ensureAntirollbar(sufix)

	local antiroll_folder = self:ChangeChildren(self.car, "AntiRoll", {
		ClassName = "Folder",
	})
	self._antiRoll = antiroll_folder

	local antiroll_bar_name = "AntiRollBar" .. sufix

	local sppring = self._antiRoll:FindFirstChild(antiroll_bar_name)
	if not sppring then
		sppring = Instance.new("SpringConstraint", self._antiRoll)
		sppring.Damping = 100
		sppring.FreeLength = 2.326
		sppring.LimitsEnabled = false
		sppring.MaxForce = 50
		sppring.Stiffness = 16000

		sppring.Coils = 0
		sppring.Color = BrickColor.Yellow()
		sppring.Radius = 0
		sppring.Thickness = 0.15
		sppring.Visible = false
		sppring.Name = antiroll_bar_name
	end

	sppring.Attachment0 = self:ChangeChildren(antiroll_bar, "LeftSpringAttachment")

	local wheel_name = "Wheel" .. sufix
	local the_wheel = assert(self._Wheels:FindFirstChild(wheel_name), " create a wheel model")
	local wheel_part =
		assert(the_wheel:FindFirstChild("Wheel"), " '" .. wheel_name .. "' model should have a 'Wheel' part")
	print("fucking wheel_part", wheel_part)
	sppring.Attachment1 = self:ChangeChildren(wheel_part, "MotorAttachment") --wheel_part.MotorAttachment
end

function CarInitializer._initAntiRoll(self: ControllersTypes.CarInitializer): ControllersTypes.antiRoll
	for _, suffix in ipairs(wheel_suffix) do
		self:_ensureAntiroll(suffix)
	end
	return {
		frontAntiRollBarDamping = self:_ensureAtt("frontAntiRollBarDamping", "antiRoll"),
		frontAntiRollBarStiffness = self:_ensureAtt("frontAntiRollBarStiffness", "antiRoll"),
		rearAntiRollBarStiffness = self:_ensureAtt("rearAntiRollBarStiffness", "antiRoll"),
		rearAntiRollBarDamping = self:_ensureAtt("rearAntiRollBarDamping", "antiRoll"),
	}
end

function CarInitializer._ensureChasisShit(self: ControllersTypes.CarInitializer)
	assert(self.chassis, "vehicle must have 'Chassis'")
	self:ChangeChildren(self.chassis, "HoodCameraAttachment", {
		CFrame = CFrame.new(Vector3.new(0, 3, -3)),
	})

	self:ChangeChildren(self.chassis, "InteriorCameraAttachment", {
		CFrame = CFrame.new(Vector3.new(-1.5, 3, 0)),
	})
end

function CarInitializer._initRedress(self: ControllersTypes.CarInitializer)
	if not self._redress then
		local redress_folder = self:ChangeChildren(self.car, "Redress", {
			ClassName = "Folder",
		})
		self._redress = redress_folder
	end

	local RedressOrientation = Instance.new("AlignOrientation", self._redress)
	RedressOrientation.Name = "RedressOrientation"
	RedressOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	RedressOrientation.AlignType = Enum.AlignType.AllAxes
	RedressOrientation.ReactionTorqueEnabled = false
	RedressOrientation.RigidityEnabled = false
	RedressOrientation.MaxTorque = 500000
	RedressOrientation.Responsiveness = 10

	RedressOrientation.Attachment0 = self:ChangeChildren(self.chassis, "FlipperAttachment")
	local redress_params = {}
	local engine_stats = table.clone(default_stats["redress"])
	for key, _ in pairs(engine_stats) do
		redress_params[key] = self:_ensureAtt(key, "redress")
	end
	return redress_params
end

function CarInitializer._initFolder(self: ControllersTypes.CarInitializer)
	-- TODO: may ensure folder exists and it has their attributes
	self:_ensureChasisShit()
	local steering = self:_initSteering()

	local suspension = self:_initSuspension()

	local antiRoll = self:_initAntiRoll()

	local redress = self:_initRedress()
	self.config = {
		["suspension"] = suspension,
		["antiRoll"] = antiRoll,
		["steering"] = steering,
		["redress"] = redress,
	}
end

function CarInitializer.Init(self: ControllersTypes.CarInitializer)
	self:_initFolder()
	self:_initializeEngineAtt()
end

return CarInitializer
