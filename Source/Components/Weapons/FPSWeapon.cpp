#pragma once
#include "UltraEngine.h"
#include "../Player/FirstPersonControls.h"
#include "FPSWeapon.h"

using namespace UltraEngine;

const int RENDERLAYER_VIEWMODEL = 8;

void FPSWeapon::AnimationDone(const UltraEngine::WString name, shared_ptr<UltraEngine::Object> object)
{
	auto wpn = object->As<FPSWeapon>();
	if (wpn)
	{
		if (name == wpn->animations[ANIM_RELOAD])
		{
			wpn->reloading = false;
		}
	}
}

FPSWeapon::FPSWeapon()
{
    name = "FPSWeapon";
	viewmodelfov = 54.0f;
	viewmodelcam = NULL;
	muzzle = NULL;
	drawonlayer = false;
	animations.fill("");
	animations[ANIM_IDLE] = "idle";
	animationmanger = NULL;
	reloading = false;
	firing = false;
}

void FPSWeapon::Start()
{
	// Now find the model we'll be animating. It's possible that the model will be parented to a pivot.
	auto entity = GetEntity();
	if (!entity->As<Model>())
	{
		for (const auto& p : entity->kids)
		{
			auto mdl = p->As<Model>();
			if (mdl)
			{	
				mdl->Animate(animations[ANIM_IDLE], 0.25f);
				viewmodel = mdl;
				break;
			}
			else if (p->As<Pivot>() && p->name == "Muzzle")
			{
				if (!muzzle) muzzle = p->As<Pivot>();
			}
		}
	}

	Assert(viewmodel.lock(), "No viewmodel found for FPSWeapon!");
	viewmodel.lock()->SetShadows(false);

	int i = viewmodel.lock()->FindAnimation(animations[ANIM_IDLE]);
	animationmanger = CreateAnimationManager(viewmodel.lock(), i);
	animationmanger->SetAnimationSpeed(animations[ANIM_IDLE], 0.25f);
	animationmanger->AddAnimation(animations[ANIM_WALK], 0.25);
	animationmanger->AddAnimation(animations[ANIM_FIRE]);
	animationmanger->AddAnimation(animations[ANIM_RELOAD], 1.0f, ANIMATION_ONCE);
	animationmanger->AddCompleteHook(FPSWeapon::AnimationDone, Self());
}

void FPSWeapon::Update()
{
	static bool moving = false;
	//static bool reloading = false;

	if (!reloading && !firing)
	{
		auto velo = playerentity.lock()->GetVelocity().xz().Length();
		if (velo > 4.0f * 0.5)
		{
			if (!playerentity.lock()->GetAirborne())
			{
				animationmanger->PlayAnimation(animations[ANIM_WALK]);
				moving = true;
			}
		}
		else if (moving)
		{
			animationmanger->ReturnToRestingAnimation();
			moving = false;
		}
	}
	else
	{
		Print("Skiping");
	}

	auto window = ActiveWindow();
	if (window)
	{
		if (window->KeyHit(KEY_R))
		{
			reloading = true;
			animationmanger->PlayAnimation(animations[ANIM_RELOAD]);
			Reload();
		}

		if (!reloading)
		{
			if (window->MouseDown(MOUSE_LEFT))
			{
				firing = true;
				animationmanger->PlayAnimation(animations[ANIM_FIRE]);
				Fire();
			}
			else if (firing)
			{
				firing = false;
				animationmanger->ReturnToRestingAnimation();
			}
		}
	}
}

//This method will work with simple components
shared_ptr<Component> FPSWeapon::Copy()
{
	return std::make_shared<FPSWeapon>(*this);
}

bool FPSWeapon::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags)
{
	if (properties["anim_idle"].is_string()) animations[ANIM_IDLE] = properties["anim_idle"];
	if (properties["anim_fire"].is_string()) animations[ANIM_FIRE] = properties["anim_fire"];
	if (properties["anim_reload"].is_string()) animations[ANIM_RELOAD] = properties["anim_reload"];
	if (properties["anim_walk"].is_string()) animations[ANIM_WALK] = properties["anim_walk"];

	if (properties["viewmodelfov"].is_number()) viewmodelfov = properties["viewmodelfov"];
	if (properties["drawonlayer"].is_boolean()) drawonlayer = properties["drawonlayer"];
	return true;
}

bool FPSWeapon::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags)
{
	properties["anim_idle"] = animations[ANIM_IDLE];
	properties["anim_fire"] = animations[ANIM_FIRE];
	properties["anim_reload"] = animations[ANIM_RELOAD];
	properties["anim_walk"] = animations[ANIM_WALK];

	properties["viewmodelfov"] = viewmodelfov;
	properties["drawonlayer"] = drawonlayer;
	return true;
}

void FPSWeapon::AttachToPlayer(std::shared_ptr<Component> playercomponent)
{
	// Set up the camera for the viewmodel.
	Start();

	auto entity = GetEntity();
	auto world = entity->GetWorld();

	auto player = playercomponent->As<FirstPersonControls>();
	if (player)
	{
		auto playercam = player->GetCamera();
		if (playercam != NULL)
		{
			if (drawonlayer)
			{
				viewmodelcam = CreateCamera(world);
				viewmodelcam->SetClearColor(0, 0, 0, 0);
				viewmodelcam->SetClearMode(CLEAR_DEPTH);
				viewmodelcam->SetMatrix(playercam->GetMatrix(true), true);
				viewmodelcam->SetFov(viewmodelfov);
				viewmodelcam->SetRange(0.001f, playercam->GetRange().y);
				viewmodelcam->SetOrder(RENDERLAYER_VIEWMODEL);
				viewmodelcam->SetRenderLayers(RENDERLAYER_VIEWMODEL);
				viewmodelcam->SetParent(playercam);

				entity->SetParent(viewmodelcam);

				entity->SetRenderLayers(RENDERLAYER_VIEWMODEL);
				viewmodel.lock()->SetRenderLayers(RENDERLAYER_VIEWMODEL);
			}
			else
			{
				playercam->SetRange(0.001f, playercam->GetRange().y);
				entity->SetParent(playercam);
			}
		}

		playerentity = player->GetEntity();
	}
}

void FPSWeapon::Fire()
{
}

void FPSWeapon::Reload()
{
}