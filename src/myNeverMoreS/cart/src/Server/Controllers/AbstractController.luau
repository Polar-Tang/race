local RS = game:GetService("ReplicatedStorage")

local packages = RS.Nevermore.Quenty
local BaseObject = require(packages.baseobject.Shared.BaseObject)
local ControllersTypes = require(script.Parent.ControllersTypes)

local AbstractController = setmetatable({}, BaseObject)
AbstractController.__index = AbstractController

function AbstractController.new(cart: Model, serviceBag: any, data: ControllersTypes.ControllConstructor)
	local self = setmetatable(BaseObject.new() :: any, AbstractController)

	self._cart = cart
	self._root = cart.PrimaryPart
	self._seat = data.seat

	self._serviceBag = serviceBag

	return self
end

return AbstractController :: ControllersTypes.ControllerBase
