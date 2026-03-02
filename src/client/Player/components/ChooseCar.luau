local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Maid = require(ReplicatedStorage.Nevermore.Quenty.maid.Shared.Maid)

local chooseCarEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ChooseCar")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local currentGui

local maid: Maid.Maid = Maid.new()

chooseCarEvent.OnClientEvent:Connect(function(data)
	-- Destroy any existing UI
	if currentGui then
		currentGui:Destroy()
		currentGui = nil
	end

	-- ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ChooseCarGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	-- Main Frame
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 420, 0, 320)
	frame.Position = UDim2.new(0.5, -210, 0.5, -160)
	frame.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "Choose a Vehicle"
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Parent = frame

	-- ImageLabel (centered, ~30% height)
	local image = Instance.new("ImageLabel")
	image.Size = UDim2.new(0.8, 0, 0.3, 0)
	image.Position = UDim2.new(0.1, 0, 0.18, 0)
	image.BackgroundTransparency = 1
	image.Image = "" -- placeholder, set an asset id if desired
	image.ScaleType = Enum.ScaleType.Fit
	image.Parent = frame

	-- Description below image
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, 0, 0, 40)
	desc.Position = UDim2.new(0, 0, 0.55, 0)
	desc.BackgroundTransparency = 1
	desc.Text = "Select Car or Cart to spawn at the kiosk."
	desc.TextWrapped = true
	desc.TextScaled = true
	desc.TextColor3 = Color3.fromRGB(200, 200, 200)
	desc.Parent = frame

	-- Car Button (left)
	local carButton = Instance.new("TextButton")
	carButton.Size = UDim2.new(0.45, 0, 0, 48)
	carButton.Position = UDim2.new(0.05, 0, 0.75, 0)
	carButton.Text = "Car"
	carButton.TextScaled = true
	carButton.BackgroundColor3 = Color3.fromRGB(46, 134, 193)
	carButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	carButton.Parent = frame

	-- Cart Button (right)
	local cartButton = Instance.new("TextButton")
	cartButton.Size = UDim2.new(0.45, 0, 0, 48)
	cartButton.Position = UDim2.new(0.5, 0, 0.75, 0)
	cartButton.Text = "Cart"
	cartButton.TextScaled = true
	cartButton.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
	cartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	cartButton.Parent = frame

	local function sendChoice(choice)
		local payload = { choiceName = choice, obj = data.obj }
		if data and data.spawnLocation then
			payload.spawnLocation = data.spawnLocation
		end
		-- Fire back to server with the chosen option
		chooseCarEvent:FireServer(payload)
		-- Clean up UI
		if screenGui then
			screenGui:Destroy()
			currentGui = nil
		end
	end

	maid:GiveTask(carButton.Activated:Connect(function()
		sendChoice("Car")
	end))
	maid:GiveTask(cartButton.Activated:Connect(function()
		sendChoice("Cart")
	end))

	currentGui = screenGui
end)

return {}
