local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CarConstants = require(ReplicatedStorage.Nevermore.Custom.car.src.Shared.CarConstants)

local function nitroHandler(inputState: Enum.UserInputState, inputs)
	if inputState == Enum.UserInputState.Begin then
		inputs:SetAttribute(CarConstants.NITRO_INPUT_ATTRIBUTE, true)
	else
		inputs:SetAttribute(CarConstants.NITRO_INPUT_ATTRIBUTE, false)
	end
end

return nitroHandler
