local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CarConstants = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.CarConstants)

local car = script.Parent.Parent.Parent.Parent
local inputs = car.Inputs

local function handBrakeHandler(_, inputState: Enum.UserInputState)
	if inputState == Enum.UserInputState.Begin then
		inputs:SetAttribute(CarConstants.HAND_BRAKE_INPUT_ATTRIBUTE, true)
	else
		inputs:SetAttribute(CarConstants.HAND_BRAKE_INPUT_ATTRIBUTE, false)
	end
end

return handBrakeHandler
