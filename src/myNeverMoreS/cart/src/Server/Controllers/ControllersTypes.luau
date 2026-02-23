export type ControllConstructor = {
	cart: Model,
	seat: Seat,
}

export type ControllerBase = {
	-- ===== Attack-specific state =====
	cart: Model,
	_maid: any,
	_root: BasePart,
	_seat: Seat,

	-- ===== Overridden / new methods =====
	new: (constructor: ControllConstructor) -> { self: ControllerBase },
	Destroy: () -> (),
}

---== ParticleEffectsController ==---

export type SparkEntry = {
	Prismatic: PrismaticConstraint,
	Check: (pos: number) -> boolean,
	Sparks: ParticleEmitter,
	Streaks: Trail,
}

export type Sparks = { SparkEntry }

export type ParticleEffectsController = ControllerBase & {
	_sparks: Sparks,
	updateSparks: (self: ParticleEffectsController, velocity: number, override: boolean) -> boolean,
}

export type SoundEffectsController = ControllerBase & {
	_sparks: Sparks,

	_screech: Sound,
	_kachunk: { Sound },
	_breakSound: Sound,

	_screechFrac: number,
	_screechTimeLeft: number,

	_kachunkDistance: number,
	_whichKachunk: number,

	updateSparks: (self: ParticleEffectsController, velocity: number, override: boolean) -> boolean,

	playSounds: (self: SoundEffectsController, dt: number, velocity: number, screeching: boolean) -> (),
	stopSounds: (self: SoundEffectsController) -> (),
	movedBy: (self: SoundEffectsController, number) -> (),
	playSound: (self: SoundEffectsController, soundName: string) -> (),
}

export type ThrottleController = ControllerBase & {
	Throttle: IntValue,

	SetThrottle: (ThrottleController, number) -> (),
}

export type StatusController = ControllerBase & {
	CurrentPlayer: Player?,

	occupantIsPlayer: (self: StatusController, player: Player) -> boolean,
	setUp: (self: StatusController, player: Player) -> (),
	isSeatAvaible: (self: StatusController) -> boolean,
	init: (self: StatusController) -> (),
	vacate: (self: StatusController) -> (),
	occupantIsPlayerOrNone: (self: StatusController) -> boolean,
}
return {}
