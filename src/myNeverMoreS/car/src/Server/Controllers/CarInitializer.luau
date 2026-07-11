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

-- Spatial properties must be applied in a fixed order: local frame first, then
-- world-space props (which must win). pairs() order is otherwise random, so a table
-- holding both `CFrame` and `WorldPosition` would intermittently leave the attachment
-- hundreds of studs off (a world position landing in the local CFrame).
local PROP_ORDER = {
	Orientation = 1,
	CFrame = 2,
	Axis = 3,
	SecondaryAxis = 4,
	WorldCFrame = 5,
	WorldAxis = 6,
	WorldSecondaryAxis = 7,
	WorldPosition = 8,
}
local funcionSetProps = function(inst: Instance, properties)
	local ordered = {}
	for key in pairs(properties) do
		if key ~= "ClassName" then
			table.insert(ordered, key)
		end
	end
	table.sort(ordered, function(a, b)
		return (PROP_ORDER[a] or 0) < (PROP_ORDER[b] or 0)
	end)
	for _, key in ipairs(ordered) do
		inst[key] = properties[key]
	end
end

function CarInitializer._createInstance(Parent: BasePart | Model, Name: string, properties): Attachment
	local newAttacment =
		Instance.new(if properties and properties.ClassName then properties.ClassName else "Attachment")
	newAttacment.Name = Name
	if properties then
		funcionSetProps(newAttacment, properties)
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

local function isLeftWheel(sufix: string): boolean
	return sufix:sub(2, 2):lower() == "l"
end

-- The motor/hinge axes must be MIRRORED between the two sides, exactly like
-- Workspace.Car (left wheels rotation axis +X in chassis space, right wheels -X):
-- the shared Controller drives FL/RL with -angularVelocity and FR/RR with
-- +angularVelocity, so if all four axes point the same way the two sides spin
-- against each other and the car does not move at all.
-- Returns the world rotation for the mount/knuckle attachment (primary axis up,
-- secondary = rotation axis) and for the wheel attachment (primary = rotation axis).
function CarInitializer._wheelAxisRotations(self: ControllersTypes.CarInitializer, sufix: string): (CFrame, CFrame)
	local chassisRot = self.chassis.CFrame.Rotation
	if isLeftWheel(sufix) then
		return chassisRot * CFrame.Angles(0, math.pi, 0) * CFrame.Angles(0, 0, math.pi / 2), chassisRot
	end
	return chassisRot * CFrame.Angles(0, 0, math.pi / 2), chassisRot * CFrame.Angles(0, math.pi, 0)
end

function CarInitializer._ensureKnuckle(self: ControllersTypes.CarInitializer, sufix: string)
	local suffix = sufix:lower()
	if suffix:sub(1, 1) ~= "f" then
		return nil
	end
	local rightSuffix = "F" .. sufix:sub(2)

	local wheel_name = "Wheel" .. rightSuffix
	local the_wheel = assert(self._Wheels:FindFirstChild(wheel_name), " create a wheel model")
	local Knuckle = assert(the_wheel:FindFirstChild("Knuckle"), " wheel '" .. wheel_name .. "' must have Knuckles")

	local Mount = assert(the_wheel:FindFirstChild("Mount"), " wheel '" .. wheel_name .. "' must have Mount")

	-- Steering pivot. Attachment0 (Mount) and Attachment1 (Knuckle) MUST share one
	-- identical WORLD frame, otherwise the HingeConstraint snaps them together at
	-- runtime and the wheel twists ~90 (this is what made the front wheels fly off).
	-- The hinge primary axis points along the chassis "up" -> a vertical steering
	-- axis, matching Workspace.Car. We set WorldCFrame (after the attachments are
	-- parented) instead of a local CFrame, so the result is independent of how the
	-- Mount/Knuckle parts are individually oriented.
	local wheel_part = the_wheel:FindFirstChild("Wheel")
	local a0Rot = self:_wheelAxisRotations(sufix)
	local hingeWorldCFrame = CFrame.new(wheel_part.Position) * a0Rot

	local HingeAttachmentMount = self:ChangeChildren(Mount, "HingeAttachment")
	local HingeAttachmentKnuckle = self:ChangeChildren(Knuckle, "HingeAttachment")
	HingeAttachmentMount.WorldCFrame = hingeWorldCFrame
	HingeAttachmentKnuckle.WorldCFrame = hingeWorldCFrame

	self:ChangeChildren(Knuckle, "HingeConstraint", {
		ClassName = "HingeConstraint",
		-- LimitsEnabled defaults to false; without it the knuckle spins freely and
		-- the steering geometry collapses (Workspace.Car has it enabled).
		LimitsEnabled = true,
		LowerAngle = -60,
		UpperAngle = 60,
		Restitution = 0,
		Attachment0 = HingeAttachmentMount,
		Attachment1 = HingeAttachmentKnuckle,
		ActuatorType = Enum.ActuatorType.None,
	})

	return Knuckle
end

function CarInitializer._ensureSteerRack(self: ControllersTypes.CarInitializer)
	local SteeringRack = assert(self.car:FindFirstChild("SteeringRack"), "Cars should have an 'SteeringRack'")

	-- Drop any half-wired legacy "RodConstraint" left by older builds so we never
	-- end up with broken duplicates beside RodConstraintRight / RodConstraintLeft.
	local legacyRod = SteeringRack:FindFirstChild("RodConstraint")
	while legacyRod do
		legacyRod:Destroy()
		legacyRod = SteeringRack:FindFirstChild("RodConstraint")
	end

	-- Rod attachments sit at the rack ends and at the knuckle end AWAY from the
	-- wheel, like Workspace.Car. The rod Length must equal the rest distance
	-- between its two attachments (a freshly scripted rod has Length 0 and would
	-- yank the knuckles into the rack on Play).
	local halfRack = SteeringRack.Size.X / 2

	local function knuckleSteerAtt(wheelName: string): Attachment
		local wheelModel = assert(self._Wheels:FindFirstChild(wheelName), " " .. wheelName .. " must exists")
		local knuckle = assert(wheelModel:FindFirstChild("Knuckle"), " " .. wheelName .. " must have Knuckle")
		local wheel_part = wheelModel:FindFirstChild("Wheel")
		local att = self:ChangeChildren(knuckle, "SteeringAttachment")
		local halfZ = knuckle.Size.Z / 2
		local towardPlusZ = ((knuckle.CFrame * CFrame.new(0, 0, halfZ)).Position - wheel_part.Position).Magnitude
		local towardMinusZ = ((knuckle.CFrame * CFrame.new(0, 0, -halfZ)).Position - wheel_part.Position).Magnitude
		att.Orientation = Vector3.zero
		att.Position = Vector3.new(0, 0, if towardPlusZ >= towardMinusZ then halfZ else -halfZ)
		return att
	end

	local RightRodAttachment = self:ChangeChildren(SteeringRack, "RightRodAttachment")
	RightRodAttachment.Orientation = Vector3.zero
	RightRodAttachment.Position = Vector3.new(halfRack, 0, 0)
	local att1_FR = knuckleSteerAtt("WheelFR")

	self:ChangeChildren(SteeringRack, "RodConstraintRight", {
		ClassName = "RodConstraint",
		Attachment0 = RightRodAttachment,
		Attachment1 = att1_FR,
		Length = (RightRodAttachment.WorldPosition - att1_FR.WorldPosition).Magnitude,
	})

	local LeftRodAttachment = self:ChangeChildren(SteeringRack, "LeftRodAttachment")
	LeftRodAttachment.Orientation = Vector3.zero
	LeftRodAttachment.Position = Vector3.new(-halfRack, 0, 0)
	local att1_FL = knuckleSteerAtt("WheelFL")

	self:ChangeChildren(SteeringRack, "RodConstraintLeft", {
		ClassName = "RodConstraint",
		Attachment0 = LeftRodAttachment,
		Attachment1 = att1_FL,
		Length = (LeftRodAttachment.WorldPosition - att1_FL.WorldPosition).Magnitude,
	})
end

function CarInitializer._ensureMotor(self: ControllersTypes.CarInitializer, sufix: string)
	local motor_name = "Wheel" .. sufix .. "Motor" --WheelFLMotor
	local wheelMotor = self.engine:FindFirstChild(motor_name)
	if not wheelMotor then
		wheelMotor = Instance.new("CylindricalConstraint")
		wheelMotor.Name = motor_name
		wheelMotor.Parent = self.engine
	end
	wheelMotor.Size = 0.15
	wheelMotor.Visible = false
	wheelMotor.Color = BrickColor.Yellow()
	wheelMotor.AngularVelocity = 0
	wheelMotor.MotorMaxAngularAcceleration = 500000
	wheelMotor.MotorMaxTorque = 10000
	wheelMotor.InclinationAngle = 90
	wheelMotor.AngularLimitsEnabled = false
	wheelMotor.AngularActuatorType = Enum.ActuatorType.Motor
	-- Bound the cylindrical slide (suspension travel) like Workspace.Car does
	-- ([-1, 1]); with limits off nothing holds the wheel to its mount until the
	-- springs are tuned, so the wheels dangle or fly on Play.
	wheelMotor.LimitsEnabled = true
	wheelMotor.LowerLimit = -1
	wheelMotor.UpperLimit = 1
	wheelMotor.Restitution = 0

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

	-- Both motor attachments must sit at the SAME world point (the wheel centre),
	-- otherwise the CylindricalConstraint yanks the wheel hundreds of studs on Play.
	-- We set WorldCFrame explicitly (never a world position stuffed into a local
	-- CFrame) so the result is independent of how the parts are oriented.
	local wheel_part = the_wheel_model:FindFirstChild("Wheel")
	local wheelCenter = wheel_part.Position
	local a0Rot, a1Rot = self:_wheelAxisRotations(sufix)

	-- Attachment0 (Knuckle on front wheels, Mount on rear): vertical primary axis,
	-- matching the steering hinge and Workspace.Car (InclinationAngle = 90 turns
	-- the secondary axis into the wheel rotation axis).
	local a0Parent = if sufix:sub(1, 1):lower() == "f" then Knuckle else Mount
	local motorA0 = self:ChangeChildren(a0Parent, "MotorAttachment")
	motorA0.WorldCFrame = CFrame.new(wheelCenter) * a0Rot
	wheelMotor.Attachment0 = motorA0

	-- Attachment1 (the spinning Wheel): primary axis along the lateral axle. This
	-- attachment is also shared by the suspension / anti-roll springs (position only).
	local motorA1 = self:ChangeChildren(wheel_part, "MotorAttachment")
	motorA1.WorldCFrame = CFrame.new(wheelCenter) * a1Rot
	wheelMotor.Attachment1 = motorA1
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

	local nitroV = self.engine:FindFirstChild("NitroVelocity") or Instance.new("LinearVelocity")
	nitroV.Parent = self.engine
	nitroV.MaxForce = 10000
	nitroV.Visible = false
	nitroV.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
	nitroV.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	nitroV.ForceLimitMode = Enum.ForceLimitMode.Magnitude
	nitroV.Attachment0 = self:ChangeChildren(self.chassis, "NitroAttachment")
	nitroV.Name = "NitroVelocity"
	-- Off until the nitro system enables it; left on it constantly brakes the car
	-- toward zero velocity (Workspace.Car ships with it disabled).
	nitroV.Enabled = false

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
	local attachment = parent:FindFirstChild(childName)
	if not attachment then
		attachment = self._createInstance(parent, childName, properties)
	else
		if properties then
			funcionSetProps(attachment, properties)
		end
	end

	return attachment
end

function CarInitializer._ensureNoCollide(self: ControllersTypes.CarInitializer, wheel_part: BasePart, other: BasePart)
	local name = "NoCollide_" .. other.Name
	local noCollide = wheel_part:FindFirstChild(name)
	if not noCollide then
		noCollide = Instance.new("NoCollisionConstraint")
		noCollide.Name = name
		noCollide.Parent = wheel_part
	end
	noCollide.Part0 = other
	noCollide.Part1 = wheel_part
end

function CarInitializer._ensureSpringConstraing(self: ControllersTypes.CarInitializer, sufix: string)
	local spring_name = "Wheel" .. sufix .. "Suspension"
	local sppring = self._suspension:FindFirstChild(spring_name)
	if not sppring then
		sppring = Instance.new("SpringConstraint")
		sppring.Name = spring_name
		sppring.Parent = self._suspension
	end
	sppring.Coils = 8
	sppring.Color = BrickColor.Yellow()
	sppring.Radius = 0.2
	sppring.Thickness = 0.15
	sppring.Visible = false
	sppring.LimitsEnabled = false

	-- Give the spring working values immediately. ConstraintUpdater re-applies these
	-- from the folder attributes at runtime, but the car must already stand up in
	-- Studio (a scripted SpringConstraint otherwise starts with Stiffness 0).
	local prefix = if sufix:sub(1, 1):lower() == "f" then "front" else "rear"
	sppring.Stiffness = self._suspension:GetAttribute(prefix .. "SuspensionStiffness")
		or default_stats.suspension[prefix .. "SuspensionStiffness"]
	sppring.Damping = self._suspension:GetAttribute(prefix .. "SuspensionDamping")
		or default_stats.suspension[prefix .. "SuspensionDamping"]
	sppring.FreeLength = self._suspension:GetAttribute(prefix .. "SuspensionLength")
		or default_stats.suspension[prefix .. "SuspensionLength"]
	sppring.MaxForce = math.huge

	local wheel_name = "Wheel" .. sufix
	local the_wheel = assert(self._Wheels:FindFirstChild(wheel_name), " create a wheel model")
	local mount = assert(the_wheel:FindFirstChild("Mount"), " wheel '" .. wheel_name .. "' must have mounts")
	sppring.Attachment0 = self:ChangeChildren(mount, "SpringAttachment")

	local wheel_part = the_wheel:FindFirstChild("Wheel")
	sppring.Attachment1 = self:ChangeChildren(wheel_part, "MotorAttachment")

	-- The wheels overlap the chassis / body colliders; without NoCollision the
	-- assembly collides with itself and jams in place.
	self:_ensureNoCollide(wheel_part, self.chassis)
	local body = self.car:FindFirstChild("Body")
	if body then
		for _, part in ipairs(body:GetDescendants()) do
			if part:IsA("BasePart") and part.CanCollide then
				self:_ensureNoCollide(wheel_part, part)
			end
		end
	end
end

function CarInitializer._ensureSteeringRack(self: ControllersTypes.CarInitializer)
	local rackPart = assert(self.car:FindFirstChild("SteeringRack"), "Cars should have an 'SteeringRack'")

	local SteeringRack = self._steering:FindFirstChild("SteeringRack")
	if not SteeringRack then
		SteeringRack = Instance.new("PrismaticConstraint")
		SteeringRack.Name = "SteeringRack"
		SteeringRack.Parent = self._steering
	end
	SteeringRack.Size = 0.15
	SteeringRack.Visible = false
	SteeringRack.LinearResponsiveness = self._steering:GetAttribute("steeringRackResponsiveness")
		or default_stats.steering.steeringRackResponsiveness
	SteeringRack.ServoMaxForce = self._steering:GetAttribute("steeringRackMaxForce")
		or default_stats.steering.steeringRackMaxForce
	SteeringRack.Speed = self._steering:GetAttribute("steeringRackSpeed") or default_stats.steering.steeringRackSpeed
	SteeringRack.TargetPosition = 0
	SteeringRack.ActuatorType = Enum.ActuatorType.Servo
	SteeringRack.LimitsEnabled = true
	SteeringRack.Restitution = 0
	-- Symmetric travel around the rest pose ([-length, length] like Workspace.Car);
	-- the scripted default of [0, 5] can only steer one way.
	local rackLength = self._steering:GetAttribute("steeringRackLength") or default_stats.steering.steeringRackLength
	SteeringRack.LowerLimit = -rackLength
	SteeringRack.UpperLimit = rackLength

	-- Both prismatic attachments must share ONE world frame (the rack rest pose)
	-- with the slide axis along the chassis' lateral X, like Workspace.Car;
	-- otherwise the rack snaps sideways on Play.
	local rackWorld = CFrame.new(rackPart.Position) * self.chassis.CFrame.Rotation
	local att0 = self:ChangeChildren(self.chassis, "SteeringAttachment")
	local att1 = self:ChangeChildren(rackPart, "SteeringAttachment")
	att0.WorldCFrame = rackWorld
	att1.WorldCFrame = rackWorld
	SteeringRack.Attachment0 = att0
	SteeringRack.Attachment1 = att1
end

function CarInitializer._initSteering(self: ControllersTypes.CarInitializer)
	self._steering = self:ChangeChildren(self.car, "Steering", {
		ClassName = "Folder",
	})

	-- Ensure ALL steering attributes (including steeringReduction, which the client
	-- controller reads) before wiring the rack, so the rack can use them.
	local steering_params = {}
	local steering_stats = table.clone(default_stats["steering"])
	for key, _ in pairs(steering_stats) do
		steering_params[key] = self:_ensureAtt(key, "steering")
	end

	self:_ensureSteeringRack()

	return steering_params
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

	local suspension_params = {
		frontSuspensionLength = self:_ensureAtt("frontSuspensionLength", "suspension"),
		frontSuspensionStiffness = self:_ensureAtt("frontSuspensionStiffness", "suspension"),
		frontSuspensionDamping = self:_ensureAtt("frontSuspensionDamping", "suspension"),
		rearSuspensionLength = self:_ensureAtt("rearSuspensionLength", "suspension"),
		rearSuspensionStiffness = self:_ensureAtt("rearSuspensionStiffness", "suspension"),
		rearSuspensionDamping = self:_ensureAtt("rearSuspensionDamping", "suspension"),
		frontCamber = self:_ensureAtt("frontCamber", "suspension"),
		rearCamber = self:_ensureAtt("rearCamber", "suspension"),
	}

	for _, suffix in ipairs(wheel_suffix) do
		self:_ensureSpringConstraing(suffix)
	end

	return suspension_params
end

function CarInitializer._ensureAntirollbar(self: ControllersTypes.CarInitializer, suffix: string)
	local firstLetter = suffix:sub(1, 1):lower()

	local antiroll_name = "AntiRollBar" .. (if firstLetter == "r" then "R" else "F")
	local antiroll_bar = self.car:FindFirstChild(antiroll_name)
	assert(antiroll_bar, "create an " .. antiroll_name)

	-- The bar pivots on the chassis about its own long (lateral) axis. Both hinge
	-- attachments must be coincident in world space, like Workspace.Car, or the hinge
	-- snaps the bar a few studs on Play. Workspace.Car pivots at the bar's REAR edge
	-- (local +Z), with the spring attachments hanging off the front corners.
	local pivotPos = (antiroll_bar.CFrame * CFrame.new(0, 0, antiroll_bar.Size.Z / 2)).Position
	local pivot = CFrame.new(pivotPos) * self.chassis.CFrame.Rotation

	local att0 = self:ChangeChildren(self.chassis, "AntiRollAttachment" .. firstLetter:upper())
	local att1 = self:ChangeChildren(antiroll_bar, "AntiRollAttachment")
	att0.WorldCFrame = pivot
	att1.WorldCFrame = pivot

	self:ChangeChildren(antiroll_bar, "HingeConstraint", {
		ClassName = "HingeConstraint",
		LimitsEnabled = true,
		LowerAngle = -45,
		Restitution = 0,
		UpperAngle = 45,
		ActuatorType = Enum.ActuatorType.None,

		Attachment0 = att0,
		Attachment1 = att1,
	})
	return antiroll_bar
end

function CarInitializer._ensureAntiroll(self: ControllersTypes.CarInitializer, sufix: string)
	local antiroll_bar = self:_ensureAntirollbar(sufix)

	local secondLetter = sufix:sub(2, 2):lower()
	local att_name = if secondLetter == "l" then "LeftSpringAttachment" else "RightSpringAttachment"

	-- The spring hangs from the bar END (front corner), not the bar centre, or the
	-- bar has no leverage and the spring free length is measured wrong.
	local att0 = self:ChangeChildren(antiroll_bar, att_name)
	att0.Orientation = Vector3.zero
	att0.Position = Vector3.new(
		(if secondLetter == "l" then -1 else 1) * antiroll_bar.Size.X / 2,
		0,
		-antiroll_bar.Size.Z / 2
	)

	local wheel = assert(self._Wheels:FindFirstChild("Wheel" .. sufix)):FindFirstChild("Wheel")
	local att1 = self:ChangeChildren(wheel, "MotorAttachment")

	local front = sufix:sub(1, 1):lower() == "f"
	local antiroll_spring_name = "AntiRollBar" .. sufix
	local sppring = self._antiRoll:FindFirstChild(antiroll_spring_name)
	if not sppring then
		sppring = Instance.new("SpringConstraint")
		sppring.Name = antiroll_spring_name
		sppring.Parent = self._antiRoll
	end
	sppring.Stiffness = self._antiRoll:GetAttribute(if front then "frontAntiRollBarStiffness" else "rearAntiRollBarStiffness")
		or default_stats.antiRoll.frontAntiRollBarStiffness
	sppring.Damping = self._antiRoll:GetAttribute(if front then "frontAntiRollBarDamping" else "rearAntiRollBarDamping")
		or default_stats.antiRoll.frontAntiRollBarDamping
	sppring.LimitsEnabled = false
	-- Workspace.Car uses a huge MaxForce here (5e8 front / 5e7 rear) and
	-- ConstraintUpdater never touches MaxForce, so a small value would permanently
	-- disable the anti-roll bars.
	sppring.MaxForce = if front then 500000000 else 50000000

	sppring.Coils = 0
	sppring.Color = BrickColor.Yellow()
	sppring.Radius = 0
	sppring.Thickness = 0.15
	sppring.Visible = false

	sppring.Attachment0 = att0
	sppring.Attachment1 = att1
	-- Rest length is this car's actual bar-end -> wheel-centre distance (Workspace.Car
	-- hardcodes 2.326 because that is ITS geometry; other cars differ).
	sppring.FreeLength = (att0.WorldPosition - att1.WorldPosition).Magnitude
end

function CarInitializer._initAntiRoll(self: ControllersTypes.CarInitializer): ControllersTypes.antiRoll
	local antiroll_folder = self:ChangeChildren(self.car, "AntiRoll", {
		ClassName = "Folder",
	})
	self._antiRoll = antiroll_folder

	local antiRoll_params = {
		frontAntiRollBarDamping = self:_ensureAtt("frontAntiRollBarDamping", "antiRoll"),
		frontAntiRollBarStiffness = self:_ensureAtt("frontAntiRollBarStiffness", "antiRoll"),
		rearAntiRollBarStiffness = self:_ensureAtt("rearAntiRollBarStiffness", "antiRoll"),
		rearAntiRollBarDamping = self:_ensureAtt("rearAntiRollBarDamping", "antiRoll"),
	}

	for _, suffix in ipairs(wheel_suffix) do
		self:_ensureAntiroll(suffix)
	end

	return antiRoll_params
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

	local RedressOrientation = self._redress:FindFirstChild("RedressOrientation") or Instance.new("AlignOrientation")
	RedressOrientation.Parent = self._redress
	RedressOrientation.Name = "RedressOrientation"
	RedressOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	RedressOrientation.AlignType = Enum.AlignType.AllAxes
	RedressOrientation.ReactionTorqueEnabled = false
	RedressOrientation.RigidityEnabled = false
	RedressOrientation.MaxTorque = 500000
	RedressOrientation.Responsiveness = 10
	-- Off until the Redresser flips the car back; left on it permanently torques
	-- the chassis toward one fixed orientation (Workspace.Car ships with it off).
	RedressOrientation.Enabled = false

	RedressOrientation.Attachment0 = self:ChangeChildren(self.chassis, "FlipperAttachment")
	local redress_params = {}
	local engine_stats = table.clone(default_stats["redress"])
	for key, _ in pairs(engine_stats) do
		redress_params[key] = self:_ensureAtt(key, "redress")
	end
	return redress_params
end

function CarInitializer._initFolder(self: ControllersTypes.CarInitializer)
	self:_ensureChasisShit()
	local steering = self:_initSteering()

	local suspension = self:_initSuspension()

	local antiRoll = self:_initAntiRoll()

	local redress = self:_initRedress()

	self:_ensureSteerRack()
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

	local Animations = Instance.new("Folder", self.car)
	Animations.Name = "Animations"
	local driveAnimation = Instance.new("Animation", Animations)
	driveAnimation.Name = "DriveAnimation"
	driveAnimation.AnimationId = "rbxassetid://15570378042"
end

return CarInitializer
