--||Services||--
local RS = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local setupCollisionGroups = require(ServerScriptService.utils.setupCollisionGroups)
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
local Cart = Nevermore("Cart")

local Binders = {
	["Cart"] = Cart,
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
