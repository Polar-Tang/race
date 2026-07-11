local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StateMachine = require(ReplicatedStorage.StateMachine)
local State = StateMachine.State

-- Terminal state. Reached from any other state the moment the Humanoid's health
-- hits zero (see the Die transition). Its whole job is to tear the NPC's brain
-- down by destroying the binder parent, which in turn cleans every controller,
-- connection and the state machine itself.
--
-- Note: it has NO outgoing transitions -- once dead, always dead.
local Die = State.new("Die")

Die.Transitions = {}

function Die:OnEnter(data)
	-- Halt behaviour immediately and play the death animation if one exists.
	if data.MovementController then
		data.MovementController:Stop()
	end
	if data.EatController then
		data.EatController:StopAnim()
	end
	if data.PetAnimatorController then
		data.PetAnimatorController:StopAll()
		data.PetAnimatorController:LoadAnimation(true, "die")
	end
	if data.SoundController then
		data.SoundController:Play("die")
	end

	-- Defer the teardown so we don't destroy the state machine from inside its own
	-- transition/heartbeat pass. binder:Destroy() runs the binder maid, which owns
	-- every controller AND the state machine, so this single call is the full,
	-- leak-free cleanup the summary asks for.
	local binder = data.binder
	if binder then
		task.defer(function()
			binder:Destroy()
		end)
	end
end

return Die
