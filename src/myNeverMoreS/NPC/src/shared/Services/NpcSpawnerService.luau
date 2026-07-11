-- NpcSpawnerService
--
-- Backend-only owner of NPC lifecycle. Responsibilities:
--   * create/track the NPCSpawnLocation pads
--   * SpawnNpc: clone a random model from ServerStorage.NPCs onto a pad and tag
--     it "npc" (which is what boots its StateMachineBinder brain)
--   * keep a registry of (model -> spawn location) and, per registered model,
--     watch it: once its parent goes nil, wait 30s and respawn a new one on the
--     same pad.
--
-- Everything the service creates (parts, connections, the binder listener) is
-- owned by a Maid so :Destroy() tears the whole system down cleanly.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Maid = require(ReplicatedStorage.Nevermore.Quenty.maid.Shared.Maid)

local SPAWN_LOCATION_TAG = "NPCSpawnLocation"
-- Must match the NPC binder's tag (the "NPC" key in Main's Binders table). Adding
-- this tag is what makes the BinderProvider construct the brain + fire its
-- GetClassAddedSignal (which calls :Init()).
local NPC_TAG = "NPC"
local RESPAWN_DELAY = 30 -- seconds to wait after an NPC is removed before respawning

-- Grid defaults for programmatically created pads (kept close together so the
-- NPCs share a neighbourhood). Swap for hand-placed pads any time -- the service
-- only ever looks pads up by their tag.
local DEFAULT_COUNT = 24
local DEFAULT_SPACING = 12
local DEFAULT_ORIGIN = Vector3.new(0, 1, 0)

local NpcSpawnerService = {}
NpcSpawnerService.ServiceName = "NpcSpawner"
NpcSpawnerService.__index = NpcSpawnerService

function NpcSpawnerService.new(serviceBag: any?, config: { npcFolder: Instance?, spawnParent: Instance? }?)
	local self = setmetatable({}, NpcSpawnerService)

	config = config or {}
	self._serviceBag = serviceBag
	self._npcFolder = (config :: any).npcFolder or ServerStorage:FindFirstChild("NPCs")
	self._spawnParent = (config :: any).spawnParent or Workspace

	-- model -> { location = BasePart, maid = Maid }
	self._registry = {}
	-- location -> model, so we never double-occupy a pad
	self._occupied = {}

	self._maid = Maid.new()
	self._padFolder = nil

	return self
end

-- Makes sure pads exist and seeds one NPC per pad. The brains themselves are
-- started by Main's BinderProvider wiring (NPCBinder:GetClassAddedSignal ->
-- :Init()), which fires as soon as SpawnNpc tags a model with NPC_TAG.
function NpcSpawnerService:Start()
	if #self:GetSpawnLocations() == 0 then
		self:CreateSpawnLocations()
	end

	self:SpawnAll()
	return self
end

-- Builds a grid of `count` anchored, non-collidable pads tagged as spawn
-- locations. Idempotent-ish: only creates pads, callers guard against re-running.
function NpcSpawnerService:CreateSpawnLocations(count: number?, origin: Vector3?, spacing: number?)
	local padCount: number = count or DEFAULT_COUNT
	local padOrigin: Vector3 = origin or DEFAULT_ORIGIN
	local padSpacing: number = spacing or DEFAULT_SPACING

	local folder = self._padFolder
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "NPCSpawnLocations"
		folder.Parent = self._spawnParent
		self._maid:GiveTask(folder)
		self._padFolder = folder
	end

	-- Lay them out in a roughly square grid so they stay near each other.
	local perRow = math.ceil(math.sqrt(padCount))
	for i = 0, padCount - 1 do
		local row = math.floor(i / perRow)
		local col = i % perRow
		local pad = Instance.new("Part")
		pad.Name = "NPCSpawnLocation"
		pad.Size = Vector3.new(4, 1, 4)
		pad.Anchored = true
		pad.CanCollide = false
		pad.CanQuery = false
		pad.CanTouch = false
		pad.Transparency = 0.5
		pad.Color = Color3.fromRGB(120, 200, 120)
		pad.Position = padOrigin + Vector3.new(col * padSpacing, 0, row * padSpacing)
		pad:AddTag(SPAWN_LOCATION_TAG)
		pad.Parent = folder
	end

	return self:GetSpawnLocations()
end

function NpcSpawnerService:GetSpawnLocations(): { BasePart }
	local pads = {}
	for _, inst in CollectionService:GetTagged(SPAWN_LOCATION_TAG) do
		if inst:IsA("BasePart") then
			table.insert(pads, inst)
		end
	end
	return pads
end

-- Picks a random NPC model from ServerStorage.NPCs.
function NpcSpawnerService:_randomNpcModel(): Model?
	local folder = self._npcFolder
	if not folder then
		warn("[NpcSpawnerService] ServerStorage.NPCs not found -- cannot spawn")
		return nil
	end
	local models = {}
	for _, child in folder:GetChildren() do
		if child:IsA("Model") then
			table.insert(models, child)
		end
	end
	if #models == 0 then
		warn("[NpcSpawnerService] no Models under ServerStorage.NPCs")
		return nil
	end
	return models[math.random(#models)]
end

-- Spawns a random NPC on the given pad (or a random free pad), tags it "npc" so
-- its binder starts, and registers it for respawn tracking. Returns the model.
function NpcSpawnerService:SpawnNpc(spawnLocation: BasePart?): Model?
	spawnLocation = spawnLocation or self:_randomFreePad()
	if not spawnLocation then
		warn("[NpcSpawnerService] no free spawn location available")
		return nil
	end

	local template = self:_randomNpcModel()
	if not template then
		return nil
	end

	local model = template:Clone()
	-- Sit the model just above the pad.
	local padCFrame = (spawnLocation :: BasePart).CFrame
	model:PivotTo(padCFrame * CFrame.new(0, 3, 0))
	model.Parent = self._spawnParent

	-- Tag last, after it's parented and positioned, so the binder sees a ready model.
	model:AddTag(NPC_TAG)

	self:_register(model, spawnLocation :: BasePart)
	return model
end

-- One NPC per pad on startup.
function NpcSpawnerService:SpawnAll()
	for _, pad in self:GetSpawnLocations() do
		if not self._occupied[pad] then
			self:SpawnNpc(pad)
		end
	end
end

function NpcSpawnerService:_randomFreePad(): BasePart?
	local free = {}
	for _, pad in self:GetSpawnLocations() do
		if not self._occupied[pad] then
			table.insert(free, pad)
		end
	end
	if #free == 0 then
		return nil
	end
	return free[math.random(#free)]
end

-- Records the spawned model against its pad and starts watching it. When the
-- model leaves the DataModel we wait RESPAWN_DELAY and spawn a replacement on
-- the same pad.
function NpcSpawnerService:_register(model: Model, spawnLocation: BasePart)
	local entryMaid = Maid.new()
	self._registry[model] = { location = spawnLocation, maid = entryMaid }
	self._occupied[spawnLocation] = model

	-- The connection lives on the entry maid, which itself lives on the service
	-- maid, so it is cleaned on respawn AND on service teardown.
	self._maid:GiveTask(entryMaid)

	entryMaid:GiveTask(model.AncestryChanged:Connect(function(_, parent)
		if parent then
			return
		end
		-- Model was removed/destroyed: free the registry + pad, then respawn later.
		self._registry[model] = nil
		if self._occupied[spawnLocation] == model then
			self._occupied[spawnLocation] = nil
		end
		entryMaid:DoCleaning()

		self._maid:GiveTask(task.delay(RESPAWN_DELAY, function()
			-- Guard: service may have been destroyed during the wait.
			if self._padFolder == nil and self._spawnParent == nil then
				return
			end
			self:SpawnNpc(spawnLocation)
		end))
	end))
end

function NpcSpawnerService:Destroy()
	self._maid:DoCleaning()
	table.clear(self._registry)
	table.clear(self._occupied)
end

return NpcSpawnerService
