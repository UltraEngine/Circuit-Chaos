--Initialze Steam (optional)
--if not Steamworks.Initialize() then return 1 end

--Load FreeImage plugin (optional)
local fiplugin = LoadPlugin("Plugins/FITextureLoader")

--Get the displays
local displays = GetDisplays()

--Create a window
local window = CreateWindow("Ultra Engine", 0, 0, 1280, 720, displays[1], WINDOW_CENTER | WINDOW_TITLEBAR)

--Create a framebuffer
local framebuffer = CreateFramebuffer(window)

--Create a world
local world = CreateWorld()

--Load a map
local mapname = "Maps/start.ultra"
local cl = CommandLine()
if type(cl["map"]) == "string" then mapname = cl["map"] end
local scene = LoadMap(world, mapname)

while window:KeyDown(KEY_ESCAPE) == false and window:Closed() == false do
    
    --Garbage collection step
    collectgarbage()

    --Update the world
    world:Update()
    Steamworks.Update()
    
    --Render the world to the framebuffer
    world:Render(framebuffer)
end

Steamworks.Shutdown()