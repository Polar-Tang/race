local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginalCart = game.ReplicatedStorage.Cart

local o_chasis = OriginalCart.Chassis

local wheel_suffix = {
	"FL",
	"FR",
	-- "RL",
	-- "RR",
}
local copy = workspace.CartInitialized

for _, suffic in ipairs(wheel_suffix) do
	-- local wheel_model = OriginalCart.Wheels:FindFirstChild("Wheel" .. suffic)
	-- local o_wheel = wheel_model.Wheel

	-- local distance = o_wheel.Position - o_chasis.Position

	local c_wheel_model = copy.Wheels:FindFirstChild("Wheel" .. suffic)
	local c_wheel = c_wheel_model.Wheel
	local center = c_wheel.CFrame.Position
	print("center of " .. c_wheel_model.Name .. " wheel ", center)
end

local gptResult = Vector3.new(-513.479, 5.8, -227.423)
	+ Vector3.new(-511.49591064453125, 6.401949882507324, -229.86300659179688)

--0.185, -1.882, -0.375
---14.997, -0.001, 0
--1, 0, 0
--0, 0.966, -0.259
