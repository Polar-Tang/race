local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StateMachine = require(ReplicatedStorage.StateMachine)
local Transition = StateMachine.Transition

-- Patrol -> Idle. Fires once the patrol has run for its (movement-derived) duration.
local FinnishPatrol = Transition.new("Idle")

function FinnishPatrol:OnDataChanged(data)
	return (data.timer - data.patrolStartTime) >= data.patrol_duration
end

return FinnishPatrol
