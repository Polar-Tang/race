local ClientTypes = require(script.Parent.Parent.utils.ClientTypes)

--== BASE ==--
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
	Audio: Audio,
	Haptics: Haptics,
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

---== Speedometer ==---
export type Speedometer = ControllerBase & {
	_enabled: boolean,
	_gui: ScreenGui?,
	_heartbeatConnection: RBXScriptConnection?,

	_update: (self: Speedometer) -> (),
	Enable: (self: Speedometer) -> (),
	Disable: (self: Speedometer) -> (),
}

---== CAMERA SERVICE ==---

export type CameraClass = ControllerBase & {
	_cycleCameraModeConnection: RBXScriptConnection?,
	_currentCameraModeIndex: number,
	_enabled: boolean,

	_cameraModules: any, -- The camera modules that i don't want to type

	_currentModeInfo: any,
	_cameraMode: any,

	SetMode: (self: CameraClass, modeIndex: number) -> (),
	CycleCameraMode: (self: CameraClass) -> (),
	Enable: (self: CameraClass) -> (),
	Disable: (self: CameraClass) -> (),
}

---== CameraControllerBase ==---
export type CameraControllerBase<Tparametes> = ControllerBase & {
	_enabled: boolean,
	_parameters: Tparametes,

	_update: (self: CameraControllerBase<Tparametes>, deltaTime: number) -> (),
	SetParameters: (self: CameraControllerBase<Tparametes>, newParameters: Tparametes) -> (),
	Enable: (self: CameraControllerBase<Tparametes>) -> (),
	Disable: (self: CameraControllerBase<Tparametes>) -> (),
}

---== InteriorCamera ==---
export type InteriorCameraParams = {
	attachment: Attachment,
	forwardHeadTurnAngle: number,
	reverseHeadTurnAngle: number,
}

export type InteriorCamera = CameraControllerBase<InteriorCameraParams> & {
	_forwardVector: Vector3,
	_upVector: Vector3,
	_headTurnAngle: number,

	_initializeValues: (self: InteriorCamera) -> (),
}

---== FixedCamera ==---
type fixedCameraParameters = {
	attachment: Attachment,
}

export type FixedCamera = CameraControllerBase<fixedCameraParameters>

---== ChaseCamera ==---
export type ChaseCameraParams = {
	height: number,
	distance: number,
}

export type ChaseCamera = CameraControllerBase<ChaseCameraParams> & {
	_gimbalCFrame: CFrame,
	_relativeCameraCFrame: CFrame,
	_trailingOffset: Vector3,
	_lookAhead: Vector3,
	_isManualControl: boolean,
	_lastManualControl: number,
	_pitch: number,
	_yaw: number,
	_lastInputCategoryChangedConnection: RBXScriptConnection,
	_currentInputCategory: EnumItem,
	_enabled: boolean,

	_gimbalSpeed: number,

	_onLastInputCategoryChanged: (self: ChaseCamera, string) -> (),
	_initializeValues: (self: ChaseCamera) -> (),
}

---== INPUT ==---
export type TouchInput = ClientTypes.ControllerBase & {

	_enabled: boolean,
	_gui: ScreenGui?,
	_throttleAmount: number,
	_brakeAmount: number,
	_steeringTouchInputObject: InputObject?,
	_gasPedalInputObject: InputObject?,
	_brakePedalInputObject: InputObject?,
	_nitroInputObject: InputObject?,
	_handBrakeInputObject: InputObject?,

	_onInputEnded: (self: TouchInput, InputObject) -> (),
	_onGasPedalInputBegan: (self: TouchInput, inputObject: InputObject) -> (),
	_onBrakePedalInputBegan: (self: TouchInput, inputObject: InputObject) -> (),
	_onWheelInputBegan: (self: TouchInput, inputObject: InputObject) -> (),
	_onNitroButtonInputBegan: (self: TouchInput, inputObject: InputObject) -> (),
	_onHandBrakeInputBegan: (self: TouchInput, inputObject: InputObject) -> (),
	_onExitButtonInputBegan: (self: TouchInput, inputObject: InputObject) -> (),
	_onCycleCameraModeButtonInputBegan: (self: TouchInput, inputObject: InputObject) -> (),
	_updateScale: (self: TouchInput) -> (),
	GetThrottleAndSteering: (self: TouchInput) -> (number, number),
	Enable: (self: TouchInput) -> (number, number),
	Disable: (self: TouchInput) -> (number, number),
}

---== GamePad ==---
export type Gamepad = ClientTypes.ControllerBase & {
	_currentGamepad: EnumItem,
	_enabled: boolean,
	_lastInputTypeChangedConnection: RBXScriptConnection?,
	_controlsGui: Folder?,

	GetThrottleAndSteering: (self: Gamepad) -> (number, number),
	Enable: (self: Gamepad) -> (),
	Disable: (self: Gamepad) -> (),
}

---== KeyboardAndMouse ==---
export type KeyboardAndMouse = ClientTypes.ControllerBase & {
	_currentGamepad: EnumItem,
	_enabled: boolean,
	_lastInputTypeChangedConnection: RBXScriptConnection,
	_controlsGui: ScreenGui?,

	new: (config: ControllConstructor) -> (),
	GetThrottleAndSteering: (self: KeyboardAndMouse) -> (),
	Enable: (self: KeyboardAndMouse) -> (),
	Disable: (self: KeyboardAndMouse) -> (),
}

---== KeyboardService ==---
export type ClassInput = ClientTypes.ControllerBase & {
	_currentInputCategory: string,
	_enabled: boolean,
	_controllers: any,

	_onLastInputCategoryChanged: (self: ClassInput, string) -> (),
	_update: (self: ClassInput) -> (),
	Enable: (self: ClassInput) -> (),
	Disable: (self: ClassInput) -> (),
}

---== DRIVER CLIENT ==---
export type DriverController = ClientTypes.ControllerBase & {
	inputs: Folder,
	engine: Folder,
	steering: Folder,
	wheels: Folder,
	_steeringRack: PrismaticConstraint,
	_wheelRadius: number,

	_wheelParts: { Model },
	_engineParameters: { [string]: number },
	_steeringParameters: { [string]: number },
	_wheelParameters: { [string]: number },

	getChassisForwardSpeed: (self: DriverController) -> number,
	updateNitro: (self: DriverController, deltaTime: number) -> (),
	updateEngine: (self: DriverController, deltaTime: number) -> (),
	updateSteering: (self: DriverController) -> (),
	updateWheelFriction: (self: DriverController) -> (),
	initialize: (self: DriverController) -> (),
	reset: (self: DriverController) -> (),
	update: (self: DriverController, deltaTime: number) -> (),

	_ensureAtt: (self: DriverController, attName: string) -> number,
	_initializeEngineAtt: (self: DriverController) -> (),
	Init: (self: DriverController) -> (),
}
---== CAR CLIENT ==---

export type CarControllers = {
	CameraClass: CameraClass,
	ClassInput: ClassInput,
	Speedometer: Speedometer,
	FX: FX,
}

export type CarClient = ClientTypes.BaseService<CarControllers> & {
	_totalSpeedChange: number,
	_lastSpeed: number,
	_lastCollisionUpdate: number,
	_driverSeat: Seat,
	_engine: Folder,
	_animations: Folder,
	_driveAnimation: Animation,
	_isControlling: boolean,
	_driveAnimationTrack: AnimationTrack?,

	_DriverController: DriverController,

	StartControlling: (self: CarClient) -> (),
	StopControlling: (self: CarClient) -> (),
	OnOccupantChanged: (self: CarClient) -> (),
	SetupDestructionHandler: (self: CarClient) -> (),
}

return {}
