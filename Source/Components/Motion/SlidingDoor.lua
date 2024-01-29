SlidingDoor = {
    enabled = true,
    openstate = false,
    movement = Vec3(0, 2, 0),
    speed = 1.0,
    maxforce = 1000,
    distancetolerance = 0.1,
    resettime = 5000,
    name = "SlidingDoor"
}

function SlidingDoor:Start()
    if self.entity:GetMass() == 0.0 then
        self.entity:SetMass(10)
    end
    self.startposition = self.entity:GetPosition(true)
    local parent = self.entity:GetParent()
    self.joint = CreateSliderJoint(self.startposition, self.movement:Normalize(), parent, self.entity)
    self.joint:SetMotorSpeed(self.speed)
    self.joint:SetMaxForce(self.maxforce)
end

function SlidingDoor.EventHook(e, door)
    if e.source == door.closetimer then
        door:Close()
    end
    return false
end

function SlidingDoor:Open()
    if self.closetimer then
        self.closetimer:Stop()
        self.closetimer = nil
    end
    if self.resettime > 0 then
        self.closetimer = CreateTimer(self.resettime)
        ListenEvent(EVENT_TIMERTICK, self.closetimer, SlidingDoor.EventHook, self)
    end
    if self.openstate then
        return
    end
    if not self.enabled then
        return
    end
    self.openstate = true
    self.joint:SetPose(self.movement:Length())
    if self.opensound then
        self.entity:EmitSound(self.opensound)
    end
end

function SlidingDoor:Close()
    if self.closetimer then
        self.closetimer:Stop()
        self.closetimer = nil
    end
    if not self.openstate then
        return
    end
    self.openstate = false
    self.joint:SetPose(0)
    if self.closesound then
        self.entity:EmitSound(self.closesound)
    end
end

function SlidingDoor:Enable()
    self.enabled = true
end

function SlidingDoor:Disable()
    self.enabled = false
end

function SlidingDoor:Load(t, binstream, scene, flags)
    if type(self.startposition) == "table" and #self.startposition == 3 then
        local temp = self.entity:GetPosition(true)
        self.entity:SetPosition(self.startposition, true)
        if self.entity:GetMass() == 0.0 then
            self.entity:SetMass(10)
        end
        self.joint = CreateSliderJoint(self.startposition, self.movement:Normalize(), self.entity:GetParent(), self.entity)
        self.joint:SetMotorSpeed(self.speed)
        self.joint:SetMaxForce(self.maxforce)
        self.entity:SetPosition(temp, true)
    end
    if type(self.opensound) == "string" then
        self.opensound = LoadSound(t.opensound)
    end
    if type(t.closesound) == "string" then
        self.closesound = LoadSound(t.closesound)
    end
    if self.openstate then
        self:Open()
    else
        self:Close()
    end
    return true
end

function SlidingDoor:Use(caller)
    if self.openstate then
        self:Close()
    else
        self:Open()
    end
end

function SlidingDoor:Save(t, binstream, scene, flags)
    if self.opensound and not self.opensound.path == "" then
        t.opensound = self.opensound.path
    end
    if self.closesound and not self.closesound.path == "" then
        t.closesound = self.closesound.path
    end
    return true
end

RegisterComponent("SlidingDoor", SlidingDoor)

return SlidingDoor