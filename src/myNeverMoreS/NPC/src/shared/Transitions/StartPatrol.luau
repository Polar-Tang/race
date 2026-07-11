local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StateMachine = require(ReplicatedStorage.StateMachine)
local Transition = StateMachine.Transition

-- Idle -> Patrol. Fires once enough idle time has elapsed since the last patrol.
local StartPatrol = Transition.new("Patrol")

function StartPatrol:OnDataChanged(data)
	return (data.timer - data.lastPatrolTime) >= data.patrol_interval
end

return StartPatrol
