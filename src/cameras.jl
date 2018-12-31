export Camera, PerspectiveCamera, OrthoCamera
export xy_to_uv, uv_to_xy, cast_ray, project_point

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

################################################################################

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

################################################################################

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

################################################################################

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
