export Material, UniformMaterial, TexturedMaterial, AATexturedMaterial
export getcolor

abstract type Material end

"""
    struct UniformMaterial <: Material

A uniform-looking material.

# Initialization

    UniformMaterial(r, g, b)

Initialize the material with a color whose red, green, and blue components
are `r`, `g`, `b`. All the three values must be in the range ``[0, 1]``.

# Examples

```julia
texture = SolidState.UniformMaterial(0.5, 0.5, 0.1)
```
"""
struct UniformMaterial <: Material
    color::RGB{Float64}

    UniformMaterial(r, g, b) = new(RGB{Float64}(r, g, b))
end

getcolor(mat::UniformMaterial, u, v) = mat.color

################################################################################

"""
    struct TexturedMaterial <: Material

A textured material, mapping a bitmap to a ``(u, v)`` grid in the domain
``[0, 1] \times [0, 1]``.

If you are looking for an anti-aliased textured material, use
`AATexturedMaterial`: it produce good-looking results even for
low-resolution bitmaps, at the expense of more calculations.

# Initialization

    TexturedMaterial(img::Array{RGB{Float64}, 2})

Initialize the texture with a bitmap.

    TexturedMaterial(fname::AbstractString)

Initialize the texture with a bitmap loaded from a file with name
`fname`. All the image types implemented in the
[Images.jl](https://github.com/JuliaImages/Images.jl) package are
recognized.

# Examples

```julia
texture = SolidState.TexturedMaterial("picture.jpg")
```
"""
struct TexturedMaterial <: Material
    texture::Array{RGB{Float64}, 2}

    TexturedMaterial(img::Array{RGB{Float64}, 2}) = new(img)
    TexturedMaterial(fname::AbstractString) = new(convert.(RGB{Float64},
                                                           Images.load(fname)))
end

function getcolor(mat::TexturedMaterial, u, v)
    height, width = size(mat.texture)
    mat.texture[round(Int, height - v * (height - 1)),
                round(Int, u * (width - 1) + 1)]
end

################################################################################

interp_texture(img) = LinearInterpolation((1:size(img)[1], 1:size(img)[2]), img)

"""
    struct AATexturedMaterial <: Material

An anti-aliased textured material, mapping a bitmap to a ``(u, v)`` grid in
the domain ``[0, 1] \times [0, 1]``.

Use `TexturedMaterial` if your textures are high-resolution, as it is faster.
Anti-aliasing only helps when the resolution of textures are so low that the
rendered object looks pixelated.

# Initialization

    AATexturedMaterial(img::Array{RGB{Float64}, 2})

Initialize the texture with a bitmap.

    AATexturedMaterial(fname::AbstractString)

Initialize the texture with a bitmap loaded from a file with name
`fname`. All the image types implemented in the
[Images.jl](https://github.com/JuliaImages/Images.jl) package are
recognized.

# Examples

```julia
texture = SolidState.AATexturedMaterial("picture.jpg")
```
"""
struct AATexturedMaterial <: Material
    texture

    AATexturedMaterial(img::Array{RGB{Float64}, 2}) = new(interp_texture(img))
    AATexturedMaterial(fname::AbstractString) = new(interp_texture(convert.(RGB{Float64},
                                                                            Images.load(fname))))
end

function getcolor(mat::AATexturedMaterial, u, v)
    height, width = size(mat.texture)
    mat.texture(height - v * (height - 1), u * (width - 1) + 1)
end
