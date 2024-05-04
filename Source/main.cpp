#include "UltraEngine.h"
#include "ComponentSystem.h"
//#include "Steamworks/Steamworks.h"

using namespace UltraEngine;

int main(int argc, const char* argv[])
{
    
#ifdef STEAM_API_H
    if (not Steamworks::Initialize())
    {
        RuntimeError("Steamworks failed to initialize.");
        return 1;
    }
#endif

    RegisterComponents();

    auto cl = ParseCommandLine(argc, argv);
    
    //Load FreeImage plugin (optional)
    auto fiplugin = LoadPlugin("Plugins/FITextureLoader");

    //Get the displays
    auto displays = GetDisplays();

    //Create a window
    iVec2 windowsize = iVec2(1280, 720);
    WindowStyles windowstyle = WINDOW_CENTER | WINDOW_TITLEBAR;
    if (cl["screenwidth"].is_number()) windowsize.x = cl["screenwidth"];
    if (cl["screenheight"].is_number()) windowsize.y = cl["screenheight"];
    if (cl["fullscreen"].is_boolean())
    {
        if (cl["fullscreen"])
        {
            windowsize.x = displays[0]->size.x;
            windowsize.y = displays[0]->size.y;
            windowstyle = WINDOW_FULLSCREEN;
        }
    }
    auto window = CreateWindow("Ultra Engine", 0, 0, windowsize.x * displays[0]->scale, windowsize.y * displays[0]->scale, displays[0], windowstyle);

    //Create a framebuffer
    auto framebuffer = CreateFramebuffer(window);

    //Create a world
    auto world = CreateWorld();

    //Load the map
    WString mapname = "Maps/start.ultra";
    if (cl["map"].is_string()) mapname = std::string(cl["map"]);
    auto scene = LoadMap(world, mapname);

    //Main loop
    while (window->Closed() == false and window->KeyDown(KEY_ESCAPE) == false)
    {
        world->Update();
        world->Render(framebuffer);

#ifdef STEAM_API_H
        Steamworks::Update();
#endif

    }

#ifdef STEAM_API_H
    Steamworks::Shutdown();
#endif

    return 0;
}