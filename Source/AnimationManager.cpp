#include "UltraEngine.h"
#include "AnimationManager.h"

using namespace UltraEngine;

AnimationManager::AnimationManager()
{
	animations.clear();
	idlesequence.clear();
	currentanimation.clear();
	endhook = NULL;
}

AnimationManager::~AnimationManager()
{
	animations.clear();
	idlesequence.clear();
	currentanimation.clear();
	endhook = NULL;
}

std::shared_ptr<UltraEngine::Model> AnimationManager::GetEntity()
{
	return entity.lock();
}

void AnimationManager::AnimationDoneHook(shared_ptr<Skeleton> skeleton, shared_ptr<Object> extra)
{
	auto self = extra->As<AnimationManager>();
	if (self)
	{
		Print("DONE!!");
		self->FireCompleteHook(self->currentanimation);
		self->ReturnToRestingAnimation();
	}
}

void AnimationManager::AddAnimation(const WString name, const float speed, AnimationMode mode, int blendtime)
{
	ModelAnimation anim;
	anim.sequence = GetEntity()->FindAnimation(name);
	anim.totalframes = GetEntity()->CountAnimationFrames(anim.sequence);
	anim.length = GetEntity()->GetAnimationLength(anim.sequence);
	anim.speed = speed;
	anim.mode = mode;
	anim.blendtime = blendtime;

	auto skeleton = GetEntity()->skeleton;
	if (skeleton && anim.mode != ANIMATION_LOOP)
	{
		skeleton->AddHook(anim.sequence, anim.totalframes-10, AnimationDoneHook, Self()); // 50
	}

	animations[name] = anim;
}

void AnimationManager::PlayAnimation(const UltraEngine::WString name)
{
	if (currentanimation != name)
	{
		GetEntity()->Animate(animations[name].sequence, animations[name].speed, animations[name].blendtime);
		currentanimation = name;
	}
}

void AnimationManager::SetAnimationSpeed(const UltraEngine::WString name, const float speed)
{
	animations[name].speed = speed;
	if (name == idlesequence) ReturnToRestingAnimation();
}

void AnimationManager::ReturnToRestingAnimation()
{
	if (!currentanimation.empty())
	{
		GetEntity()->Animate(animations[idlesequence].sequence, animations[idlesequence].speed);
		currentanimation.clear();
	}
}

void AnimationManager::FireCompleteHook(const UltraEngine::WString name)
{
	if (endhook) endhook(name, extra);
}

void AnimationManager::AddCompleteHook(std::function<void(const UltraEngine::WString name, shared_ptr<UltraEngine::Object>)> func, shared_ptr<UltraEngine::Object> extra)
{
	endhook = func;
	this->extra = extra;
}

std::shared_ptr<AnimationManager> CreateAnimationManager(std::shared_ptr<UltraEngine::Model> entity, const int restingsequence)
{
	auto animmanger = std::make_shared<AnimationManager>();
	animmanger->entity = entity;
	WString seq = animmanger->GetEntity()->GetAnimationName(restingsequence);
	animmanger->AddAnimation(seq);
	animmanger->idlesequence = seq;
	animmanger->ReturnToRestingAnimation();
	return animmanger;
}