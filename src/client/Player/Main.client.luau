--||Services||--
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--||Nevermore Shit||--
---------------------------getting servicebag and loader -----------------------------

local NeverMorePackages = RS.Nevermore
local loader = NeverMorePackages:FindFirstChild("LoaderUtils", true).Parent
local Nevermore = require(loader).bootstrapGame(NeverMorePackages)

local ServiceBag = Nevermore("ServiceBag")
local serviceBag = ServiceBag.new()

---------------------------------
local istTaggedArmed
local isServiceBagInitialized
---------------------------------

--------------------------- Binders -----------------------------

local Binder = Nevermore("Binder")
local CarClient = Nevermore("CarClient")

local Binders = {
	["Car"] = CarClient,
}
---------- USE BINDER PORVIDER ----------
local BinderProvider = Nevermore("BinderProvider")

local AttacksBinders = BinderProvider.new("Binders", function(self, serviceBag)
	for tag, contructor in pairs(Binders) do
		self:Add(Binder.new(tag, contructor), serviceBag, "test")
	end
end)
serviceBag:GetService(AttacksBinders)
--------------------------- END Binders -----------------------------
--------------------------- INIT -----------------------------
serviceBag:Init()

local BinderProviderInitialized = serviceBag:GetService(AttacksBinders)
-------------------------START SERVICEBAG -----------------------------

serviceBag:Start()
----- ------------------------ START SERVICEBAG -----------------------------
_G.ServiceBagClient = serviceBag
_G.BinderProviderClient = AttacksBinders
isServiceBagInitialized = true
------------- ONCE INITIALIZED -------------
-- Ensures Roact App start after intializing service bag

local carBinder = BinderProviderInitialized:Get("Car")

carBinder:GetClassAddedSignal():Connect(function(car)
	car:Init()
	print("Calling start")
	-- car:Start()
end)

local _ = require(script.Parent.components.ChooseCar)
