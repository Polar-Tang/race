local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbsController = require(ReplicatedStorage.Nevermore.Custom.car.src.Server.Controllers.utils.AbsController)
local ControllersTypes = require(ReplicatedStorage.Nevermore.Custom.car.src.Server.Controllers.utils.ControllersTypes)

local FLIPPED_LIMIT = -0.5
local UPRIGHT_LIMIT = 0.7
local MOVING_LIMIT = 10

local Redresser = setmetatable({}, AbsController)
Redresser.__index = Redresser
Redresser.ClassName = "Redresser"

function Redresser.new(config: ControllersTypes.ControllConstructor): ControllersTypes.Redresser
	local self = setmetatable(AbsController.new(config), Redresser)
	self._redress = self.car.Redress
	self._redressOrientation = self._redress.RedressOrientation
	self._timeFlipped = 0
	self._redressParameters = {
		maxTimeFlipped = 2,
		redressMaxTorque = 500000,
		redressResponsiveness = 10,
	}
	return self
end

function Redresser._isFlipped(self: ControllersTypes.Redresser): boolean
	local chassisUp = self.chassis.CFrame.UpVector
	return chassisUp:Dot(Vector3.yAxis) < FLIPPED_LIMIT
end

function Redresser._isUpright(self: ControllersTypes.Redresser): boolean
	local chassisUp = self.chassis.CFrame.UpVector
	return chassisUp:Dot(Vector3.yAxis) > UPRIGHT_LIMIT
end

function Redresser._isMoving(self): boolean
	return self.chassis.AssemblyLinearVelocity.Magnitude > MOVING_LIMIT
end

-- Enable the RedressOrientation constraint until the car has flipped upright
function Redresser._redressAsync(self: ControllersTypes.Redresser)
	local forward = self.chassis.CFrame.LookVector
	local cframe = CFrame.lookAt(Vector3.zero, forward, Vector3.yAxis)
	self._redressOrientation.CFrame = cframe
	self._redressOrientation.Enabled = true
	repeat
		task.wait()
	until self:_isUpright()
	self._redressOrientation.Enabled = false
end

function Redresser.Start(self: ControllersTypes.Redresser)
	-- Cache the attribute values in a table and update them when the attribute changes.
	-- Parameters aren't going to change very often so there's no reason to call :GetAttribute() constantly.
	for parameter in self._redressParameters do
		self._maid:GiveTask(self._redress:GetAttributeChangedSignal(parameter):Connect(function()
			self._redressParameters[parameter] = self._redress:GetAttribute(parameter) :: number
		end))

		self._redressParameters[parameter] = self._redress:GetAttribute(parameter) :: number
	end

	-- The maid cancels this thread on Destroy; otherwise the loop keeps calling
	-- methods on a metatable-stripped self after the car is destroyed
	-- ("attempt to call missing method '_isFlipped'").
	self._maid:GiveTask(task.spawn(function()
		while true do
			local deltaTime = task.wait(0.1)
			-- If the car is currently flipped, keep track of the amount of time it has been flipped
			if self:_isFlipped() and not self:_isMoving() then
				self._timeFlipped += deltaTime
			else
				self._timeFlipped = 0
			end
			-- Once the time flipped exceeds the limit, flip the car back over
			if self._timeFlipped >= self._redressParameters.maxTimeFlipped then
				self._timeFlipped = 0
				self:_redressAsync()
			end
		end
	end))
end

return Redresser
