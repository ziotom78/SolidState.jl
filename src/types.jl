export Vec3d, vec3d, norm2, norm, Ray, ray_at_dist

import Base: show

################################################################################

"A 3-D vector. Use `vec3d` to create instances of this object"
const Vec3d = StaticVector{3, Float64}

"""
    vec3d(x, y, z)

Create a `Vec3d` object
"""
vec3d(x, y, z) = SVector{3, Float64}(x, y, z)

"""
    norm2(v::Vec3d)

Squared length of the vector. It is faster to compute than the length, since
no squared-root operation is required.

# Example
```jldoctest
julia> norm2(vec3d(1, 0, 0))
1.0
julia> norm2(vec3d(3, 1, 2))
14.0
```
"""
norm2(v::Vec3d) = v[1]^2 + v[2]^2 + v[3]^2

################################################################################

"""
    struct Ray

A ray originating from some point and having a direction. The direction
is always normalized. It contains the following fields:
- `origin`
- `dir`

You can compute the point reached by the ray after some time `t` with the
function `ray_at_dist`. This can be short-handed using the ray as a function:
```jldoctest
julia> r = Ray(vec3d(0, 0, 0), vec3d(1, 0, 0));
julia> ray_at_dist(r, 10) ≈ r(10)
true
```
"""
struct Ray
    "Point where the ray originates"
    origin::Vec3d
    "Normalized direction of the ray"
    dir::Vec3d

    Ray(o, d) = new(o, normalize(d))
end

function show(io::IO, r::Ray)
    println(string("Ray([$(r.origin[1]), $(r.origin[2]), $(r.origin[3])] + ",
                   "t * [$(r.dir[1]), $(r.dir[2]), $(r.dir[3])]"))
end

"""
    ray_at_dist(ray::Ray, dist::Number)

Return the point (a `Vec3d` type) reached by the ray after having
travelled a distance `dist`.
"""
ray_at_dist(ray::Ray, dist::Number) = ray.origin + dist * ray.dir

(r::Ray)(dist::Number) = ray_at_dist(r, dist)
