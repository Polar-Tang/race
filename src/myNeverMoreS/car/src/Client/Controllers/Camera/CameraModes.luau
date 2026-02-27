
function getCameraModes(chassis)
	
	local CameraModes = {
	{
		module = "ChaseCamera",
		parameters = {
			height = 7,
			distance = 15,
		},
	},
	{
		module = "ChaseCamera",
		parameters = {
			height = 9,
			distance = 25,
		},
	},
	{
		module = "InteriorCamera",
		parameters = {
			attachment = chassis.InteriorCameraAttachment,
			forwardHeadTurnAngle = math.rad(20),
			reverseHeadTurnAngle = -math.rad(140),
		},
	},
	{
		module = "FixedCamera",
		parameters = {
			attachment = chassis.HoodCameraAttachment,
		},
	},
}
return CameraModes
end


return getCameraModes
