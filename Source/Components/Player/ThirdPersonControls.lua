-- ThirdPersonControls.lua
ThirdPersonControls = {
    freelookstarted = false,
    freelookmousepos = Vec3(0),
    freelookrotation = Vec3(0),
    lookchange = Vec2(0),
    camera = nil,
    currentcameraposition = Vec3(0),
    eyeheight = 1.7,
    smoothcameradistance = 0,
    croucheyeheight = 1.0,
    followdistance = 2.0,
    mousesmoothing = 0.0,
    mouselookspeed = 1.0,
    cameraradius = 0.1,
    movespeed = 1.2,
    runspeed = 4.8,
    jumpforce = 8.0,
    jumplunge = 1.5,
    modelangle = 0,
    name = "ThirdPersonControls"
}

function ThirdPersonControls:Start()
    self.smoothcameradistance = self.followdistance
    self.entity:SetPhysicsMode(PHYSICS_PLAYER)
    if self.entity:GetMass() == 0.0 then
        self.entity:SetMass(78)
    end
    self.entity:SetCollisionType(COLLISION_PLAYER)
    self.camera = CreateCamera(self.entity:GetWorld())
    self.camera:SetPosition(0, self.eyeheight, 0)
    self.camera:SetRotation(0, 0, 0)
    self.camera:SetFov(70)
    self.currentcameraposition = self.camera:GetPosition(true)
    self.freelookrotation = self.entity:GetRotation(true)
end

function ThirdPersonControls:Update()
    local movement = Vec3(0)
    local jump = 0
    local crouch = false
    local window = ActiveWindow()
    local airborne = self.entity:GetAirborne()
    local shiftkey = false

    if window then
        shiftkey = window:KeyDown(KEY_SHIFT)

        if not self.freelookstarted then
            self.freelookstarted = true
            self.freelookrotation = self.entity:GetRotation(true)
            self.freelookmousepos = window:GetMouseAxis()
        end

        local newmousepos = window:GetMouseAxis()
        self.lookchange.x = self.lookchange.x * self.mousesmoothing + (newmousepos.y - self.freelookmousepos.y) * 100.0 * self.mouselookspeed * (1.0 - self.mousesmoothing)
        self.lookchange.y = self.lookchange.y * self.mousesmoothing + (newmousepos.x - self.freelookmousepos.x) * 100.0 * self.mouselookspeed * (1.0 - self.mousesmoothing)

        if math.abs(self.lookchange.x) < 0.001 then
            self.lookchange.x = 0.0
        end

        if math.abs(self.lookchange.y) < 0.001 then
            self.lookchange.y = 0.0
        end

        if self.lookchange.x ~= 0.0 or self.lookchange.y ~= 0.0 then
            self.freelookrotation.x = self.freelookrotation.x + self.lookchange.x
            self.freelookrotation.y = self.freelookrotation.y + self.lookchange.y
            self.camera:SetRotation(self.freelookrotation, true)
        end

        self.freelookmousepos = newmousepos
        local speed = self.movespeed

        if airborne then
            speed = speed * 0.25
        else
            if shiftkey then
                speed = self.runspeed
            end

            if window:KeyHit(KEY_SPACE) then
                jump = self.jumpforce
            end
        end

        if window:KeyDown(KEY_D) then
            movement.x = speed
        end

        if window:KeyDown(KEY_A) then
            movement.x = -speed
        end

        if window:KeyDown(KEY_W) then
            movement.z = speed
        end

        if window:KeyDown(KEY_S) then
            movement.z = -speed
        end

        if movement.x ~= 0.0 and movement.z ~= 0.0 then
            movement = movement * 0.707
        end

        if jump ~= 0.0 then
            movement.x = movement.x * self.jumplunge
            if movement.z > 0.0 then
                movement.z = movement.z * self.jumplunge
            end
        end

        crouch = window:KeyDown(KEY_CONTROL)
    end

    self.entity:SetInput(self.camera.rotation.y, movement.z, movement.x, jump, crouch)
    self.entity:SetRotation(0, self.camera.rotation.y + self.modelangle, 0)

    local eye = self.eyeheight
    local y = self.currentcameraposition.y - self.entity:GetPosition(true).y
    local h = eye

    if y < eye then
        h = Mix(y, eye, 0.5)
    end

    self.currentcameraposition = self.entity:GetPosition(true) + Vec3(0, h, 0)
    self.camera:SetPosition(self.currentcameraposition, true)

    local campos = TransformPoint(0, 0, -self.followdistance, self.camera, nil)
    local world = self.entity:GetWorld()

    if world then
        local temp = self.entity:GetPickMode()
        self.entity:SetPickMode(PICK_NONE)
        local pickinfo = world:Pick(self.camera:GetPosition(true), campos, self.cameraradius, true)
        self.entity:SetPickMode(temp)

        if pickinfo.entity then
            campos = pickinfo.position
        end

        local d = campos:DistanceToPoint(self.camera:GetPosition(true))

        if d > self.smoothcameradistance then
            self.smoothcameradistance = Mix(d, self.smoothcameradistance, 0.9)
        else
            self.smoothcameradistance = Mix(d, self.smoothcameradistance, 0.5)
        end

        campos = TransformPoint(0, 0, -self.smoothcameradistance, self.camera, nil)
    end

    self.camera:SetPosition(campos, true)

    --Animation
    local model = Model(self.entity)
    if model == nil then return end
    local sequencename = "idle"
    if airborne == false and jump == 0 then
        local v = self.entity:GetVelocity()
        if v.xz:Length() > 0.1 then
            sequencename = "walk"
            if shiftkey then
                sequencename = "run"
            end
        end
        model:Animate(sequencename)
    else
        if jump > 0 then
            self.everjumped = true
            model:Animate("jump", 0.1, 250, ANIMATION_ONCE)
        end
    end

end

RegisterComponent("ThirdPersonControls", ThirdPersonControls)

return ThirdPersonControls