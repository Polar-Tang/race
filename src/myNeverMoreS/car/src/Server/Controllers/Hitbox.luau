local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local AbsController = require(ReplicatedStorage.Nevermore.Custom.car.src.Server.Controllers.utils.AbsController)

-- The hit-detection library lives in the place (not synced to disk). We code
-- against it through the small adapter in `_startDetection` below.
local HitboxClass = require(ReplicatedFirst:WaitForChild("HitboxClass"))

local Hitbox = setmetatable({}, AbsController)
Hitbox.__index = Hitbox
Hitbox.ClassName = "Hitbox"

-- ===== tuning =====
local HITBOX_DEPTH = 2 -- studs the hitbox sticks out past the front bumper
local HITBOX_TRANSPARENCY = 1 -- 1 = invisible in game; bump to ~0.6 to debug
local DAMAGE = 25
local KNOCKBACK_SPEED = 60 -- studs/s velocity added to the victim
local KNOCKBACK_UP = 0.4 -- fraction of the knockback that points up
local ANGULAR_IMPULSE = 40 -- how much spin to add
local HIT_DEBOUNCE = 0.5 -- seconds a given humanoid is immune after a hit
-- Which local axis of the chassis points forward. -Z is the Roblox "front"
-- (CFrame.LookVector). Flip/reassign if your chassis faces a different way.
local FORWARD = Vector3.new(0, 0, -1)

function Hitbox.new(config)
	local self = setmetatable(AbsController.new(config), Hitbox)
	self._hitboxPart = nil
	self._hitbox = nil
	self._recentlyHit = {} -- humanoid -> true while on cooldown
	return self
end

-- Builds an invisible, non-colliding part welded to the front of the chassis.
function Hitbox._buildHitboxPart(self)
	local chassis = self.chassis
	assert(chassis, "Hitbox: car has no Chassis part")

	local size = chassis.Size
	local part = Instance.new("Part")
	part.Name = "CarHitbox"
	part.Size = Vector3.new(size.X, size.Y, HITBOX_DEPTH)
	part.Transparency = HITBOX_TRANSPARENCY
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = true -- some hitbox libs rely on Touched under the hood
	part.Massless = true -- must not disturb the car's physics
	part.Anchored = false
	-- Sit it just past the front face, along the chassis' forward axis.
	local offset = size.Z / 2 + HITBOX_DEPTH / 2
	part.CFrame = chassis.CFrame * CFrame.new(FORWARD * offset)
	part.Parent = chassis

	-- Weld so it rigidly tracks the chassis as the car drives.
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = chassis
	weld.Part1 = part
	weld.Parent = part

	self._maid:GiveTask(part)
	self._hitboxPart = part
	return part
end

-- ADAPTER: this is the only spot coupled to ReplicatedFirst.HitboxClass. Adjust
-- the method/signal names here to match your library's actual API.
function Hitbox._startDetection(self)
	local hitbox = HitboxClass.new(self._hitboxPart)
	self._hitbox = hitbox

	-- Give the object to the maid if it is cleanable, so teardown stops detection.
	if typeof(hitbox) == "table" and (hitbox.Destroy or hitbox.Stop) then
		self._maid:GiveTask(hitbox)
	end

	self._maid:GiveTask(hitbox.OnHit:Connect(function(hitPart, humanoid)
		-- Libraries differ on argument order; resolve the Humanoid either way.
		local hum = (typeof(humanoid) == "Instance" and humanoid:IsA("Humanoid")) and humanoid
			or (typeof(hitPart) == "Instance" and hitPart:IsA("Humanoid")) and hitPart
			or nil
		if hum then
			self:_onHit(hum)
		end
	end))

	hitbox:HitStart()
end

-- Applies knockback + spin + damage to a struck humanoid (once per debounce).
function Hitbox._onHit(self, humanoid: Humanoid)
	if self._recentlyHit[humanoid] then
		return
	end
	self._recentlyHit[humanoid] = true
	task.delay(HIT_DEBOUNCE, function()
		self._recentlyHit[humanoid] = nil
	end)

	local character = humanoid.Parent
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		-- Send the victim the way the car is travelling (fall back to the front
		-- axis when the car is basically stationary), with an upward component.
		local carVel = self.chassis.AssemblyLinearVelocity
		local dir = carVel.Magnitude > 1 and carVel.Unit or (self.chassis.CFrame * CFrame.new(FORWARD)).Position - self.chassis.Position
		dir = (dir.Unit + Vector3.new(0, KNOCKBACK_UP, 0)).Unit

		hrp:ApplyImpulse(dir * KNOCKBACK_SPEED * hrp.AssemblyMass)
		-- Angular torque: spin them around a mostly-vertical axis.
		hrp:ApplyAngularImpulse(Vector3.new(0, 1, 0) * ANGULAR_IMPULSE * hrp.AssemblyMass)
	end

	humanoid:TakeDamage(DAMAGE)
end

function Hitbox.Init(self)
	self:_buildHitboxPart()
end

function Hitbox.Start(self)
	self:_startDetection()
end

return Hitbox
