export Vec3d, vec3d, norm2, norm, Ray, ray_at_dist

"A 3-D vector"
const Vec3d = StaticVector{3, Float64}

"""
    vec3d(x, y, z)

Create a `Vec3d` object
"""
vec3d(x, y, z) = SVector{3, Float64}(x, y, z)

norm2(v::Vec3d) = v[1]^2 + v[2]^2 + v[3]^2

"""
A ray originating from some point and having a direction. The direction
is always normalized.
"""
struct Ray
    origin::Vec3d
    dir::Vec3d

    Ray(o, d) = new(o, normalize(d))
end

ray_at_dist(ray::Ray, dist::Number) = ray.origin + dist * ray.dir
