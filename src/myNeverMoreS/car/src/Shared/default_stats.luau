local default_stats = {
	suspension = {
		frontSuspensionLength = 0,
		frontSuspensionStiffness = 0,
		frontSuspensionDamping = 0,
		rearSuspensionLength = 0,
		rearSuspensionStiffness = 0,
		rearSuspensionDamping = 0,
		frontCamber = 0,
		rearCamber = 0,
	},
	antiRoll = {
		frontAntiRollBarDamping = 0,
		frontAntiRollBarStiffness = 0,
		rearAntiRollBarStiffness = 0,
		rearAntiRollBarDamping = 0,
	},
	steering = {
		steeringRackLength = 0,
		steeringRackResponsiveness = 0,
		steeringRackSpeed = 0,
		steeringRackMaxForce = 0,
	},
	redress = {
		maxTimeFlipped = 2,
		redressMaxTorque = 500000,
		redressResponsiveness = 10,
	},
	enginge = {
		forwardMaxSpeed = 0,
		reverseMaxSpeed = 0,
		acceleration = 0,
		deceleration = 0,
		braking = 0,
		engineSpeedCorrection = 0,
		minSpeedTorque = 0,
		maxSpeedTorque = 0,
		handBrakeTorque = 0,
		nitroTorque = 0,
		nitroTime = 0,
		nitroRechargeTime = 0,
		nitroMaxSpeed = 0,
		nitroAcceleration = 0,
	},
}

return default_stats
