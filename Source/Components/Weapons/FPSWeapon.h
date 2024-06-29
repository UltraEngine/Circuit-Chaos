#pragma once
#include "UltraEngine.h"
#include "../../AnimationManager.h"

using namespace UltraEngine;

class FPSWeapon : public Component
{
    shared_ptr<Camera> viewmodelcam;
    std::weak_ptr<Model> viewmodel;
    std::weak_ptr<Entity> playerentity;
    std::shared_ptr<Pivot> muzzle;
    bool firing;
    bool reloading;
    std::shared_ptr<AnimationManager> animationmanger;

public:
    bool drawonlayer;
    float viewmodelfov;

    enum
    {
        ANIM_IDLE,
        ANIM_FIRE,
        ANIM_RELOAD,
        ANIM_WALK,
        ANIM_MAX,
    };

    int current_animaton;
    std::array<String, ANIM_MAX> animations;

    FPSWeapon();

    virtual void Start();
    virtual void Update();
    virtual std::shared_ptr<Component> Copy();
    virtual bool Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags);
    virtual bool Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags);

    static void AnimationDone(const UltraEngine::WString name, shared_ptr<UltraEngine::Object> object);
    virtual void AttachToPlayer(std::shared_ptr<Component> playercomponent);

    virtual void Fire();
    virtual void Reload();

    //virtual void Holster();
    //virtual void UnHolster();
};