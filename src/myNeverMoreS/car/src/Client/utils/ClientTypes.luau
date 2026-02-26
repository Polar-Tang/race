local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Maid = require(ReplicatedStorage.Nevermore.Quenty.loader.Maid)
export type BaseService<TControllers>  = ControllerBase & {
	-- ===== Attack-specific state =====
	_controllers : TControllers,

	-- ===== Overridden / new methods =====
	new: (constructor: ControllConstructor) -> { self: ControllerBase },
    _initControllers: (constructor: ControllConstructor, Folder) -> (),
	Destroy: () -> (),
	Start: (ControllerBase) -> (),
}

export type ControllConstructor = {
    car: Model
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



return {}