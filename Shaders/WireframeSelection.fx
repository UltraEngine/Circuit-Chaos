{
    "posteffect":
    {
        "subpasses":
        [
            {
                "samplers": ["DEPTH"],
                "shader":
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/WireframeSelection.frag"
                    }
                }
            }
        ]
    }
}