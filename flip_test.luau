local car = workspace:FindFirstChild("Fletcher Thunderbolt")
local ch = car.Chassis
local ao = car.Redress.RedressOrientation
local out = {}
table.insert(out, "MaxTorque now: " .. ao.MaxTorque .. " Resp: " .. ao.Responsiveness)
table.insert(out, "before flip, up dot Y: " .. string.format("%.2f", ch.CFrame.UpVector:Dot(Vector3.yAxis)))
-- flip the car upside down, 6 studs up so it lands on its roof
local pivot = car:GetPivot()
car:PivotTo(CFrame.new(pivot.Position + Vector3.new(0, 6, 0)) * CFrame.Angles(0, 0, math.pi))
task.wait(1)
table.insert(out, "after flip, up dot Y: " .. string.format("%.2f", ch.CFrame.UpVector:Dot(Vector3.yAxis)))
return table.concat(out, "\n")
