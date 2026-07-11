-- StateMachineBinder
--
-- The per-NPC "brain owner". One StateMachineBinder is created for each NPC
-- model. It owns:
--   * a single top-level Maid that holds every controller, service and
--     connection built for this NPC (see setCtx)
--   * the RobloxStateMachine instance that drives Idle/Patrol/Eat/Die
--
-- Because everything is registered with `self.maid`, a single :Destroy() call
-- tears the whole NPC down with no dangling Heartbeat connections, tweens,
-- animation tracks or promises -- i.e. no memory leakage.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Maid = require(ReplicatedStorage.Nevermore.Quenty.maid.Shared.Maid)
local StateMachine = require(ReplicatedStorage.StateMachine)
local setCtx = require(script.Parent.helpers.setCtx)

local StatesFolder = ReplicatedStorage.NPC.States

local StateMachineBinder = {}
StateMachineBinder.ServiceName = "StateMachine"
StateMachineBinder.__index = StateMachineBinder

function StateMachineBinder.new(char: Model, serviceBag: any)
	local self = setmetatable({}, StateMachineBinder)

	self.char = char
	self.state = nil
	self._initialized = false
	self._destroyed = false
	self._players = {}
	self.serviceBag = serviceBag
	self.maid = Maid.new()

	-- If the model leaves the DataModel we must still clean up, even if nothing
	-- called :Destroy() explicitly (e.g. streamed out, parent removed).
	self.maid:GiveTask(char.AncestryChanged:Connect(function(_, parent)
		if not parent then
			self:Destroy()
		end
	end))

	return self
end

-- Called for a nearby player. Builds the context (which spawns the controllers)
-- and boots the state machine that acts as the NPC's brain.
function StateMachineBinder:Init(player: Player?)
	if self._initialized or self._destroyed then
		return self
	end
	self._initialized = true

	-- The state machine *is* the NPC's brain. setCtx wires all controllers into
	-- self.maid and hands back the shared data table.
	local state = StateMachine.new(
		"Idle",
		StateMachine:LoadDirectory(StatesFolder),
		setCtx(self.char, self.serviceBag, player, self.maid, self)
	)

	-- Own the machine on the maid too, so :Destroy() also tears it down even when
	-- teardown is triggered by AncestryChanged rather than the Die state.
	self.maid:GiveTask(function()
		state:Destroy()
	end)

	self.state = state
	return self
end

function StateMachineBinder:GetState(): string?
	return self.state and self.state:GetCurrentState() or nil
end

function StateMachineBinder:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true

	-- One call: disconnects AncestryChanged, destroys the state machine, and
	-- destroys every controller/service registered in setCtx.
	self.maid:DoCleaning()
	self.state = nil
end

--[[
	Collection helper -- wires the binder to a CollectionService tag so a fresh
	brain is Init()'d the first time an NPC is tagged and torn down when it is
	untagged/removed. This is the "connect to the class-added signal" entry point.

	```lua
	local disconnect = StateMachineBinder.listen("NPC", serviceBag, localPlayer)
	```

	@param tag string          -- CollectionService tag identifying NPC models
	@param serviceBag any       -- Nevermore service bag
	@param player Player?        -- the player this brain is running for (client)
	@return () -> ()             -- call to stop listening + tear down all binders
]]
function StateMachineBinder.listen(tag: string, serviceBag: any, player: Player?): () -> ()
	local maid = Maid.new()
	local binders: { [Instance]: any } = {}

	local function onAdded(instance: Instance)
		if not instance:IsA("Model") or binders[instance] then
			return
		end
		local binder = StateMachineBinder.new(instance, serviceBag)
		binders[instance] = binder
		-- Destroying the binder when the maid cleans is enough; the binder's own
		-- maid owns the state machine and controllers.
		maid:GiveTask(function()
			if binders[instance] then
				binders[instance]:Destroy()
				binders[instance] = nil
			end
		end)
		binder:Init(player)
	end

	local function onRemoved(instance: Instance)
		local binder = binders[instance]
		if binder then
			binder:Destroy()
			binders[instance] = nil
		end
	end

	maid:GiveTask(CollectionService:GetInstanceAddedSignal(tag):Connect(onAdded))
	maid:GiveTask(CollectionService:GetInstanceRemovedSignal(tag):Connect(onRemoved))

	for _, instance in CollectionService:GetTagged(tag) do
		onAdded(instance)
	end

	return function()
		maid:DoCleaning()
	end
end

return StateMachineBinder
