local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CarConstants = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.CarConstants)

local AbsController = require(ReplicatedStorage.Nevermore.Custom.car.src.Server.Controllers.utils.AbsController)
local ControllersTypes = require(ReplicatedStorage.Nevermore.Custom.car.src.Server.Controllers.utils.ControllersTypes)

local Occupant = setmetatable({}, AbsController)
Occupant.__index = Occupant
Occupant.ClassName = "Occupant"

function Occupant.new(config: ControllersTypes.ControllConstructor): ControllersTypes.OccupantController
	local self = setmetatable(AbsController.new(config), Occupant)
	self._owner = nil
	self._drivePrompt = self.chassis.DrivePromptAttachment.DrivePrompt

	print("self ",self)
	return self
end

-- Force a character to sit in the car
function Occupant.Enter(self: ControllersTypes.OccupantController, character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	assert(humanoid, "No humanoid found!")
	if self.driverSeat.Occupant then
		return
	end

	self.driverSeat:Sit(humanoid)
end

-- Set network ownership when a player sits in the car
function Occupant._onOccupantChanged(self: ControllersTypes.OccupantController)
	local humanoid = self.driverSeat.Occupant
	self._drivePrompt.Enabled = humanoid == nil

	if humanoid then
		local character = humanoid.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			self.driverSeat:SetNetworkOwner(player)
		end
	end
end

function Occupant.UpdateOwner(self: ControllersTypes.OccupantController)
	-- Since instance references can't be stored in attributes, the car owner is stored by UserId
	local ownerUserId = self.car:GetAttribute(CarConstants.CAR_OWNER_ATTRIBUTE)
	if ownerUserId then
		self._owner = Players:GetPlayerByUserId(ownerUserId)
	else
		self._owner = nil
	end

	-- Update the drive prompt to show who the car belongs to
	if self._owner then
		self._drivePrompt.ObjectText = `{self._owner.DisplayName}'s car`
	else
		self._drivePrompt.ObjectText = ""
	end
end

function Occupant.Start(self: ControllersTypes.OccupantController)
	self._maid:GiveTask(self.driverSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
		self:_onOccupantChanged()
	end))
	self._maid:GiveTask(self._drivePrompt.Triggered:Connect(function(player: Player)
		if self._owner then
			if player ~= self._owner then
				return
			end
		end

		local character = player.Character
		if character then
			self:Enter(character)
		end
	end))

	self._maid:GiveTask(
		self.inputs:GetAttributeChangedSignal(CarConstants.KEYBOARD_ENTER_KEY_CODE_ATTRIBUTE):Connect(function()
			self._drivePrompt.KeyboardKeyCode =
				self.inputs:GetAttribute(CarConstants.KEYBOARD_ENTER_KEY_CODE_ATTRIBUTE) :: Enum.KeyCode
		end)
	)
	self._maid:GiveTask(
		self.inputs:GetAttributeChangedSignal(CarConstants.GAMEPAD_ENTER_KEY_CODE_ATTRIBUTE):Connect(function()
			self._drivePrompt.GamepadKeyCode =
				self.inputs:GetAttribute(CarConstants.GAMEPAD_ENTER_KEY_CODE_ATTRIBUTE) :: Enum.KeyCode
		end)
	)
	self._maid:GiveTask(self.car:GetAttributeChangedSignal(CarConstants.CAR_OWNER_ATTRIBUTE):Connect(function()
		self:UpdateOwner()
	end))

	self._drivePrompt.KeyboardKeyCode =
		self.inputs:GetAttribute(CarConstants.KEYBOARD_ENTER_KEY_CODE_ATTRIBUTE) :: Enum.KeyCode
	self._drivePrompt.GamepadKeyCode =
		self.inputs:GetAttribute(CarConstants.GAMEPAD_ENTER_KEY_CODE_ATTRIBUTE) :: Enum.KeyCode

	self:UpdateOwner()
end

return Occupant
