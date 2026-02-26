local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Maid = require(ReplicatedStorage.Nevermore.Quenty.loader.Maid)

export type ControllConstructor = {
	car: Model,
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

---== FX ==---
export type FX = baseData & {
	_totalSpeedChange: number,
	_lastSpeed: number,
	_lastCollisionUpdate: number,

	-- ===== Overridden / new methods =====
	new: (ControllConstructor) -> (),
	Init: (FX) -> (),

	_onFXChanged: (FX) -> (),
	_onNitroEnabledChanged: (FX) -> (),
	_onHeartbeat: (FX, _deltaTime: number) -> (),
}

---== Audio ==---
export type Audio = baseData & {
	_audioPlayers: Folder,
	_engineStartup: AudioPlayer,
	_engineShutdown: AudioPlayer,
	_engineLoop: AudioPlayer,
	_tiresLoop: AudioPlayer,
	_tiresSlidingLoop: AudioPlayer,
	_nitroStart: AudioPlayer,
	_nitroStop: AudioPlayer,
	_nitroLoop: AudioPlayer,
	_suspension: { AudioPlayer },
	_collision: { AudioPlayer },

	_engineRunning: boolean,
	_nitroEnabled: boolean,

	_totalSuspensionChange: number,
	_lastSuspensionLength: number,
	_lastSuspensionUpdate: number,

	-- ===== Overridden / new methods =====
	new: (ControllConstructor) -> (),
	Init: (Audio) -> (),

	_onFXChanged: (Audio) -> (),
	_onNitroEnabledChanged: (Audio) -> (),
	_onHeartbeat: (Audio, _deltaTime: number) -> (),
	_updateSuspensionSounds: (self: Audio) -> (),
	StartNitro: (self: Audio) -> (),
	StopNitro: (self: Audio) -> (),
	StartupEngine: (self: Audio) -> (),
	ShutdownEngine: (self: Audio) -> (),
	PlayCollisionSound: (self: Audio, volume: number) -> (),
}
return {}
