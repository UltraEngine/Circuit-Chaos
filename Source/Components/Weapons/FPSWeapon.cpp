#pragma once
#include "UltraEngine.h"
#include "../Player/FirstPersonControls.h"
#include "FPSWeapon.h"

using namespace UltraEngine;

const int RENDERLAYER_VIEWMODEL = 8;

void AnimationDone(shared_ptr<Skeleton> skeleton, shared_ptr<Object> extra)
{
	auto wpn = extra->As<FPSWeapon>();
	if (wpn)
	{
		Print("Done!");
		wpn->Idle();
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

	viewmodel.lock()->skeleton->AddHook(0, 0, AnimationDone, Self());
}

void FPSWeapon::Update()
{
	static bool moving = false;
	auto velo = playerentity.lock()->GetVelocity().xz().Length();
	if (velo > 4.0f * 0.5)
	{
		if (!playerentity.lock()->GetAirborne())
		{
			viewmodel.lock()->Animate(animations[ANIM_WALK], 0.25f);
			moving = true;
		}
	}
	else if (moving)
	{
		Idle();
		moving = false;
	}

	auto window = ActiveWindow();
	if (window)
	{
		if (window->KeyDown(KEY_R))
		{
			Reload();
		}

		if (window->MouseDown(MOUSE_LEFT))
		{
			Fire();
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

void FPSWeapon::Idle()
{
	viewmodel.lock()->Animate(animations[ANIM_IDLE], 0.25f);
}

void FPSWeapon::Fire()
{
	viewmodel.lock()->Animate(animations[ANIM_FIRE], 1.00f, 250, ANIMATION_ONCE);
}

void FPSWeapon::Reload()
{
	viewmodel.lock()->Animate(animations[ANIM_RELOAD], 1.00f, ANIMATION_ONCE);
}