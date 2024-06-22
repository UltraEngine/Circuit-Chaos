{
    "posteffect":
    {
        "textures":
        [
            {
                "size": [0.5, 0.5],
                "format": 97
            },
            {
                "size": [0.25, 0.25],
                "format": 97
            },
            {
                "size": [0.125, 0.125] ,
                "format" : 97
            },
            {
                "size": [0.0625, 0.0625] ,
                "format" : 97
            }
        ],
        "subpasses":
        [
            {
                "colorattachments": [0],
                "samplers": [ "PREVPASS" ],
                "shader":
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/BloomBlurX.frag"
                    }
                }
            },
            {
                "colorattachments": [1],
                "samplers": [ 0 ],
                "shader":
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/BloomBlurY.frag"
                    }
                }
            },
            {
                "colorattachments": [2] ,
                "samplers" : [ 1 ],
                "shader" :
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/BloomBlurX.frag"
                    }
                }
            },
            {
                "colorattachments": [3] ,
                "samplers" : [2],
                "shader" :
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/BloomBlurY.frag"
                    }
                }
            },
            {
                "samplers": ["PREVPASS", 3],
                "shader":
                {
                    "float32":
                    {
                        "fragment": "Shaders/PostEffects/BloomResolve.frag"
                    }
                }
            }                      
        ]
    }
}