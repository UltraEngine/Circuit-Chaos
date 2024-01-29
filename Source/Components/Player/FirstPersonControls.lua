FirstPersonControls = {
    freelookstarted = false,
    freelookmousepos = Vec3(0, 0, 0),
    freelookrotation = Vec3(0, 0, 0),
    lookchange = Vec2(0, 0),
    camera = nil,
    currentcameraposition = Vec3(0, 0, 0),
    eyeheight = 1.7,
    croucheyeheight = 1.0,
    mousesmoothing = 0.0,
    mouselookspeed = 1.0,
    movespeed = 4.0,
    jumpforce = 8.0,
    jumplunge = 1.5,
    name = "FirstPersonControls"
}

function FirstPersonControls:Start()
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

function FirstPersonControls:Update()
    local movement = Vec3(0, 0, 0)
    local jump = 0
    local crouch = false
    local window = ActiveWindow()

    if window ~=nil then
        if not self.freelookstarted then
            self.freelookstarted = true
            self.freelookrotation = self.entity:GetRotation(true)
            self.freelookmousepos = window:GetMouseAxis()
        end

        local newmousepos = window:GetMouseAxis()
        self.lookchange.x = self.lookchange.x * self.mousesmoothing + (newmousepos.y - self.freelookmousepos.y) * 100.0 * self.mouselookspeed * (1.0 - self.mousesmoothing)
        self.lookchange.y = self.lookchange.y * self.mousesmoothing + (newmousepos.x - self.freelookmousepos.x) * 100.0 * self.mouselookspeed * (1.0 - self.mousesmoothing)

        if math.abs(self.lookchange.x) < 0.001 then
            self.lookchange.x = 0
        end

        if math.abs(self.lookchange.y) < 0.001 then
            self.lookchange.y = 0
        end

        if self.lookchange.x ~= 0 or self.lookchange.y ~= 0 then
            self.freelookrotation.x = self.freelookrotation.x + self.lookchange.x
            self.freelookrotation.y = self.freelookrotation.y + self.lookchange.y
            self.camera:SetRotation(self.freelookrotation, true)
        end

        self.freelookmousepos = newmousepos
        local speed = self.movespeed

        local jumpkey = window:KeyHit(KEY_SPACE)

        if self.entity:GetAirborne() then
            speed = speed * 0.25
        else
            if window:KeyDown(KEY_SHIFT) then
                speed = speed * 2.0
            elseif window:KeyDown(KEY_CONTROL) then
                speed = speed * 0.5
            end

            if jumpkey then
                jump = self.jumpforce
            end
        end

        if window:KeyDown(KEY_D) then movement.x = speed end
        if window:KeyDown(KEY_A) then movement.x = -speed end
        if window:KeyDown(KEY_W) then movement.z = speed end
        if window:KeyDown(KEY_S) then movement.z = -speed end

        if movement.x ~= 0 and movement.z ~= 0 then
            movement = movement * 0.707
        end

        if jump ~= 0 then
            movement.x = movement.x * self.jumplunge
            if movement.z > 0 then
                movement.z = movement.z * self.jumplunge
            end
        end

        crouch = window:KeyDown(KEY_CONTROL)
    end

    self.entity:SetInput(self.camera.rotation.y, movement.z, movement.x, jump, crouch)

    local eye = self.eyeheight
    local y = TransformPoint(self.currentcameraposition, nil, self.entity).y
    local h = eye

    if y < eye then
        h = Mix(y, eye, 0.5)
    end

    self.currentcameraposition = TransformPoint(0, h, 0, self.entity, nil)
    self.camera:SetPosition(self.currentcameraposition, true)
end

RegisterComponent("FirstPersonControls", FirstPersonControls)

-- Return the table
return FirstPersonControls