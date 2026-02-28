local ReplicatedStorage = game:GetService("ReplicatedStorage")
local cycleCameraModeEvent = ReplicatedStorage.Nevermore.Custom.car.src.Client.Controllers.Camera.CycleCameraMode

local function cycleCameraModeHandler(_, inputState: Enum.UserInputState)
	if inputState == Enum.UserInputState.Begin then
		cycleCameraModeEvent:Fire()
	end
end

return cycleCameraModeHandler
