local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local CollectionService = game:GetService("CollectionService")

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
local CAR_MESH_TAG = "CarMesh" -- every BasePart of a car carries this tag; used to build the hit filter
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

-- ADAPTER: this is the only spot coupled to ReplicatedFirst.HitboxClass (v2.0).
-- The library's real API is:
--   local hitbox = HitboxClass.new(HitboxType --[[string]], opts)
--   hitbox.OnHit:Connect(function(characterModel, hitPart) ... end)
--   hitbox:Start() / hitbox:Destroy()
function Hitbox._startDetection(self)
	-- Tag-driven filtering: exclude every CarMesh-tagged part (this car's meshes,
	-- our hitbox part, and any other car alive right now) at the engine level, so
	-- the spatial query can never report the car itself.
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = CollectionService:GetTagged(CAR_MESH_TAG)
	overlapParams.RespectCanCollide = false

	-- "WeldedBox" re-reads root.CFrame every interval, so the box tracks the car
	-- for the whole (infinite) duration. HitMode "Cooldown" lets the same character
	-- be hit again after HitCooldown -- the default "Weak" caches a character
	-- forever, which a car must not do. No dotProductFilter: its referenceVector is
	-- a Vector3 snapshot taken at construction, which goes stale as soon as the car
	-- turns; the front-welded box already encodes "in front of the car".
	local hitbox = HitboxClass.new("WeldedBox", {
		root = self._part,
		size = self._part.Size,
		duration = math.huge,
		overlapParams = overlapParams,
		HitMode = "Cooldown",
		HitCooldown = HIT_DEBOUNCE,
		velocityPrediction = true,
		velocityMultiplier = 6,
		-- Shared id: HitboxClass.ClearHitboxesWithId("CarHitbox") bulk-stops every
		-- car's hitbox (the maid still owns this one's normal lifetime).
		hitboxId = "CarHitbox",
		-- debug = true,
	})
	self._hitbox = hitbox

	-- OnHit fires per struck character (throttled by HitCooldown) with the
	-- character Model and the specific BasePart that was overlapped.
	local conn = hitbox.OnHit:Connect(function(characterModel, _hitPart)
		local hum = characterModel and characterModel:FindFirstChildOfClass("Humanoid")
		if hum then
			self:_onHit(hum)
		end
	end)

	-- GoodSignal connections expose :Disconnect(), NOT :Destroy(). Handing the raw
	-- connection to Quenty's Maid makes it probe for a Destroy member, which
	-- GoodSignal's strict __index throws on -- so wrap teardown in a function.
	self._maid:GiveTask(function()
		conn:Disconnect()
		hitbox:Destroy() -- Stops the heartbeat loop, clears hit cache + id registry
	end)

	hitbox:Start()
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

	-- Whoever is seated in this car (driver/passenger) is not a descendant of the
	-- car model, so the tag-built blacklist can't cover them -- guard here instead.
	if humanoid.SeatPart and humanoid.SeatPart:IsDescendantOf(self.car) then
		return
	end

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

-- Tags every BasePart of the car (meshes, chassis, our hitbox part) so overlap
-- filtering can be built from CollectionService instead of hardcoded instances.
-- Done at runtime rather than in Studio: every car that binds is always fully
-- tagged, including parts added to the model later.
function Hitbox._tagCarMeshes(self)
	for _, inst in self.car:GetDescendants() do
		if inst:IsA("BasePart") then
			CollectionService:AddTag(inst, CAR_MESH_TAG)
		end
	end
end

function Hitbox.Init(self)
	self._part = self:_buildHitboxPart()
	self:_tagCarMeshes()
end

function Hitbox.Start(self)
	self:_startDetection()
end

return Hitbox
