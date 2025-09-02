# simple_godot_caustics
Simple implementation of caustics volume shader for godot engine 4.3+

## Overview

![](/meta/poster.GIF)

The provided shader helps creating custom caustics volumes, that behave decal-like and support non trivial (also runtime) modifications and customization

## Usage

Please refer to `DOCS.md` for quickstart guide and documentation.

Possibilities:
- the shader excels at rendering large bodies of caustics in dim environment
- the shader handles complex geometry well and without major performence drawbacks (compared to plain meshes)
- fully movable and configurable in editor 
- plenty customizable per volume, including:
    + speed, size and strength
    + aberration
    + cutoff
- the shader is standalone, serialaziable and interfaceable

Limitations:
- this shader uses both `screen_texture` and `depth_texture` and thus requires *major boilerplate* to allow any usage of another one of such kind - including having two volumes at once (see official godot docs for details) 
- usage of 4 separate noise textures is a major overhead and creates artifacts when surface is perpendicular to one of the sampling axis (even if physically plausible and *"not a big deal"* when the surface in question is not large)
- lighting is not supported (and since mostly dim areas are targeted, it likely won't be)
- modern architecture only - needs a modification in world space calculating part in certain edge scenarios (see official godot docs for details)

## Future of this project

- I'll tinker with doing separate shader that implements caustics in such a way that "backside" caustics are not rendered according to an axis (this should fix artifacts)
- I'll try making `NoiseTexture3D` implementation, that doesn't mess with aberration in an unpredictable ways
- Generally, I want to support this implentation for future releases, but don't take that for granted

## Acknowledgments

1. [this blog](https://ameye.dev/notes/realtime-caustics/) inspired some of the core solutions of my shader (you may want to read it for yourself if you want to make a caustics implementation yourself, since I've definitely not exhausted the topic)
2. skybox in example scene generated from [this engine](https://tools.wwwtyro.net/space-3d/index.html)
