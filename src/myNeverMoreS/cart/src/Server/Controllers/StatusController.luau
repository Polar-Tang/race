local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local AbstractController = require(script.Parent.AbstractController)
local ControllersTypes = require(script.Parent.ControllersTypes)

local StatusController = setmetatable({}, AbstractController)
StatusController.__index = StatusController

function StatusController.new(config: ControllersTypes.ControllConstructor): ControllersTypes.StatusController
	local self = setmetatable(AbstractController.new(config), StatusController) :: any
	self.CurrentPlayer = nil
	return self
end

function StatusController.occupantIsPlayer(self: ControllersTypes.StatusController, player: Player): boolean
	local occupant = self._seat.Occupant
	if occupant then
		return occupant.Parent == player.Character
	end
	return false
end

function StatusController.setUp(self: ControllersTypes.StatusController, player: Player)
	local playerGui = player:FindFirstChild("PlayerGui") :: PlayerGui
	if not playerGui:FindFirstChild("LocalCartUI") then
		local LocalCartUI = ServerStorage:FindFirstChild("LocalCartUI")

		local localScript = LocalCartUI:Clone()
		localScript.Disabled = false
		localScript.Parent = playerGui
	end
end
function StatusController.isSeatAvaible(self: ControllersTypes.StatusController): boolean
	return not self._seat.Occupant
end

function StatusController.vacate(self: ControllersTypes.StatusController)
	local occupant = self._seat.Occupant
	if occupant then
		occupant.Sit = false
	end
	self._seat.Disabled = true
end

function StatusController.init(self: ControllersTypes.StatusController)
	local occupantCon = self._seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local currentOccupant = self._seat.Occupant
		if currentOccupant then
			self.CurrentPlayer = Players:GetPlayerFromCharacter(currentOccupant.Parent)
		end
		if self.CurrentPlayer then
			local LocalCartUI = script:WaitForChild("LocalCartUI")
			local CartDriverModule = script:WaitForChild("CartDriverModule")

			local playerGui = self.CurrentPlayer:FindFirstChild("PlayerGui") :: PlayerGui
			if not playerGui:FindFirstChild("LocalCartUI") then
				local localScript = LocalCartUI:Clone()
				localScript.Disabled = false
				CartDriverModule:Clone().Parent = localScript
				localScript.Parent = playerGui
			end
		end
	end)

	self._maid:GiveTask(occupantCon)
end

function StatusController.occupantIsPlayerOrNone(self: ControllersTypes.StatusController)
	return not self._seat.Occupant
end

return StatusController
