--||Services||--
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CarConstants = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.CarConstants)
local setupCollisionGroups = require(ServerScriptService.Collision)
--||Nevermore Shit||--
----------------------------- getting servicebag and loader -----------------------------

local NeverMorePackages = RS.Nevermore
local loader = NeverMorePackages:FindFirstChild("LoaderUtils", true).Parent
local Nevermore = require(loader).bootstrapGame(NeverMorePackages)

local ServiceBag = Nevermore("ServiceBag")
local serviceBag = ServiceBag.new()

----------------------------- init process -----------------------------
_G.FistBag = serviceBag

---------- COLDOWNS ----------
---------- OTHERS ----------
---------- BINDERS ----------
local Binder = Nevermore("Binder")
local Car = Nevermore("Car")
local NPC = Nevermore("StateMachineBinder")

local Binders = {
	["Car"] = Car,
	["NPC"] = NPC,
}
---------- USE BINDER PORVIDER ----------
local BinderProvider = Nevermore("BinderProvider")

local AttacksBinders = BinderProvider.new("Binders", function(self, serviceBag)
	for tag, contructor in pairs(Binders) do
		self:Add(Binder.new(tag, contructor), serviceBag, "test")
	end
end)
----- ------------------------ INIT SERVICEBAG -----------------------------
serviceBag:GetService(AttacksBinders)
----- ------------------------ START SERVICEBAG -----------------------------
serviceBag:Init()
serviceBag:Start()
_G.FistBag = nil
_G.ServiceBag = serviceBag
_G.BinderProvider = AttacksBinders

setupCollisionGroups()

---== Remotes ==---
local remotes = ReplicatedStorage.RemoteEvents
local setNitroEnabledRemote = remotes.SetNitroEnabled
local BinderProviderInitialized = serviceBag:GetService(AttacksBinders)

local carBinder = BinderProviderInitialized:Get("Car")

carBinder:GetClassAddedSignal():Connect(function(car)
	car:Init()
	car:Start()
end)

local NPCBinder = BinderProviderInitialized:Get("NPC")

NPCBinder:GetClassAddedSignal():Connect(function(NPC)
	NPC:Init()
end)

---== NPC Spawner ==---
-- Builds the spawn pads and seeds an NPC on each. SpawnNpc tags each model "NPC",
-- which is what makes NPCBinder above construct + :Init() its brain.
local NpcSpawnerService = require(ReplicatedStorage.NPC.Services.NpcSpawnerService)
local npcSpawner = NpcSpawnerService.new(serviceBag)
npcSpawner:Start()

-- TODO GET THE CAR TO SET THE NITRO
setNitroEnabledRemote.OnServerEvent:Connect(function(player: Player, car: Model, isNitro: boolean)
	local binder = carBinder:Get(car)
	binder:OnSetNitroEnabledEvent(player, isNitro)
end)

local carKioskBinder = BinderProviderInitialized:Get("CarSpawnKiosk")

remotes.ChooseCar.OnServerEvent:Connect(function(player: Player, carInformation)
	if not carInformation then
		return
	end
	if not carInformation.obj then
		return
	end
	local binder = carKioskBinder:Get(carInformation.obj)
	if not binder then
		return
	end
	binder:SpawnCar(player, carInformation)
end)

local getOwnerTag = require(ReplicatedStorage.Nevermore.Custom.carSpawning.src.Server.utils.getOwnerTag)

local template = workspace["Fletcher Thunderbolt"]
Players.PlayerAdded:Connect(function(a0: Player)
	local ownerTag = getOwnerTag(a0)
	template:AddTag(ownerTag)
	template:AddTag("Car")
	-- Since instance references can't be stored in attributes, the car owner is stored by UserId
	template:SetAttribute(CarConstants.CAR_OWNER_ATTRIBUTE, a0.UserId)
end)

