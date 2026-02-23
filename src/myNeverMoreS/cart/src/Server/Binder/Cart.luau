local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControllersTypes = require(ReplicatedStorage.Nevermore.Custom.cart.src.Server.Controllers.ControllersTypes)
local ParticleEffectsController =
	require(ReplicatedStorage.Nevermore.Custom.cart.src.Server.Controllers.ParticleEffectsController)
local SoundEffectsController =
	require(ReplicatedStorage.Nevermore.Custom.cart.src.Server.Controllers.SoundEffectsController)
local StatusController = require(ReplicatedStorage.Nevermore.Custom.cart.src.Server.Controllers.StatusController)
local ThrottleController = require(ReplicatedStorage.Nevermore.Custom.cart.src.Server.Controllers.ThrottleController)
local Maid = require(ReplicatedStorage.Nevermore.Quenty.maid.Shared.Maid)
local CartTypes = require(script.Parent.CartTypes)

local CartDriver = {}
CartDriver.__index = CartDriver

function CartDriver.new(cart: Instance, serviceBag: any): CartTypes.CartDriver
	local base = cart:WaitForChild("Base")
	local driver = cart:WaitForChild("Driver")
	local Seat = cart:WaitForChild("Seat") :: Seat

	local self = setmetatable({
		_cart = cart,
		_base = base,
		_hinges = base:WaitForChild("WheelHinges"):GetChildren(),
		_springs = base:WaitForChild("Springs"):GetChildren(),
		_driver = driver,
		_seat = Seat,
		_maid = Maid.new(),
	}, CartDriver)

	local config: ControllersTypes.ControllConstructor = {
		cart = cart,
		seat = Seat,
	}

	self._statusController = StatusController.new(config)
	self._particleEffectsController = ParticleEffectsController.new(config)
	self._soundEffectsController = SoundEffectsController.new(config)
	self._throttleController = ThrottleController.new(config)

	self.controllers = {
		["statusController"] = self._statusController,
		["particleEffectsController"] = self._particleEffectsController,
		["soundEffectsController"] = self._soundEffectsController,
		["throttleController"] = self._throttleController,
	}

	for _, controller in self.controllers do
		if controller.init then
			controller:init(self)
		end
	end

	return self
end

function CartDriver.getController(self: CartTypes.CartDriver, controllerName: string)
	return self.controllers[controllerName]
end

function CartDriver.update(self: CartTypes.CartDriver, throttle: number)
	local currentScale = self._cart:GetScale()
	local currentMass = self._base.AssemblyMass

	-- Apply the calculated throttle
	for _, hinge in self._hinges do
		hinge.MotorMaxTorque = currentMass * 100 * math.sqrt(math.abs(throttle))
		local maxSpeed = self._driver:GetAttribute("MaxSpeed")
		assert(maxSpeed)
		assert(typeof(maxSpeed))
		hinge.AngularVelocity = -maxSpeed * throttle
	end

	local velocity = self._base.AssemblyLinearVelocity.Magnitude
	local springFactor = (velocity / currentScale) / 40
	for _, spring in self._springs do
		spring.Stiffness = math.clamp(springFactor, 0.3, 2.0) * currentMass * 60
		spring.Damping = math.clamp(springFactor, 0.3, 2.0) * currentMass * 3
	end
end

-- function CartDriver.init(self: CartTypes.CartDriver)
-- 	-- setupCollisionGroups()
-- 	local parent = self._cart
-- 	local base = Instance.new("Part", parent)
-- 	base.CFrame = CFrame.new(parent) * CFrame.Angles(0, math.rad(90), 0)
-- end
function CartDriver.SetThrottle(self: CartTypes.CartDriver, throttle: number, player)
	if self._statusController:occupantIsPlayer(player) and type(throttle) == "number" then
		self._throttleController:SetThrottle(throttle)
	end
end

function CartDriver.breakCart(self: CartTypes.CartDriver)
	self._statusController:vacate()

	self._soundEffectsController:playSound("BreakSound")

	if self._base.AssemblyRootPart then
		self._base.AssemblyRootPart:SetNetworkOwner(nil)
	end
	local descendants = self._cart:GetDescendants()
	for _, descendant in ipairs(descendants) do
		if descendant:IsA("WeldConstraint") or descendant:IsA("Constraint") then
			descendant.Enabled = false
		end
	end
	for _, descendant in ipairs(descendants) do
		if descendant:IsA("BasePart") then
			descendant:ApplyImpulse(Vector3.new(0, math.random(70, 70), 0) * 0.5 * descendant.AssemblyMass)
			descendant:ApplyAngularImpulse(
				Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10))
					* 1
					* descendant.AssemblyMass
			)
		end
	end
	task.spawn(function()
		for _, ch in ipairs(self._cart:GetDescendants()) do
			if ch:IsA("BasePart") then
				task.delay(math.random() * 4, ch.Destroy, ch)
			end
		end
		task.wait(4)
		self._cart:Destroy()
	end)
end

function CartDriver.getStatus(self: CartTypes.CartDriver, respawnAfter: number): (boolean, boolean)
	local Cart = self._cart
	local Base = self._base

	local WheelAttachments = {
		Base:WaitForChild("BackLeft"),
		Base:WaitForChild("BackRight"),
		Base:WaitForChild("FrontLeft"),
		Base:WaitForChild("FrontRight"),
	}

	local FindRailRaycastParams = RaycastParams.new()
	FindRailRaycastParams.FilterDescendantsInstances = { Cart:WaitForChild("Wheels") }

	local MustBeOnRails = script:GetAttribute("MustBeOnRails")

	local function isSittingOnTrack()
		local offTrackCount = 0
		for _, attach in ipairs(WheelAttachments) do
			local cf = attach.WorldCFrame
			local pos = cf.Position
			local dir = -cf.YVector
			local hit = workspace:Raycast(pos, dir, FindRailRaycastParams)
			if not hit or (MustBeOnRails and hit.Instance.CollisionGroupId ~= 1) then
				offTrackCount += 1
			end
		end
		return offTrackCount <= 1
	end

	local lastOnTrack = os.clock()

	if isSittingOnTrack() then
		lastOnTrack = os.clock()
		return true, false
	elseif (os.clock() - lastOnTrack) > respawnAfter then
		return false, true
	else
		return false, false
	end
end

function CartDriver.running(self: CartTypes.CartDriver)
	local SoundEffects = self._soundEffectsController
	local ParticleEffects = self._particleEffectsController
	-- local getStatus = require(script:WaitForChild("getStatus"))
	-- local breakCart = require(script:WaitForChild("breakCart"))

	local Cart = self._cart
	local Throttle = script:WaitForChild("Throttle")
	local Base = Cart:WaitForChild("Base")

	--Buttons:WaitForChild("Decouple"):WaitForChild("ClickDetector").MouseClick:Connect(function(player)
	--	if occupantIsPlayerOrNone(player) then
	--		Coupling.decouple()
	--	end
	--end)

	-- local function slowDownIfNoOccupant(dt)

	-- end

	local lastPosition = Base.Position
	local iteration = math.random(1, 100)
	while true do
		local dt = task.wait()

		local shouldPlaySounds = script:GetAttribute("PlaySounds")

		-- Only do the raycasts every 4th frame
		iteration += 1
		if iteration % 4 == 0 then
			local DespawnAfter = self._cart:GetAttribute("DespawnAfter")
			assert(DespawnAfter)
			assert(typeof(DespawnAfter) == "number")
			local isOnTrack, expired = self:getStatus(DespawnAfter)
			if not isOnTrack and shouldPlaySounds then
				SoundEffects.stopSounds()
			end
			if expired then
				self:breakCart()
				break
			end
		end

		local thisPosition = Base.Position
		SoundEffects.movedBy((lastPosition - thisPosition).Magnitude)
		lastPosition = thisPosition

		local throttle = Throttle.Value
		local velocity = Base.AssemblyLinearVelocity.Magnitude

		local overrideScreech = false
		if
			math.abs(throttle) > 0.2
			and math.sign(Base.CFrame.LookVector:Dot(Base.AssemblyLinearVelocity)) ~= math.sign(throttle)
		then
			overrideScreech = true
		end

		local screeching = ParticleEffects.updateSparks(velocity, overrideScreech)

		if shouldPlaySounds then
			SoundEffects.playSounds(dt, velocity, screeching)
		end

		-- 	-- Slow down if nobody is riding
		if script:GetAttribute("SlowDownWhenEmpty") and self._statusController:isSeatAvaible() then
			local decay = 0.01 * dt
			if math.abs(Throttle.Value) < decay then
				Throttle.Value = 0
			else
				Throttle.Value -= math.sign(Throttle.Value) * decay
			end
		end

		if self._statusController:isSeatAvaible() then
			self:update(throttle)
		end
	end
end

return CartDriver
