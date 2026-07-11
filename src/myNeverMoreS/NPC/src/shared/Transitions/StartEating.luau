local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StateMachine = require(ReplicatedStorage.StateMachine)
local Transition = StateMachine.Transition

-- Idle -> Eat. Fires once enough idle time has elapsed since the last meal.
local StartEating = Transition.new("Eat")

function StartEating:OnDataChanged(data)
	return (data.timer - data.lastEatTime) >= data.eat_interval
end

return StartEating
