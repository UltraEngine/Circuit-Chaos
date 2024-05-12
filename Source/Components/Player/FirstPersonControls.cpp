#pragma once
#include "UltraEngine.h"
#include "FirstPersonControls.h"

using namespace UltraEngine;

FirstPersonControls::FirstPersonControls()
{
	name = "FirstPersonControls";
}

void FirstPersonControls::Start()
{
	auto entity = GetEntity();
	entity->SetPhysicsMode(PHYSICS_PLAYER);
	if (entity->GetMass() == 0.0f) entity->SetMass(78);
	entity->SetCollisionType(COLLISION_PLAYER);
	camera = CreateCamera(entity->GetWorld());
	camera->SetPosition(0, eyeheight, 0);
	camera->SetRotation(0, 0, 0);
	camera->SetFov(fov);
	currentcameraposition = camera->GetPosition(true);
	freelookrotation = entity->GetRotation(true);
}

void FirstPersonControls::Update()
{
	Vec3 movement;
	float jump = 0;
	bool crouch = false;
	auto entity = GetEntity();
	auto window = ActiveWindow();
	if (window)
	{
		/*
		if (!freelookstarted)
		{
			freelookstarted = true;
			freelookrotation = entity->GetRotation(true);
			freelookmousepos = window->GetMouseAxis();
		}
		auto newmousepos = window->GetMouseAxis();
		lookchange.x = lookchange.x * mousesmoothing + (newmousepos.y - freelookmousepos.y) * 100.0f * mouselookspeed * (1.0f - mousesmoothing);
		lookchange.y = lookchange.y * mousesmoothing + (newmousepos.x - freelookmousepos.x) * 100.0f * mouselookspeed * (1.0f - mousesmoothing);
		if (Abs(lookchange.x) < 0.001f) lookchange.x = 0.0f;
		if (Abs(lookchange.y) < 0.001f) lookchange.y = 0.0f;
		if (lookchange.x != 0.0f or lookchange.y != 0.0f)
		{
			freelookrotation.x += lookchange.x;
			freelookrotation.y += lookchange.y;
			camera->SetRotation(freelookrotation, true);
		}
		freelookmousepos = newmousepos;
		*/

		auto cx = Round((float)window->GetFramebuffer()->GetSize().x / 2);
		auto cy = Round((float)window->GetFramebuffer()->GetSize().y / 2);
		auto mpos = window->GetMousePosition();
		window->SetMousePosition(cx, cy);
		auto centerpos = window->GetMousePosition();

		if (freelookstarted)
		{
			float looksmoothing = mousesmoothing; //0.5f;
			float lookspeed = mouselookspeed / 10.0f;

			if (looksmoothing > 0.00f)
			{
				mpos.x = mpos.x * looksmoothing + freelookmousepos.x * (1 - looksmoothing);
				mpos.y = mpos.y * looksmoothing + freelookmousepos.y * (1 - looksmoothing);
			}

			auto dx = (mpos.x - centerpos.x) * lookspeed;
			auto dy = (mpos.y - centerpos.y) * lookspeed;

			freelookrotation.x = freelookrotation.x + dy;
			freelookrotation.x = Clamp(freelookrotation.x, -90.0f, 90.0f);
			freelookrotation.y = freelookrotation.y + dx;
			camera->SetRotation(freelookrotation, true);
			freelookmousepos = Vec3(mpos.x, mpos.y);
		}
		else
		{
			freelookstarted = true;
			freelookrotation = camera->GetRotation(true);
			freelookmousepos = Vec3(window->GetMousePosition().x, window->GetMousePosition().y);
			window->SetCursor(CURSOR_NONE);
		}

		float speed = movespeed;// / 60.0f;
		bool jumpkey = window->KeyHit(KEY_SPACE);
		if (entity->GetAirborne())
		{
			speed *= 0.25f;
		}
		else
		{
			if (window->KeyDown(KEY_SHIFT))
			{
				speed *= 2.0f;
			}
			else if (window->KeyDown(KEY_CONTROL))
			{
				speed *= 0.5f;
			}
			if (jumpkey)
			{
				jump = jumpforce;
			}
		}
		if (window->KeyDown(KEY_D)) movement.x += speed;
		if (window->KeyDown(KEY_A)) movement.x -= speed;
		if (window->KeyDown(KEY_W)) movement.z += speed;
		if (window->KeyDown(KEY_S)) movement.z -= speed;
		if (movement.x != 0.0f and movement.z != 0.0f) movement *= 0.707f;
		if (jump != 0.0f)
		{
			movement.x *= jumplunge;
			if (movement.z > 0.0f) movement.z *= jumplunge;
		}
		crouch = window->KeyDown(KEY_CONTROL);
	}
	entity->SetInput(camera->rotation.y, movement.z, movement.x, jump, crouch);
	
	// TODO: Need something like entity->GetCrouched() so we don't have to do a raycast ourselves. 
	float eye = eyeheight;
	if (crouch) eye = croucheyeheight;
	float y = TransformPoint(currentcameraposition, nullptr, entity).y;
	float h = eye;
	if (y < eye || eye != eyeheight) h = Mix(y, eye, 0.25f);
	currentcameraposition = TransformPoint(0, h, 0, entity, nullptr);
	camera->SetPosition(currentcameraposition, true);
}

//This method will work with simple components
shared_ptr<Component> FirstPersonControls::Copy()
{
	return std::make_shared<FirstPersonControls>(*this);
}

bool FirstPersonControls::Load(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const LoadFlags flags)
{
	if (properties["fov"].is_number()) fov = properties["fov"];
	if (properties["eyeheight"].is_number()) eyeheight = properties["eyeheight"];
	if (properties["croucheyeheight"].is_number()) croucheyeheight = properties["croucheyeheight"];
	if (properties["mouselookspeed"].is_number()) mouselookspeed = properties["mouselookspeed"];
    if (properties["mousesmoothing"].is_number()) mousesmoothing = properties["mousesmoothing"];
    if (properties["mouselookspeed"].is_number()) mouselookspeed = properties["mouselookspeed"];
    if (properties["movespeed"].is_number()) movespeed = properties["movespeed"];
	if (properties["jumpforce"].is_number()) jumpforce = properties["jumpforce"];
	if (properties["jumplunge"].is_number()) jumplunge = properties["jumplunge"];
	return true;
}

bool FirstPersonControls::Save(table& properties, shared_ptr<Stream> binstream, shared_ptr<Map> scene, const SaveFlags flags)
{
	properties["fov"] = fov;
	properties["eyeheight"] = eyeheight;
	properties["croucheyeheight"] = croucheyeheight;
	properties["mousesmoothing"] = mousesmoothing;
	properties["mouselookspeed"] = mouselookspeed;
	properties["movespeed"] = movespeed;
	properties["jumpforce"] = jumpforce;
	properties["jumplunge"] = jumplunge;
	return true;
}