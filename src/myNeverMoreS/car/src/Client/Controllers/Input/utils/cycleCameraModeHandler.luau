local cycleCameraModeEvent = game.ReplicatedStorage.RemoteEvents.CycleCameraMode

local function cycleCameraModeHandler(_, inputState: Enum.UserInputState)
	if inputState == Enum.UserInputState.Begin then
		cycleCameraModeEvent:Fire()
	end
end

return cycleCameraModeHandler
