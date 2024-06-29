#pragma once
#include "UltraEngine.h"

struct ModelAnimation
{
	int sequence;
	int totalframes;
	float speed;
	float length;
	int blendtime;
	UltraEngine::AnimationMode mode;
};

class AnimationManager : public UltraEngine::Object
{
	std::map<UltraEngine::WString, ModelAnimation> animations;
	std::weak_ptr<UltraEngine::Model> entity;
	UltraEngine::WString idlesequence;
	UltraEngine::WString currentanimation;

	shared_ptr<UltraEngine::Object> extra;
	std::function<void(const UltraEngine::WString name, shared_ptr<UltraEngine::Object>)> endhook;

	void FireCompleteHook(const UltraEngine::WString name);
public:
	AnimationManager();
	~AnimationManager();

	void AddAnimation(const UltraEngine::WString name, const float speed = 1.0f, UltraEngine::AnimationMode mode = UltraEngine::ANIMATION_LOOP, int blendtime = 250);
	void PlayAnimation(const UltraEngine::WString name);
	void SetAnimationSpeed(const UltraEngine::WString name, const float speed);
	void ReturnToRestingAnimation();

	virtual void AddCompleteHook(std::function<void(const UltraEngine::WString name, shared_ptr<UltraEngine::Object>)>, shared_ptr<UltraEngine::Object> extra);

	std::shared_ptr<UltraEngine::Model> GetEntity();
	static void AnimationDoneHook(shared_ptr<UltraEngine::Skeleton> skeleton, shared_ptr<UltraEngine::Object> extra);

	friend std::shared_ptr<AnimationManager> CreateAnimationManager(std::shared_ptr<UltraEngine::Model> entity, const int restingsequence);
};

extern std::shared_ptr<AnimationManager> CreateAnimationManager(std::shared_ptr<UltraEngine::Model> entity, const int restingsequence = 0);