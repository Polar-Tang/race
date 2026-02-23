--!strict

local PhysicsService = game:GetService("PhysicsService")

local RAILS = "Rails"
local CASTORS = "Castors"

return function()
	if not PhysicsService:IsCollisionGroupRegistered(RAILS) then
		PhysicsService:RegisterCollisionGroup(RAILS)
	end
	if not PhysicsService:IsCollisionGroupRegistered(CASTORS) then
		PhysicsService:RegisterCollisionGroup(CASTORS)
	end
	PhysicsService:CollisionGroupSetCollidable(RAILS, CASTORS, true)
	PhysicsService:CollisionGroupSetCollidable(CASTORS, "Default", false)
end
