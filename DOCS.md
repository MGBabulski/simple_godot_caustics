# Documetation
This file gives extensive information about caustics shader and its configuration. Feel free to also look into the shader itself and modify it to your liking.

## Quickstart

Check if the shader works as intended by reproducing example presented in `README.md` as a gif
- Create a `MeshInstance3D` instance
- Create a *10x10x10* `BoxMesh` instance as a mesh (other shapes will likely give a "looking glass effect")
- Create appropriate shader material for your mesh (and put `caustics_volume.gdshader` as a shader)
- Configure parameters as such
    + (see images below)
    + for noise, `Cellular` noise of `Euclidean Squared` and `Distance 2 div` return type tended to work best for me (you may obviously choose custom textures)

![](/meta/demo_settings.png) 
![](/meta/noise_settings.png)
![](/meta/fastnoiselite_settings.png)

- Create a *20x20* `PlaneMesh` as a floor and some other shapes (remember caustics work like decals - no objects, no caustics)
- Configure `WorldEnvironment` to your liking and place `DirectionalLight3D` with soft and dim light
- If you succeeded, tinker with parameters, settings and use these volumes to your advantage. And above all: *have fun!*

## Parameters (uniforms)

Note: due to my wish of supporting multiple caustics implementation, these docs are pre-divided into common parameters and implementation-specific parameters (subject to change)

### Common parameters

| Type | Parameter name | Description |
| ---- | ---- | ---- |
| `vec3` | `bounding_box_size` | Forward of `BoxMesh.Size` parameter, **MUST** be forwarded in order to show caustics as intended. Forwarding "smaller" numbers will result in smaller caustics volume (however note, that `fading_point` parameter should be used to manipulate cutoffs). Forwarding larger numbers will result in "looking glass effect" where volume will be larger than mesh, effectively making large bodies of caustics being albe to be witnessed only by looking into the shape, while this effect (especially with `SphereMesh`) may be used to your advantage, it's generally not desired and 1-1 forward should take place. |
| `float` | `uv_scale` | Scale for `UV` (the "zoom" of texture sample), optimal values should be acquired by heurestics. |
| `float` | `caustics_speed` | Speed of caustics texture scroll, `0.0` will make animation stop, negative values will reverse animation direction (please note, that animation direction is hardcoded, and since in the vast majority of the cases would not change the effect significantly enough, its not exposed to editor) |
| `float` | `caustics_strength` | Strength of caustics, larger values will make them appear brighter (should be hdr compliant). Values less or equal `0.0` will make them disappear. Note, that while working with extremely large values, it's recommended to lower `cromatic_cutoff` parameter, as well as make `ColorRamp` noise parameter gradient less steep (that is, allowing much more darker points in noise) in order to retain more natural look of caustics. |
| `float` | `caustics_aberration` | A factor by which rgb channels are separated while sampling the noise, `0.0` will make channels allign, negative values will reverse aberration directions (the directions are hardcoded).|
| `float` | `chromatic_cutoff`| Cutoff parameter for channels. If final caustics channel value is less than `chromatic_cutoff`, it will not be rendered. It's recommended to first tinker with `ColorRamp` noise parameter, before changing this one.|
| `float` | `fading_point` | Controls how far from edge (taxicab wise), caustics start to vanish. Values less or equal `0.0` will result in ever-sharp caustics. It's not recommended to set this value much higher than 30% of smallest bounding box edge size. |

### `caustics_volume` specific parameters

| Type | Parameter name | Description |
| ---- | ---- | ---- |
| `float` | `blending_factor` | A ratio used to mix XZ and XY noise channels. | 
| `sampler2D` | `noise_XZ_1` | Noise texture used to generate caustics. Value `min(noise_XZ_1,noise_XZ_2)` is used to determine XZ channel's final color of the pixel.|
| `sampler2D` | `noise_XZ_2` | (as above) |
| `sampler2D` | `noise_XY_1` | Noise texture used to generate caustics. Value `min(noise_XY_1,noise_XY_2)` is used to determine XY channel's final color of the pixel.|
| `sampler2D` | `noise_XY_2` | (as above) |
| `mat3` | `XY_transform` | A matrix used to modify XY axis uv as follows: if by default noise is read in accordance with (x,y) plane coordinated, then after transformation they are read in accordance with (w,t) plane coordinates derived by $ \operatorname{XYtransform} \ast (x,y,z) = (w,t,u) $ in particular certain values are *voided* and do not have any effect. Consider the following representation: $$ \begin{bmatrix} a & b & c \\ d & e & f \\ \operatorname{void} & \operatorname{void} & \operatorname{void}  \end{bmatrix} \ast \begin{bmatrix} x \\ y \\ z \end{bmatrix} = \begin{bmatrix} w \\ t \\ \operatorname{void} \end{bmatrix} $$ Remember, that (w,t) vector is not normalized after transform.|