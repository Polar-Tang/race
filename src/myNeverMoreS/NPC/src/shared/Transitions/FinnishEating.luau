local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StateMachine = require(ReplicatedStorage.StateMachine)
local Transition = StateMachine.Transition

-- Eat -> Idle. Fires once the eat animation has run for its configured duration.
local FinnishEating = Transition.new("Idle")

function FinnishEating:OnDataChanged(data)
	return (data.timer - data.eatingStartTime) >= data.eat_duration
end

return FinnishEating
