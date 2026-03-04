--||Services||--
local RS = game:GetService("ReplicatedStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
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
local CarSpawning = Nevermore("CarSpawning")

local Binders = {
	["Car"] = Car,
	["CarSpawnKiosk"] = CarSpawning,
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
	local car_template = workspace.Cart
	local descendants = car_template:GetDescendants()
	for _, descendant in ipairs(descendants) do
		if descendant:IsA("Attachment") then
			local constraints = descendant:GetConstraints()

			print(descendant.Name, constraints)
			print(descendant)
			if next(constraints) == nil then
				print(
					"ATT WITN NO CONSTRAINT FOUNR ON "
						.. descendant.Parent.Parent.Parent.Name
						.. "."
						.. descendant.Parent.Parent.Name
						.. "."
						.. descendant.Parent.Name
						.. "."
				)
				--Attachment1=HingeATTACHMENT
				--ATTACHMENT0=HingeAttachmentRR
			end

			print("------------------------------------------------------------")
		end
	end
end)

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
