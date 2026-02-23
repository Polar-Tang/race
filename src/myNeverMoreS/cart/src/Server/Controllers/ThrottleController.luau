local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CartTypes = require(ReplicatedStorage.Nevermore.Custom.cart.src.Server.Binder.CartTypes)
local AbstractController = require(script.Parent.AbstractController)
local ControllersTypes = require(script.Parent.ControllersTypes)

local ButtonUpdatedThrottle = game.ReplicatedStorage.RemoteEvents.ButtonUpdatedThrottle

local ThrottleController = setmetatable({}, AbstractController)
ThrottleController.__index = ThrottleController

function ThrottleController.new(config: ControllersTypes.ControllConstructor): ControllersTypes.ThrottleController
	local self = setmetatable(AbstractController.new(config), ThrottleController) :: any

	self.Throttle = self._cart:WaitForChild("Throttle")

	return self
end

function ThrottleController.SetThrottle(self: ControllersTypes.ThrottleController, throttle)
	self.Throttle.Value = math.clamp(throttle, -1.0, 1.0)
end

function ThrottleController.init(self: ControllersTypes.ThrottleController, cart: CartTypes.CartDriver)
	local Buttons = self._cart:WaitForChild("Buttons")

	local ThrottleDisplay = Buttons:WaitForChild("Display"):WaitForChild("SurfaceGui"):WaitForChild("Throttle")
	local function UpdateDisplay()
		ThrottleDisplay.Text = tostring(math.floor(self.Throttle.Value * 100))
	end
	self._maid:GiveTask(self.Throttle:GetPropertyChangedSignal("Value"):Connect(UpdateDisplay))

	local statusController: ControllersTypes.StatusController = cart:getController("statusController")

	local StopButton = Buttons:WaitForChild("Stop"):WaitForChild("ClickDetector")
	local clickDetectorConL = StopButton.MouseClick:Connect(function(player)
		if statusController:isSeatAvaible() and statusController:occupantIsPlayer(player) then
			self.Throttle.Value = 0
			ButtonUpdatedThrottle:FireClient(player, self.Throttle.Value)
		end
	end)
	self._maid:GiveTask(clickDetectorConL)

	local StartButton = Buttons:WaitForChild("Start"):WaitForChild("ClickDetector")
	local clickDetectorConR = StartButton.MouseClick:Connect(function(player)
		if statusController:isSeatAvaible() and statusController:occupantIsPlayer(player) then
			self.Throttle.Value = 0.5
			ButtonUpdatedThrottle:FireClient(player, self.Throttle.Value)
		end
	end)
	self._maid:GiveTask(clickDetectorConR)
end

return ThrottleController
--[[
	


]]
