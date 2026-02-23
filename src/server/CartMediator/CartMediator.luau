

game.ReplicatedStorage.RemoteEvents.SetThrottle.OnServerEvent:Connect(function(player: Player, throttle)
    local BinderProviderInitialized = _G.ServiceBag:GetService(_G.BinderProvider)
	local WeaponBinderStarted = BinderProviderInitialized:Get("Armed") -- here's the character strategy context
	-- local weapon = WeaponBinderStarted:Get(player_char)
end