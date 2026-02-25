local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbsController = require(ReplicatedStorage.Nevermore.Custom.car.src.Server.Controllers.utils.AbsController)
local ControllersTypes = require(ReplicatedStorage.Nevermore.Custom.car.src.Server.Controllers.utils.ControllersTypes)

local ConstraintUpdater = setmetatable({}, AbsController)
ConstraintUpdater.__index = ConstraintUpdater
ConstraintUpdater.ClassName = "ConstraintUpdater"

function ConstraintUpdater.new(config: ControllersTypes.ControllConstructor): ControllersTypes.ConstraintUpdater
	local self = setmetatable(AbsController.new(config), ConstraintUpdater)

	self._steering = self.car:FindFirstChild("Steering")
	self._suspension = self.car:FindFirstChild("Suspension")
	self._antiRoll = self.car:FindFirstChild("AntiRoll")
	self._redress = self.car:FindFirstChild("Redress")

	return self
end
-- Update suspension constraints
function ConstraintUpdater._updateSuspension(self: ControllersTypes.ConstraintUpdater)
	local suspension = self._suspension
	local frontLength = suspension:GetAttribute("frontSuspensionLength")
	local frontStiffness = suspension:GetAttribute("frontSuspensionStiffness")
	local frontDamping = suspension:GetAttribute("frontSuspensionDamping")
	local rearLength = suspension:GetAttribute("rearSuspensionLength")
	local rearStiffness = suspension:GetAttribute("rearSuspensionStiffness")
	local rearDamping = suspension:GetAttribute("rearSuspensionDamping")
	local frontCamber = suspension:GetAttribute("frontCamber")
	local rearCamber = suspension:GetAttribute("rearCamber")

	suspension.WheelFRSuspension.FreeLength = frontLength
	suspension.WheelFRSuspension.Damping = frontDamping
	suspension.WheelFRSuspension.Stiffness = frontStiffness
	suspension.WheelFLSuspension.FreeLength = frontLength
	suspension.WheelFLSuspension.Stiffness = frontStiffness
	suspension.WheelFLSuspension.Damping = frontDamping
	suspension.WheelRRSuspension.FreeLength = rearLength
	suspension.WheelRRSuspension.Stiffness = rearStiffness
	suspension.WheelRRSuspension.Damping = rearDamping
	suspension.WheelRLSuspension.FreeLength = rearLength
	suspension.WheelRLSuspension.Stiffness = rearStiffness
	suspension.WheelRLSuspension.Damping = rearDamping

	local engine = self.engine
	engine.WheelFRMotor.InclinationAngle = 90 + frontCamber
	engine.WheelFLMotor.InclinationAngle = 90 + frontCamber
	engine.WheelRRMotor.InclinationAngle = 90 + rearCamber
	engine.WheelRLMotor.InclinationAngle = 90 + rearCamber
end

-- Update anti roll bar constraints
function ConstraintUpdater._updateAntiRoll(self: ControllersTypes.ConstraintUpdater)
	local antiRoll = self._antiRoll
	local frontDamping = antiRoll:GetAttribute("frontAntiRollBarDamping")
	local frontStiffness = antiRoll:GetAttribute("frontAntiRollBarStiffness")
	local rearStiffness = antiRoll:GetAttribute("rearAntiRollBarStiffness")
	local rearDamping = antiRoll:GetAttribute("rearAntiRollBarDamping")

	antiRoll.AntiRollBarFR.Stiffness = frontStiffness
	antiRoll.AntiRollBarFR.Damping = frontDamping
	antiRoll.AntiRollBarFL.Stiffness = frontStiffness
	antiRoll.AntiRollBarFL.Damping = frontDamping
	antiRoll.AntiRollBarRR.Stiffness = rearStiffness
	antiRoll.AntiRollBarRR.Damping = rearDamping
	antiRoll.AntiRollBarRL.Stiffness = rearStiffness
	antiRoll.AntiRollBarRL.Damping = rearDamping
end

-- Update steering constraints
function ConstraintUpdater._updateSteering(self: ControllersTypes.ConstraintUpdater)
	local steering = self._steering

	local length = steering:GetAttribute("steeringRackLength")
	local responsiveness = steering:GetAttribute("steeringRackResponsiveness")
	local speed = steering:GetAttribute("steeringRackSpeed")
	local maxForce = steering:GetAttribute("steeringRackMaxForce")

	steering.SteeringRack.UpperLimit = length
	steering.SteeringRack.LowerLimit = -length
	steering.SteeringRack.LinearResponsiveness = responsiveness
	steering.SteeringRack.Speed = speed
	steering.SteeringRack.ServoMaxForce = maxForce
end

-- Update redress constraints
function ConstraintUpdater._updateRedress(self: ControllersTypes.ConstraintUpdater)
	local redress = self._redress

	local maxTorque = redress:GetAttribute("redressMaxTorque")
	local responsiveness = redress:GetAttribute("redressResponsiveness")

	redress.RedressOrientation.MaxTorque = maxTorque
	redress.RedressOrientation.Responsiveness = responsiveness
end

function ConstraintUpdater.Start(self: ControllersTypes.ConstraintUpdater)
	local suspensionCOn = self._suspension.AttributeChanged:Connect(function()
		self:_updateSuspension()
	end)
	local antiRollCon = self._antiRoll.AttributeChanged:Connect(function(a0: string)
		self:_updateAntiRoll()
	end)
	local steeringCon = self._steering.AttributeChanged:Connect(function(a0: string)
		self:_updateSteering()
	end)
	local redressCon = self._redress.AttributeChanged:Connect(function(a0: string)
		self:_updateRedress()
	end)

	self._maid:GiveTask(suspensionCOn)
	self._maid:GiveTask(antiRollCon)
	self._maid:GiveTask(steeringCon)
	self._maid:GiveTask(redressCon)

	self:_updateSuspension()
	self:_updateAntiRoll()
	self:_updateSteering()
	self:_updateRedress()
end

return ConstraintUpdater
