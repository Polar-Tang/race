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

	return self
end

function CarInitializer._createInstance(Parent: BasePart | Model, Name: string, properties): Attachment
	local newAttacment =
		Instance.new(if properties and properties.ClassName then properties.ClassName else "Attachment")
	newAttacment.Name = Name
	newAttacment.Parent = Parent
	if properties then
		if properties.CFrame then
			newAttacment.CFrame = properties.CFrame
		end
	end
	return newAttacment
end

local function ensureAtt(folder: Folder, attName: string, parentName: ControllersTypes.parentType)
	local att = folder:GetAttribute(attName)
	if not att then
		att = default_stats[parentName][attName]
		folder:SetAttribute(attName, att)
	end

	return assert(att, "invalid attribute '", attName, "'")
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
	warn("Invalid parent name ", parent)
	return 0
end

function CarInitializer._initializeEngineAtt(self)
	local enginge = {
		forwardMaxSpeed = self:_ensureAtt("forwardMaxSpeed"),
		reverseMaxSpeed = self:_ensureAtt("reverseMaxSpeed"),
		acceleration = self:_ensureAtt("acceleration"),
		deceleration = self:_ensureAtt("deceleration"),
		braking = self:_ensureAtt("braking"),
		engineSpeedCorrection = self:_ensureAtt("engineSpeedCorrection"),
		minSpeedTorque = self:_ensureAtt("minSpeedTorque"),
		maxSpeedTorque = self:_ensureAtt("maxSpeedTorque"),
		handBrakeTorque = self:_ensureAtt("handBrakeTorque"),
		nitroTorque = self:_ensureAtt("nitroTorque"),
		nitroTime = self:_ensureAtt("nitroTime"),
		nitroRechargeTime = self:_ensureAtt("nitroRechargeTime"),
		nitroMaxSpeed = self:_ensureAtt("nitroMaxSpeed"),
		nitroAcceleration = self:_ensureAtt("nitroAcceleration"),
	}
end

function CarInitializer:ChangeChildren(
	parent: Model | BasePart,
	childName: string,
	fn: (Model | BasePart, string, any) -> BasePart | Attachment | Model,
	properties
)
	local attachment = self[childName] or parent:FindFirstChild(childName)
	if not attachment then
		attachment = fn(parent, childName, properties)
	end
	self[childName] = attachment
	return attachment
end

local wheel_suffix = {
	"FL",
	"FR",
	"RL",
	"RR",
}

function CarInitializer._ensureSpringConstraing(self: ControllersTypes.CarInitializer, sufix: string)
	local spring_name = "Wheel" .. sufix .. "Suspension"
	if self._suspension:FindFirstChild(spring_name) then
		print("Omitting create springs")
		return
	end
	local sppring = Instance.new("SpringConstraint", self._suspension)
	sppring.Coils = 8
	sppring.Color = "Lemon metallic"
	sppring.Radius = 0.2
	sppring.Thickness = 0.15
	sppring.Visible = false
	sppring.Name = spring_name

	local wheel_name = "Wheel" .. sufix
	local the_wheel = assert(self._Wheels:FindFirstChild(wheel_name), " create a wheel model")
	sppring.Attachment0 = the_wheel.Mount.SpringAttachment
	sppring.Attachment1 = the_wheel.MotorAttachment
end

function CarInitializer._ensureSteeringRack(self: ControllersTypes.CarInitializer)
	local Steering = self.car:FindFirstChild("Steering")
	if not Steering then
		Steering = Instance.new("Folder", self.car)
		return
	end
	local SteeringRack = Steering:FindFirstChild("SteeringRack")
	if SteeringRack then
		print("omiting steering initailization")
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

	SteeringRack.Attachment0 = self:ChangeChildren(self.chassis, "SteeringAttachment", self._createInstance)
	local steerRack = self.car:FindFirstChild("SteeringRack")
	SteeringRack.Attachment1 = self:ChangeChildren(steerRack, "SteeringAttachment", self._createInstance)
end

function CarInitializer._initSteering(self: ControllersTypes.CarInitializer)
	return {
		steeringRackLength = self:_ensureAtt("steeringRackLength", "steering"),
		steeringRackResponsiveness = self:_ensureAtt("steeringRackResponsiveness", "steering"),
		steeringRackSpeed = self:_ensureAtt("steeringRackSpeed", "steering"),
		steeringRackMaxForce = self:_ensureAtt("steeringRackMaxForce", "steering"),
	}
end

function CarInitializer._initSuspension(self: ControllersTypes.CarInitializer)
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

function CarInitializer._ensureAntiroll(self: ControllersTypes.CarInitializer, sufix: string)
	local antiroll_name = "AntiRollBar" .. sufix
	if self._antiRoll:FindFirstChild(antiroll_name) then
		print("Omitting create springs")
		return
	end
	local sppring = Instance.new("SpringConstraint", self._antiRoll)
	sppring.Damping = 100
	sppring.FreeLength = 2.326
	sppring.LimitsEnabled = false
	sppring.MaxForce = math.huge
	sppring.Stiffness = 16000

	sppring.Coils = 0
	sppring.Color = "Lemon metallic"
	sppring.Radius = 0
	sppring.Thickness = 0.15
	sppring.Visible = false
	sppring.Name = antiroll_name

	local suffix = sufix:lower()
	local Antiroll = "AntiRollBar" .. "F"
	if suffix:sub(1, 1) == "f" then
		Antiroll = "AntiRollBar" .. "F"
	elseif suffix:sub(1, 1) == "r" then
		Antiroll = "AntiRollBar" .. "R"
	end

	sppring.Attachment0 = Antiroll.LeftSpringAttachment

	local wheel_name = "Wheel" .. sufix
	local the_wheel = assert(self._Wheels:FindFirstChild(wheel_name), " create a wheel model")
	sppring.Attachment1 = the_wheel.Wheel.MotorAttachment
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

function CarInitializer._initFolder(self: ControllersTypes.CarInitializer)
	-- TODO: may ensure folder exists and it has their attributes
	local steering = self:_initSteering()

	local suspension = self:_initSuspension()

	local antiRoll = self:_initAntiRoll()

	local redress = {
		redressMaxTorque = self:_ensureAtt("redressMaxTorque", "redress"),
		redressResponsiveness = self:_ensureAtt("redressResponsiveness", "redress"),
	}
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
