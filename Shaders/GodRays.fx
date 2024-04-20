{
    "posteffect":
    {
        "textures":
        [
            {
                "size": [0.5, 0.5],
                "format": 37
            }
        ],
        "subpasses":
        [
            {    
                "samplers": ["PREVPASS"],
                "colorattachments": [0],
                "shader":
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/GodRays.frag"
                    }
                }
            },
            {
                "samplers": ["PREVPASS", 0],
                "shader":
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/GodRaysResolve.frag"
                    }
                }
            }
        ]
    }
}