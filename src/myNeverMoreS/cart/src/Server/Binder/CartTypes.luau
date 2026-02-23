local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControllersTypes = require(ReplicatedStorage.Nevermore.Custom.cart.src.Server.Controllers.ControllersTypes)
local Maid = require(ReplicatedStorage.Nevermore.Quenty.maid.Shared.Maid)

export type controllerName =
	"statusController"
	| "particleEffectsController"
	| "soundEffectsController"
	| "throttleController"

export type CartDriver = {
	_cart: Model,
	_base: BasePart,
	_hinges: { Instance },
	_springs: { Instance },
	_driver: Instance,
	_seat: Seat,

	_maid: typeof(Maid.new()),

	new: (cart: Model, serviceBag: any) -> { self: ControllerBase },
	update: (self: CartDriver, throttle: number) -> (),
	getController: (self: CartDriver, controllerName: controllerName) -> any,

	_particleEffectsController: ControllersTypes.ParticleEffectsController,
	_soundEffectsController: ControllersTypes.SoundEffectsController,
	_throttleController: ControllersTypes.ThrottleController,
	_statusController: ControllersTypes.StatusController,
	getStatus: (self: CartDriver, respawnAfter: number) -> (boolean, boolean),
	breakCart: (self: CartDriver) -> (),

	controllers: any,
}

return {}
