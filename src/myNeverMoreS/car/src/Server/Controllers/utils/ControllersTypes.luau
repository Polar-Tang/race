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

-- INIT SHIT --
export type suspension = {
	frontSuspensionLength: number,
	frontSuspensionStiffness: number,
	frontSuspensionDamping: number,
	rearSuspensionLength: number,
	rearSuspensionStiffness: number,
	rearSuspensionDamping: number,
	frontCamber: number,
	rearCamber: number,
}

export type antiRoll = {
	frontAntiRollBarDamping: number,
	frontAntiRollBarStiffness: number,
	rearAntiRollBarStiffness: number,
	rearAntiRollBarDamping: number,
}

export type steering = {
	steeringRackLength: number,
	steeringRackResponsiveness: number,
	steeringRackSpeed: number,
	steeringRackMaxForce: number,
}

export type redress = {
	redressMaxTorque: number,
	redressResponsiveness: number,
}

export type CarConfig = {
	suspension: suspension,
	antiRoll: antiRoll,
	steering: steering,
	redress: redress,
}

export type parentType = "suspension" | "antiRoll" | "steering" | "redress"

export type ConstraintUpdater = ControllerBase & {
	_steering: Folder,
	_suspension: Folder,
	_antiRoll: Folder,
	_redress: Folder,
	config: CarConfig,

	_updateSuspension: (ConstraintUpdater) -> (),
	_updateAntiRoll: (ConstraintUpdater) -> (),
	_updateRedress: (ConstraintUpdater) -> (),
	_updateSteering: (ConstraintUpdater) -> (),
	_ensureAtt: (self: ConstraintUpdater, attName: string, parent: parentType) -> number,
	_initFolder: (self: ConstraintUpdater) -> (),
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
