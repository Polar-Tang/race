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
	wheels_parametes: any,
}

export type parentType = "suspension" | "antiRoll" | "steering" | "redress" | "engine" | "wheels_parametes"

export type ConstraintUpdater = ControllerBase & {
	_steering: Folder,
	_suspension: Folder,
	_antiRoll: Folder,
	_redress: Folder,
	_carInitializer: CarInitializer,
	_updateSuspension: (ConstraintUpdater) -> (),
	_updateAntiRoll: (ConstraintUpdater) -> (),
	_updateRedress: (ConstraintUpdater) -> (),
	_updateSteering: (ConstraintUpdater) -> (),
	_ensureAtt: (self: ConstraintUpdater, attName: string, parent: parentType) -> number,
	_initFolder: (self: ConstraintUpdater) -> (),
}

export type properties = {
	ClassName: string?,
	CFrame: CFrame?,
}

export type CarInitializer = ControllerBase & {
	_steering: Folder,
	_suspension: Folder,
	_antiRoll: Folder,
	_redress: Folder,
	_Wheels: Folder,
	config: CarConfig,

	_createAttachment: (Parent: BasePart | Model, Name: string, properties: properties) -> Attachment,
	_ensureAtt: (self: CarInitializer, attName: string, parent: parentType) -> number,
	_ensureSpringConstraing: (self: CarInitializer, sufix: string) -> (),
	_initSteering: (self: CarInitializer) -> (),
	_initFolder: (self: CarInitializer) -> (),
	Init: (self: CarInitializer) -> (),
	ChangeChildren: (
		self: CarInitializer,
		parent: Instance,
		childName: string,
		properties?
	) -> BasePart | Attachment | Model,
	_initSuspension: (self: CarInitializer) -> any,
	_createInstance: (Parent: BasePart | Model, Name: string, properties) -> Instance,
	_ensureAntiroll: (self: CarInitializer, sufix: string) -> Instance,
	_initAntiRoll: (self: CarInitializer) -> antiRoll,
	_initializeEngineAtt: (self: CarInitializer) -> (),
	_ensureSteeringRack: (self: CarInitializer) -> (),
	_ensureKnuckle: (self: CarInitializer, sufix: string) -> (),
	_ensureAntirollbar: (self: CarInitializer, sufix: string) -> Instance,
	_ensureMotor: (self: CarInitializer, sufix: string) -> (),
	_ensureChasisShit: (self: CarInitializer) -> (),
	_initRedress: (self: CarInitializer) -> redress,
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
