local ClientTypes = require(script.Parent.Parent.utils.ClientTypes)
export type ControllConstructor = ClientTypes.ControllConstructor

export type baseData = ClientTypes.baseData

export type ControllerBase = ClientTypes.ControllerBase


---== Audio ==---
export type Audio = ControllerBase & {
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

---== Haptics ==---
export type Haptics = ControllerBase & {
	_enabled: boolean,

	_hapticEffects: Folder,
	_collisionHaptic: HapticEffect,
	_nitroHaptic: HapticEffect,

	PlayCollisionHaptic: (self: Haptics, strength: number) -> (),
	StartNitro: (self: Haptics) -> (),
	StopNitro: (self: Haptics) -> (),
	InitCustomHapticEffect: (hapticEffect: HapticEffect) -> (),
	Enable: (self: Haptics) -> (),
	Disable: (self: Haptics) -> (),
	Init: (self: Haptics) -> (),
}

---== Particles ==---
export type Particles = ControllerBase & {
	_nitroEnabled: boolean,

	_rightNitroEmitterAttachment: Attachment,
	_leftNitroEmitterAttachment: Attachment,

	StartNitro: (Particles) -> (),
	StopNitro: (Particles) -> (),
}

export type FXControllers = {
	Audio : Audio,
	Haptics : Haptics,
	Particles: Particles,
}

---== FX ==---
export type FX = ClientTypes.BaseService<FXControllers> & {
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


return {}
