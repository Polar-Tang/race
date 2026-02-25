local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Maid = require(ReplicatedStorage.Nevermore.Quenty.maid.Shared.Maid)
export type ControllConstructor = {
	cart: Model,
}

export type baseData = {
	_maid: Maid.Maid,
	car: Model,
	chassis: BasePart,
	inputs: Configuration,
	driverSeat: Seat,
	engine: Folder,
}

export type ControllerBase = baseData & {
	-- ===== Attack-specific state =====

	-- ===== Overridden / new methods =====
	new: (constructor: ControllConstructor) -> { self: ControllerBase },
	Destroy: () -> (),
	Start: (ControllerBase) -> (),
}

---== OcuppantController ==---
export type OccupantController = ControllerBase & {
	_owner: Player?,
	_drivePrompt: ProximityPrompt,

	Enter: (OccupantController, Model) -> (),
	_onOccupantChanged: (OccupantController) -> (),
	_onDrivePromptTriggered: (OccupantController, Player) -> (),
	UpdateOwner: (OccupantController) -> (),
}

---== ConstraintUpdater ==---
export type ConstraintUpdater = ControllerBase & {
	_steering: Folder,
	_suspension: Folder,
	_antiRoll: Folder,
	_redress: Folder,

	_updateSuspension: (ConstraintUpdater) -> (),
	_updateAntiRoll: (ConstraintUpdater) -> (),
	_updateRedress: (ConstraintUpdater) -> (),
	_updateSteering: (ConstraintUpdater) -> (),
}

---== Redresser ==---
export type Redresser = ControllerBase & {

	_redress: Folder,
	_redressOrientation: AlignOrientation,
	_timeFlipped: number,
	_redressParameters: { [string]: number },

	_isFlipped: (Redresser) -> boolean,
	_isUpright: (Redresser) -> boolean,
	_isMoving: (Redresser) -> boolean,
	_redressAsync: (Redresser) -> (),
}

---== Replication ==---
export type Replication = ControllerBase & {

	_getDrivingPlayer: (Replication) -> Player?,
	_onOccupantChanged: (Replication) -> Player?,
	OnSetNitroEnabledEvent: (Replication, Player, boolean) -> Player?,
}

return {}
