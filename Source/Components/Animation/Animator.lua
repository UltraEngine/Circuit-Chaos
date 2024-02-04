Animator = {}
Animator.name = "Animator"

Animator.enabled = true
Animator.animationname = ""
Animator.animationspeed = 0.0
Animator.autoplay = false
Animator.loop = false
Animator.bleed = 0

function Animator:Start()
    if self.model and self.autoplay then
        self:PlayAnimation()
    end
end

function Animator:Update()
end

function Animator:PlayAnimation()
    if self.enabled then
        if self.loop then
            self.model:Animate(self.animationname, self.animationspeed, self.bleed, ANIMATION_LOOP, 0, 0)
        else
            self.model:Animate(self.animationname, self.animationspeed, self.bleed, ANIMATION_ONCE, 0, 0);
        end
    end
end

function Animator:StopAnimation()
    self.model:StopAnimation()
end

function Animator:Collide(entity, position, normal, speed)
end

function Animator:Load(properties, binstream, scene, flags)
    self.model = Model(self.entity)
    return true
end

function Animator:Save(properties, binstream, scene, flags)
    return true
end

function Animator:Copy()
    local t = {}
    local k
    local v
    for k, v in pairs(self) do
        t[k] = v
    end
    return t
end

function Animator:Enable()
    self.enabled = true
end

function Animator:Disable()
    self.enabled = false
end

function Animator:Toggle()
    if type(self.enabled) == "boolean" and self.enabled == true then
        self.enabled = false
    else
        self.enabled = true
    end
end

RegisterComponent("Animator", Animator)

return Animator