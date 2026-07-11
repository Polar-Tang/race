local out = {}
local function add(...)
	local parts = {}
	for _, v in ipairs({ ... }) do
		table.insert(parts, tostring(v))
	end
	table.insert(out, table.concat(parts, " "))
end

-- find candidate car models in workspace and ServerStorage
local candidates = {}
for _, root in ipairs({ workspace, game:GetService("ServerStorage") }) do
	for _, inst in ipairs(root:GetChildren()) do
		if inst:IsA("Model") and inst:FindFirstChild("Chassis") then
			table.insert(candidates, inst)
		end
	end
end

for _, car in ipairs(candidates) do
	add("=== ", car:GetFullName(), " ===")
	local ch = car:FindFirstChild("Chassis")
	add("Chassis mass:", ch.AssemblyMass, "anchored:", ch.Anchored, "root:", ch.AssemblyRootPart and ch.AssemblyRootPart.Name)
	add("up dot Y:", string.format("%.3f", ch.CFrame.UpVector:Dot(Vector3.yAxis)))

	local att = ch:FindFirstChild("FlipperAttachment")
	if att then
		add("FlipperAttachment Orientation:", att.Orientation, "| Position:", att.Position)
	else
		add("NO FlipperAttachment on chassis")
	end

	local redress = car:FindFirstChild("Redress")
	if redress then
		for k, v in pairs(redress:GetAttributes()) do
			add("Redress attr:", k, "=", v)
		end
		local ao = redress:FindFirstChild("RedressOrientation")
		if ao then
			add("AO Enabled:", ao.Enabled, "MaxTorque:", ao.MaxTorque, "Resp:", ao.Responsiveness,
				"Rigidity:", ao.RigidityEnabled, "Mode:", ao.Mode.Name, "AlignType:", ao.AlignType.Name)
			add("AO Attachment0:", ao.Attachment0 and ao.Attachment0:GetFullName() or "NIL")
			local cf = ao.CFrame
			add("AO target CFrame:", cf, "| isNaN:", cf.Position.X ~= cf.Position.X or cf.LookVector.X ~= cf.LookVector.X)
		else
			add("NO RedressOrientation in Redress folder")
		end
	else
		add("NO Redress folder")
	end
	add("torque to roll ~= mass*g*halfwidth:", string.format("%.0f", ch.AssemblyMass * workspace.Gravity * (ch.Size.X / 2)),
		"(chassis size:", ch.Size, ")")
end

return table.concat(out, "\n")
