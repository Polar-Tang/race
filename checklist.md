[-] RedressOrientation <AlignOrientation>
    (oneAttachment mode)
    Attachment0 = chassis.Flipper
[.] SteeringRack.SteeringRack <PrismaticConstraint>
    Attachment0 = Chassis.SteerAtt
    Attachment1 = SteeringRack.SteerAtt
[-] Suspension.SuspensionSUFFIX <SpringConstraint>
    Attachment0 = wheelMountSUffix.Mount.SpringAtt
    Attachment1 = wheelMountSUffix.Wheel.SpringAtt
[-] Engine.WheelSuffixMotor <CylindricalConstraint>
    Attachment0 = if suffix.startWith("f") WheelSuffix.Knuckle.MotorAtt else WheelSuffix.Mount.MotorAtt
    Attachment1 = Wheels.WheelSuffix.Wheel
[-] Wheels.Knuckle.HingeConstraint <HingeConstraint>
     Knuckle is holding the wheel hub and it rotated on Y by the steering rack, it allows wheels to rotate on Y axis while the wheel hub keeps spinning the wheels, that's why there are knuckles in the FR and FL wheel, they needs to steer and the hinge contraint is perfect for this task
    Attachment0 =  Wheels.Mount.HingeAtt
    Attachment1 = Wheels.Knuckle.HingeAtt
[-] SteringRack.RodConstraint <RodConstraint>
    Attachment0 = SteringRack[left or Right]RodAttachment
    Attachment1 = wheel[left or Right].Knuckle.SteeringAttachment
[-] Antirrol[F or R].HingeConstraint <HingeConstraint>
    Attachment0 = chassis.AntiRollAttachment
    Attachment1 = Antirrol[F or R].AntiRollAttachment
[-] Antiroll.AntirollSufix <SpringAttachment>
    Attachment0 = Antirrol[F or R].[left or right]SpringAttachment
    Attachment1 = wheelSufix.Wheel.MotorAtachment

- SteeringRack


OtherQuestions:
Engine.WheelSuffixMotor is basically where the max torque is fully applied and it rotates the wheel which moves the car by the friction, this rotattes all along the X axis. Engine.WheelSuffixMotor is a prismatic constraint, what is the prismatic constraint and why is necesary to recreate this phisics mechanic?