--!strict
local AbstractController = require(script.Parent.AbstractController)
local ControllersTypes = require(script.Parent.ControllersTypes)

local ParticleEffectsController = setmetatable({}, AbstractController)
ParticleEffectsController.__index = ParticleEffectsController

function ParticleEffectsController.new(
	config: ControllersTypes.ControllConstructor
): ControllersTypes.ParticleEffectsController
	local self = setmetatable(AbstractController.new(config), ParticleEffectsController) :: any

	local Cart = config.cart
	local Base = Cart:WaitForChild("Base")

	local Prismatics = Base:WaitForChild("Prismatics")
	local FrontLeftSparks = Base:WaitForChild("FrontLeftSparks")
	local FrontRightSparks = Base:WaitForChild("FrontRightSparks")

	self._sparks = {
		{
			Prismatic = Prismatics:WaitForChild("FrontLeftCastor"),
			Check = function(pos)
				return pos > -0.85
			end,
			Sparks = FrontLeftSparks:WaitForChild("Sparks"),
			Streaks = FrontLeftSparks:WaitForChild("Streaks"),
		},
		{
			Prismatic = Prismatics:WaitForChild("FrontRightCastor"),
			Check = function(pos)
				return pos < 0.85
			end,
			Sparks = FrontRightSparks:WaitForChild("Sparks"),
			Streaks = FrontRightSparks:WaitForChild("Streaks"),
		},
	}

	return self
end

function ParticleEffectsController.updateSparks(
	self: ControllersTypes.ParticleEffectsController,
	velocity: number,
	override: boolean
)
	local screeching = false
	if velocity > 8 or override then
		for _, sparks in self._sparks do
			local enabled = sparks.Check(sparks.Prismatic.CurrentPosition) or override
			sparks.Sparks.Enabled = enabled
			sparks.Streaks.Enabled = enabled
			screeching = screeching or enabled
		end
	else
		for _, sparks in self._sparks do
			sparks.Sparks.Enabled = false
			sparks.Streaks.Enabled = false
		end
	end
	return screeching
end

return ParticleEffectsController
