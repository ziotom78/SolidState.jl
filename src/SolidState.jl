module SolidState

export Vec3d, vec3d
export TransfMatrix
export rotatex, rotatey, rotatez, rotate
export translate, scalex, scaley, scalez
export Camera, xy_to_uv, uv_to_xy
export PerspectiveCamera, OrthoCamera, cast_ray, project_point
export Material, UniformMaterial, TexturedMaterial, AATexturedMaterial
export ShapeProperties, material, transform, inv_transform
export Shape, Sphere
export renderscene!

using ColorTypes
using Images
using Interpolations: LinearInterpolation
using LinearAlgebra
using Printf
using StaticArrays

################################################################################

"A 3-D vector"
const Vec3d = StaticVector{3, Float64}

"""
    vec3d(x, y, z)

Create a `Vec3d` object
"""
vec3d(x, y, z) = SVector{3, Float64}(x, y, z)

norm2(v::Vec3d) = v[1]^2 + v[2]^2 + v[3]^2
norm(v::Vec3d) = sqrt(norm2(v))

"""
A ray originating from some point and having a direction. The direction
is always normalized.
"""
struct Ray
    origin::Vec3d
    dir::Vec3d

    Ray(o, d) = new(o, normalize(d))
end

################################################################################

"A homogeneous transformation matrix"
const TransfMatrix = StaticMatrix{4, 4, Float64}

"""
    rotatex(angle)
    rotatey(angle)
    rotatez(angle)

Return a `TransfMatrix` representing a rotation around one of the x, y, z axes.
The angle is expressed in radians.
"""
rotatex(angle) = SMatrix{4, 4, Float64}([1 0 0 0;
                                         0 cos(angle) -sin(angle) 0;
                                         0 sin(angle) cos(angle) 0;
                                         0 0 0 1])
rotatey(angle) = SMatrix{4, 4, Float64}([cos(angle) 0 sin(angle) 0;
                                         0 1 0 0;
                                         -sin(angle) 0 cos(angle) 0;
                                         0 0 0 1])
rotatez(angle) = SMatrix{4, 4, Float64}([cos(angle) -sin(angle) 0 0;
                                         sin(angle) cos(angle) 0 0;
                                         0 0 1 0;
                                         0 0 0 1])

"""
    rotate(angle, axis)

Return a `TransfMatrix` representing a rotation around an arbitrary angle. The
axis `axis` is assumed to have length one, and `angle` must be expressed in
radians.
"""
function rotate(angle, axis)
    cs, sn = cos(angle), sin(angle)
    ux, uy, uz = axis[1], axis[2], axis[3]
    SMatrix{4, 4, Float64}(
        cs + ux^2 * (1 - cs),
        uy * ux * (1 - cs) + uz * sn,
        uz * ux * (1 - cs) - uy * sn,
        0,
        ux * uy * (1 - cs) - uz * sn,
        cs + uy^2 * (1 - cs),
        uz * uy * (1 - cs) + ux * sn,
        0,
        ux * uz * (1 - cs) + uy * sn,
        uy * uz * (1 - cs) - ux * sn,
        cs + uz^2 * (1 - cs),
        0,
        0, 0, 0, 1,
    )
end

translate(x, y, z) = SMatrix{4, 4, Float64}([1 0 0 x;
                                             0 1 0 y;
                                             0 0 1 z;
                                             0 0 0 1])
scalex(f) = SMatrix{4, 4, Float64}([f 0 0 0;
                                    0 1 0 0;
                                    0 0 1 0;
                                    0 0 0 1])
scaley(f) = SMatrix{4, 4, Float64}([1 0 0 0;
                                    0 f 0 0;
                                    0 0 1 0;
                                    0 0 0 1])
scalez(f) = SMatrix{4, 4, Float64}([1 0 0 0;
                                    0 1 0 0;
                                    0 0 f 0;
                                    0 0 0 1])

translate(v::Vec3d) = translate(v[1], v[2], v[3])

function apply_transform(r::Ray, tr::TransfMatrix)

    # The origin point should be translated too
    neworig = vec3d(tr[1, 1] * r.origin[1] +
                    tr[1, 2] * r.origin[2] +
                    tr[1, 3] * r.origin[3] +
                    tr[1, 4],
                    tr[2, 1] * r.origin[1] +
                    tr[2, 2] * r.origin[2] +
                    tr[2, 3] * r.origin[3] +
                    tr[2, 4],
                    tr[3, 1] * r.origin[1] +
                    tr[3, 2] * r.origin[2] +
                    tr[3, 3] * r.origin[3] +
                    tr[3, 4])

    # Leave the translation off for the direction
    newdir = vec3d(tr[1, 1] * r.dir[1] +
                    tr[1, 2] * r.dir[2] +
                    tr[1, 3] * r.dir[3],
                    tr[2, 1] * r.dir[1] +
                    tr[2, 2] * r.dir[2] +
                    tr[2, 3] * r.dir[3],
                    tr[3, 1] * r.dir[1] +
                    tr[3, 2] * r.dir[2] +
                    tr[3, 3] * r.dir[3])

    Ray(neworig, newdir)
end

ray_at_dist(ray::Ray, dist::Number) = ray.origin + dist * ray.dir

abstract type Camera end

mutable struct PerspectiveCamera <: Camera
    position::Vec3d
    up::Vec3d
    right::Vec3d
    dir::Vec3d

    PerspectiveCamera(pos, look_at, up, right) = new(pos, up, right,
                                                     normalize(look_at - pos))
end

mutable struct OrthoCamera <: Camera
    position::Vec3d
    up::Vec3d
    right::Vec3d
    dir::Vec3d

    OrthoCamera(pos, up, right) = new(pos, up, right, right × up)
end

"""
    normalize_coord(x, span)

Assuming that `x` runs in the range [1, `span`], apply a linear
transformation to `x` so that the result runs from -1 to +1.
"""
function normalize_coord(x, span)
    span == 1 && return 0.0
    
    2(x - 1 + 0.5) / (span - 1) - 1
end

xy_to_uv(x, y, width, height) = (width / height * normalize_coord(x, width),
                                 normalize_coord(y, height))

uv_to_xy(u, v, width, height) = (((height / width * u + 1) * (width - 1) + 1) / 2,
                                 ((v + 1) * (height - 1) + 1) / 2)

"""
    cast_ray(camera::PerspectiveCamera, x, y, width, height)

Cast a ray starting from the camera along the direction `(x, y)`,
where both `x` and `y` are pure numbers in the range [1, width] × [1,
height]. Return a ray (a `Vec3d` object) of length one.
"""
function cast_ray(camera::PerspectiveCamera, x, y, width, height)
    u, v = xy_to_uv(x, y, width, height)
    dir = camera.dir + u * camera.right + v * camera.up

    Ray(camera.position, dir)
end

"""
    project_point(camera::PerspectiveCamera, pt, width, height)

Project a 3D point into the camera frame. Return a 3-element tuple
representing the coordinates ``(x, y)`` of a point ``P`` on the screen
and a Boolean value indicating whether the point ``P`` is in the range
`[1, width] × [1, height]` or not (visibility).

Both ``x`` and ``y`` are floating-point numbers.
"""
function project_point(camera::PerspectiveCamera, pt, width, height)
    # Direction from the camera to the point to project on the screen
    dir = pt - camera.position
    plane_center = camera.position + camera.dir

    # Check that the direction is not perpendicular to the viewing direction
    dotprod = camera.dir ⋅ dir
    abs(dotprod) < 1e-7 && return (0.0, 0.0, false)

    # Distance between P (on the screen plane) and the observer, along `dir`
    t = norm2(camera.dir) / dotprod

    # Point on the screen (3D coordinates)
    pt_on_screen = t * dir - camera.dir

    # Project the point on a (u, v) coordinate system, where both `u`
    # and `v` are in the range [-1, 1]    
    (u, v) = (pt_on_screen ⋅ camera.right, pt_on_screen ⋅ camera.up)
    (x, y) = uv_to_xy(u, v, width, height)
    
    return (x, y, 1 ≤ x ≤ width && 1 ≤ y ≤ height && t > 0)
end

"""
    cast_ray(camera::OrthoCamera, x, y, width, height)

Cast a ray starting from the camera along the direction `(x, y)`,
where both `x` and `y` are pure numbers in the range [1, width] × [1,
height]. Return a ray (a `Vec3d` object) of length one.
"""
function cast_ray(camera::OrthoCamera, x, y, width, height)
    pos = (camera.position +
           width / height * normalize_coord(x, width) * camera.right +
           normalize_coord(y, height) * camera.up)

    Ray(pos, camera.dir)
end

function project_point(camera::OrthoCamera, pt, width, height)
    # For orthogonal cameras, we trace the ray in the inverse
    # direction: from the point `pt` backwards to the
    # plane. Therefore, the ray would be `Ray(pt, -camera.dir)`.

    t = (pt - camera.position) ⋅ camera.dir / norm2(camera.dir)
    pt_on_screen = pt - t * camera.dir

    # Project the point on a (u, v) coordinate system, where both `u`
    # and `v` are in the range [-1, 1]    
    (u, v) = (pt_on_screen ⋅ camera.right, pt_on_screen ⋅ camera.up)
    (x, y) = uv_to_xy(u, v, width, height)
    
    return (x, y, 1 ≤ x ≤ width && 1 ≤ y ≤ height && t > 0)
end

################################################################################

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

################################################################################

mutable struct ShapeProperties
    material::Material
    transf::TransfMatrix
    invtransf::TransfMatrix

    ShapeProperties(mat) = new(mat,
                               SMatrix{4, 4}(Matrix{Float64}(I, 4, 4)),
                               SMatrix{4, 4}(Matrix{Float64}(I, 4, 4)))
    ShapeProperties(mat, transf) = new(mat, transf, inv(transf))
end



abstract type Shape end
material(s::Shape) = s.prop.material
transform(s::Shape) = s.prop.transf
inv_transform(s::Shape) = s.prop.invtransf

mutable struct Sphere <: Shape
    center::Vec3d
    radius::Float64
    prop::ShapeProperties

    Sphere(c, r, mat) = new(c, r, ShapeProperties(mat))
    Sphere(c, r, mat, transf) = new(c, r, ShapeProperties(mat, transf))
end

"""
    normal(pt::Vec3d, sphere::Sphere)

Given a point `pt` on the surface of the sphere, return a `Vec3d`
object containing the normalize outward vector outwards the surface at
point `pt`.
"""
function normal(pt::Vec3d, sphere::Sphere)
    normalize(pt - sphere.center)
end

function getcolor(sphere::Sphere, point::Vec3d)
    normpoint = normalize(point - sphere.center)
    theta = acos(normpoint[3])
    phi = atan(normpoint[2], normpoint[1])
    getcolor(material(sphere), mod2pi(phi) / 2π, theta / π)
end

function intersect(ray::Ray, sphere::Sphere)
    oc = (ray.origin - sphere.center)

    a = ray.dir ⋅ ray.dir
    bhalf = oc ⋅ ray.dir
    c = oc ⋅ oc - sphere.radius^2
    Δ = bhalf^2 - a * c

    if Δ > 0
        sqrtΔ = sqrt(Δ)
        
        t1 = (-bhalf - sqrtΔ) / a
        if t1 > 0
            return t1
        end
        
        t2 = (-bhalf + sqrtΔ) / a
        if t2 > 0
            return t2
        end
    end

    return zero(Δ)
end

function renderscene!(camera, shapes, image; background=RGB{Float64}(0, 0, 0))
    height, width = size(image)
    for y in 1:height
        #println("y = $y")
        for x in 1:width
            ray = cast_ray(camera, x, y, width, height)

            closest_dist = zero(Float64)
            closest_shape = 0
            closest_loc_ray = ray
            firsthit = true
            for i in eachindex(shapes)
                loc_ray = apply_transform(ray, inv_transform(shapes[i]))
                cur_dist = intersect(loc_ray, shapes[i])
                if cur_dist > 0 && (firsthit || cur_dist < closest_dist)
                    closest_loc_ray = loc_ray
                    closest_dist = cur_dist
                    closest_shape = i
                    firsthit = false
                end
            end
            
            image[height - y + 1, x] = if closest_shape == 0
                background
            else
                getcolor(shapes[closest_shape], ray_at_dist(closest_loc_ray, closest_dist))
            end
        end
    end
end

end # module
