local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StateMachine = require(ReplicatedStorage.StateMachine)
local Transition = StateMachine.Transition

-- Any -> Die. Attached to every non-terminal state so death is caught wherever
-- the NPC currently is. Fires when the Humanoid is gone or its health is <= 0.
--
-- OnDataChanged is polled every heartbeat by the state machine, so this reacts
-- promptly to damage without needing an explicit ChangeData call.
local Die = Transition.new("Die")

function Die:OnDataChanged(data)
	local humanoid = data.humanoid
	if not humanoid then
		return true
	end
	return humanoid.Health <= 0
end

return Die
