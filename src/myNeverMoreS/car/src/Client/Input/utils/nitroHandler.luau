local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CarConstants = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.CarConstants)

local car = script.Parent.Parent.Parent.Parent
local inputs = car.Inputs

local function nitroHandler(_, inputState: Enum.UserInputState)
	if inputState == Enum.UserInputState.Begin then
		inputs:SetAttribute(CarConstants.NITRO_INPUT_ATTRIBUTE, true)
	else
		inputs:SetAttribute(CarConstants.NITRO_INPUT_ATTRIBUTE, false)
	end
end

return nitroHandler
