set EXEPATH=%ULTRAENGINE%/Tools/glSlangValidator.exe
set BINPATH=Shaders

"%EXEPATH%" "Source/Shaders/Editor/Grid.frag" -V -o "%BINPATH%/Grid.frag.spv"

"%EXEPATH%" "Source/Shaders/Shadow/Shadow.vert" -V -o "%BINPATH%/Shadow.vert.spv"
"%EXEPATH%" "Source/Shaders/Shadow/Shadow.frag" -V -o "%BINPATH%/Shadow.frag.spv"
"%EXEPATH%" "Source/Shaders/Utilities/BlurX.frag" -V -o "%BINPATH%/BlurX.frag.spv"
"%EXEPATH%" "Source/Shaders/Utilities/BlurY.frag" -V -o "%BINPATH%/BlurY.frag.spv"

"%EXEPATH%" "Source/Shaders/DepthPass/DepthPass.vert" -V -o "%BINPATH%/DepthPass.vert.spv"
"%EXEPATH%" "Source/Shaders/DepthPass/DepthPass_WidgetBlock.frag" -V -o "%BINPATH%/DepthPass_WidgetBlock.frag.spv"
"%EXEPATH%" "Source/Shaders/DepthPass/DepthPass_Masked.vert" -V -o "%BINPATH%/DepthPass_Masked.vert.spv"
"%EXEPATH%" "Source/Shaders/DepthPass/DepthPass_Animated.vert" -V -o "%BINPATH%/DepthPass_Animated.vert.spv"
"%EXEPATH%" "Source/Shaders/DepthPass/DepthPass_Tess.vert" -V -o "%BINPATH%/DepthPass_Tess.vert.spv"
"%EXEPATH%" "Source/Shaders/DepthPass/DepthPass_Masked.frag" -V -o "%BINPATH%/DepthPass_Masked.frag.spv"
"%EXEPATH%" "Source/Shaders/DepthPass/DepthPass_Tess_Masked.vert" -V -o "%BINPATH%/DepthPass_Tess_Masked.vert.spv"

"%EXEPATH%" "Source/Shaders/PBR/PBR.vert" -V -o "%BINPATH%/PBR.vert.spv"
"%EXEPATH%" "Source/Shaders/PBR/PBR_Animated.vert" -V -o "%BINPATH%/PBR_Animated.vert.spv"
"%EXEPATH%" "Source/Shaders/PBR/PBR_Tess.vert" -V -o "%BINPATH%/PBR_Tess.vert.spv"
"%EXEPATH%" "Source/Shaders/PBR/PBR.frag" -V -o "%BINPATH%/PBR.frag.spv"
"%EXEPATH%" "Source/Shaders/PBR/PBR_Transparency.frag" -V -o "%BINPATH%/PBR_Transparency.frag.spv"
"%EXEPATH%" "Source/Shaders/PBR/PBR_Masked.frag" -V -o "%BINPATH%/PBR_Masked.frag.spv"
"%EXEPATH%" "Source/Shaders/PBR/SpecularGloss.frag" -V -o "%BINPATH%/SpecularGloss.frag.spv"
"%EXEPATH%" "Source/Shaders/PBR/SpecularGloss_Transparency.frag" -V -o "%BINPATH%/SpecularGloss_Transparency.frag.spv"
"%EXEPATH%" "Source/Shaders/PBR/SpecularGloss_Masked.frag" -V -o "%BINPATH%/SpecularGloss_Masked.frag.spv"

"%EXEPATH%" "Source/Shaders/Sky/Sky.frag" -V -o "%BINPATH%/Sky.frag.spv"
"%EXEPATH%" "Source/Shaders/Sky/Sky.vert" -V -o "%BINPATH%/Sky.vert.spv"

"%EXEPATH%" "Source/Shaders/Unlit/Unlit.frag" -V -o "%BINPATH%/Unlit.frag.spv"
"%EXEPATH%" "Source/Shaders/Unlit/Unlit_Masked.frag" -V -o "%BINPATH%/Unlit_Masked.frag.spv"
"%EXEPATH%" "Source/Shaders/Unlit/Unlit_Masked_Transparency.frag" -V -o "%BINPATH%/Unlit_Masked_Transparency.frag.spv"
"%EXEPATH%" "Source/Shaders/Unlit/Unlit_Transparency.frag" -V -o "%BINPATH%/Unlit_Transparency.frag.spv"

"%EXEPATH%" "Source/Shaders/GUI/WidgetBlock.frag" -V -o "%BINPATH%/WidgetBlock.frag.spv"
"%EXEPATH%" "Source/Shaders/GUI/WidgetBlock.vert" -V -o "%BINPATH%/WidgetBlock.vert.spv"

:: Post-processing Effects
"%EXEPATH%" "Source/Shaders/PostEffects/PostEffect.vert" -V -o "%BINPATH%/PostEffect.vert.spv"
"%EXEPATH%" "Source/Shaders/PostEffects/Refraction.frag" -V -o "%BINPATH%/Refraction.frag.spv"
"%EXEPATH%" "Source/Shaders/PostEffects/SSAO.frag" -V -o "%BINPATH%/SSAO.frag.spv"
"%EXEPATH%" "Source/Shaders/PostEffects/Denoise.frag" -V -o "%BINPATH%/Denoise.frag.spv"
"%EXEPATH%" "Source/Shaders/PostEffects/SSAOResolve.frag" -V -o "%BINPATH%/SSAOResolve.frag.spv"
"%EXEPATH%" "Source/Shaders/PostEffects/FXAA.frag" -V -o "%BINPATH%/FXAA.frag.spv"
"%EXEPATH%" "Source/Shaders/PostEffects/BloomBlurX.frag" -V -o "%BINPATH%/BloomBlurX.frag.spv"
"%EXEPATH%" "Source/Shaders/PostEffects/BloomBlurY.frag" -V -o "%BINPATH%/BloomBlurY.frag.spv"
"%EXEPATH%" "Source/Shaders/PostEffects/BloomResolve.frag" -V -o "%BINPATH%/BloomResolve.frag.spv"
"%EXEPATH%" "Source/Shaders/PostEffects/Outline.frag" -V -o "%BINPATH%/Outline.frag.spv"

"%EXEPATH%" "Source/Shaders/Khronos/IBLFilter.frag" -V -o "%BINPATH%/IBLFilter.frag.spv"

pause

