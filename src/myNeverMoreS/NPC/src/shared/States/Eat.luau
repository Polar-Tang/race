local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StateMachine = require(ReplicatedStorage.StateMachine)
local State = StateMachine.State

-- Eat stops the NPC and plays the eating animation for `eat_duration` seconds
-- before returning to Idle.
local Eat = State.new("Eat")

Eat.Transitions = {
	require(script.Parent.Parent.Transitions.FinnishEating),
	require(script.Parent.Parent.Transitions.Die),
}

function Eat:OnEnter(data)
	data.eatingStartTime = data.timer

	if data.MovementController then
		data.MovementController:Stop()
	end
	if data.EatController then
		-- EatController drives the shared AnimatorController.
		data.EatController:Eat(data.AnimatorController)
	end
	if data.SoundController then
		data.SoundController:Play("eat")
	end
end

function Eat:OnLeave(data)
	-- Reset the eat interval clock from the moment eating ended.
	data.lastEatTime = data.timer
	if data.EatController then
		data.EatController:StopAnim(data.AnimatorController)
	end
	if data.SoundController then
		data.SoundController:Stop("eat")
	end
end

function Eat:OnHeartbeat(data, deltaTime)
	data.timer += deltaTime
end

return Eat
