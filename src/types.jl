export Vec3d, vec3d, norm2, norm, Ray, ray_at_dist

import Base: show

################################################################################

"A 3-D vector"
const Vec3d = StaticVector{3, Float64}

"""
    vec3d(x, y, z)

Create a `Vec3d` object
"""
vec3d(x, y, z) = SVector{3, Float64}(x, y, z)

norm2(v::Vec3d) = v[1]^2 + v[2]^2 + v[3]^2

################################################################################

"""
A ray originating from some point and having a direction. The direction
is always normalized.
"""
struct Ray
    origin::Vec3d
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
