--[[
PRELOAD ALL
--]]
local PLayer = game:GetService("Players")
local plr = PLayer.LocalPlayer
repeat plr.CharacterAdded:Wait() until plr.Character ~= nil

local hum = script.Parent:WaitForChild("Humanoid")
local RS = game:GetService('ReplicatedStorage')
local CP = game:GetService("ContentProvider")



for _, v in ipairs(RS:WaitForChild("Animations"):GetDescendants()) do
	if v:IsA("Animation") then
		--print("animation id ", v.animationId, v.Parent.Parent.Parent, "/ ", v.Parent.Parent, "/ ", v.Parent, "/", v.Name )

		hum.Animator:LoadAnimation(v)
	end
end

CP:PreloadAsync(game:GetDescendants())
