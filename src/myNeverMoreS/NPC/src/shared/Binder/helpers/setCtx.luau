-- Builds the shared context (`data`) table used by every state, transition and
-- controller of a single NPC's state machine.
--
-- Responsibilities:
--   * resolve the NPC's parts / humanoid / owner
--   * instantiate the domain controllers and hand each one to the *binder* maid
--     so a single binder:Destroy() tears every one of them down (no leaks)
--   * expose the timers + tuning values the Idle/Patrol/Eat/Die flow reads
--
-- The returned table is passed straight into StateMachine.new as its data, so
-- `data.MovementController`, `data.timer`, etc. are what states/transitions see.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Controllers = ReplicatedStorage.NPC.Controllers
local MovementController = require(Controllers.MovementController.MovementController)
local TargetingController = require(Controllers.TargetController.TargetController)
local SoundController = require(Controllers.SoundController.SoundController)
local AnimatorController = require(Controllers.AnimatorController.AnimatorController)

export type NpcContext = typeof(setmetatable({}, {})) -- opaque; see the return below

-- Resolves the NPC's root part. Clients may not replicate it immediately, so we
-- wait a bounded amount rather than yielding forever.
local function resolveRoot(pet: Model): BasePart?
	local root = pet:FindFirstChild("Rootpart") or pet:FindFirstChild("HumanoidRootPart") or pet.PrimaryPart
	if root and root:IsA("BasePart") then
		return root
	end
	-- last resort: wait briefly for a HumanoidRootPart
	return pet:WaitForChild("HumanoidRootPart", 5) :: BasePart?
end

-- Figures out whether the local player owns this NPC. Owner is stored by UserId
-- (instance refs can't live in attributes / ObjectValues cross-network reliably).
local function isLocallyOwned(pet: Model, player: Player?): boolean
	if not player then
		return false
	end
	local ownerValue = pet:FindFirstChild("Owner")
	if ownerValue and ownerValue:IsA("ObjectValue") and ownerValue.Value then
		return ownerValue.Value == player
	end
	local ownerId = pet:GetAttribute("Owner")
	return ownerId ~= nil and tostring(ownerId) == tostring(player.UserId)
end

return function(pet: Model, serviceBag: any, player: Player?, maid: any, binder: any)
	local petName = pet:GetAttribute("petName") :: string?
	local stats = {
		-- Example species overrides. Add one entry per `petName` you ship.
		walkSpeed = 12,
		range = 60,
		patrol_interval = 4,
		patrol_duration = 7,
		eat_interval = 10,
		eat_duration = 3,
		sounds = {
			scream1 ="rbxassetid://86610831329252",
			scream2 = "rbxassetid://76241194670489",
			scream3 = "rbxassetid://93492108928718",
		},
	}

	local root = resolveRoot(pet)
	local humanoid = pet:WaitForChild("Humanoid", 5) :: Humanoid?
	local isOwnerLocal = isLocallyOwned(pet, player)

	-- `petCtx` is the sub-context handed to controllers. It's a subset of the
	-- machine data focused on "what does the pet look like / where is it".
	local homePosition = root and root.Position or Vector3.zero
	local petCtx = {
		pet = pet,
		root = root,
		humanoid = humanoid,
		petName = petName,
		stats = stats,
		range = stats.range,
		home = homePosition,
		isOwnerLocal = isOwnerLocal,
		serviceBag = serviceBag,
	}

	-------- Controllers --------
	-- Every controller is handed to the binder maid so one :DoCleaning() tears
	-- them all down (connections, Heartbeat loops, tweens, animations).
	local controllers = {
		MovementController = MovementController.new(petCtx, serviceBag, player),
		TargetingController = TargetingController.new(petCtx, serviceBag, player),
		PetAnimatorController = AnimatorController.new(petCtx, serviceBag, player),
		-- Created unconditionally (not owner-gated): server-spawned NPCs have no
		-- owner but still need to scream when hurt (see the HealthChanged hook below).
		SoundController = SoundController.new(petCtx, serviceBag, player),
	}

	for _, controller in controllers do
		maid:GiveTask(controller)
	end

	-- Scream on damage. HealthChanged fires on any health delta, so we only react
	-- when it actually drops. The connection is owned by the binder maid, so it is
	-- disconnected together with the rest of the NPC on teardown.
	if humanoid and controllers.SoundController then
		local screamKeys = {}
		local sounds = stats.sounds
		if sounds then
			for key in sounds do
				table.insert(screamKeys, key)
			end
		end

		local lastHealth = humanoid.Health
		maid:GiveTask(humanoid.HealthChanged:Connect(function(newHealth: number)
			if newHealth < lastHealth and #screamKeys > 0 then
				controllers.SoundController:Play(screamKeys[math.random(#screamKeys)])
			end
			lastHealth = newHealth
		end))
	end

	-- Let sibling controllers reach each other through the shared petCtx. In
	-- particular EatController plays its clip through the single PetAnimatorController.
	petCtx.PetAnimatorController = controllers.PetAnimatorController
	petCtx.MovementController = controllers.MovementController

	return {
		-- identity / lifecycle
		binder = binder, -- so the Die state can tear the whole NPC down
		maid = maid,
		pet = pet,
		root = root,
		humanoid = humanoid,
		home = homePosition,
		range = stats.range,
		isOwnerLocal = isOwnerLocal,

		-- timers (all in seconds, advanced by each state's OnHeartbeat)
		timer = 0,
		lastIdleTime = 0,
		lastPatrolTime = 0,
		lastEatTime = 0,
		patrolStartTime = 0,
		eatingStartTime = 0,

		-- tuning pulled from petData
		patrol_interval = stats.patrol_interval,
		patrol_duration = stats.patrol_duration,
		eat_interval = stats.eat_interval,
		eat_duration = stats.eat_duration,

		-------- controllers --------
		MovementController = controllers.MovementController,
		TargetingController = controllers.TargetingController,
		PetAnimatorController = controllers.PetAnimatorController,
		SoundController = controllers.SoundController,
	}
end
