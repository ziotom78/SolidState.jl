using SolidState
using LinearAlgebra
using StaticArrays
using Test

# types.jl

@test vec3d(1, 0, 0) ⋅ vec3d(0, 1, 0) ≈ 0
@test vec3d(2, 1, 3) ⋅ vec3d(2, 1, 3) ≈ 14
@test vec3d(1, 0, 0) × vec3d(0, 1, 0) ≈ vec3d(0, 0, 1)

@test norm2(vec3d(1, 0, 0)) ≈ 1
@test norm2(vec3d(1, 2, 3)) ≈ 14

# transformations.jl

@test rotate(π/6, vec3d(1, 0, 0)) ≈ rotatex(π/6)
@test rotate(π/6, vec3d(0, 1, 0)) ≈ rotatey(π/6)
@test rotate(π/6, vec3d(0, 0, 1)) ≈ rotatez(π/6)

@test translate(0.1, 0.2, 0.3) ≈ translate(vec3d(0.1, 0.2, 0.3))
@test translate(1, 0, 0) * translate(0, 2, 0) * translate(0, 0, 3) ≈ translate(1, 2, 3)

@test scalex(2) * scaley(3) * scalez(4) ≈ SMatrix{4, 4, Float64}([2 0 0 0;
                                                                  0 3 0 0;
                                                                  0 0 4 0;
                                                                  0 0 0 1])
ray = apply_transform(Ray(vec3d(0, 0, 0), vec3d(1, 0, 0)), rotatey(π/2))
@test ray.origin ≈ vec3d(0, 0, 0)
@test ray_at_dist(ray, 10) ≈ vec3d(0, 0, -10)

# cameras.jl

(u, v) = xy_to_uv(127, 348, 1024, 768)
(x, y) = uv_to_xy(u, v, 1024, 768)
@test [x, y] ≈ [127.0, 348.0]

camera = PerspectiveCamera(vec3d(0, 0, -2), # Position
                           vec3d(0, 0, 0),  # Look at
                           vec3d(0, 1, 0),  # Up
                           vec3d(1, 0, 0))  # Right

x, y, visible = project_point(camera, vec3d(0, 0, 0), 1024, 768)
@test x ≈ 1024 / 2
@test y ≈ 768 / 2
@test visible

x, y, visible = project_point(camera, vec3d(0, 0, -2), 1024, 768)
@test !visible

camera = OrthoCamera(vec3d(0, 0, -2), # Position
                     vec3d(0, 1, 0),  # Up
                     vec3d(1, 0, 0))  # Right

x, y, visible = project_point(camera, vec3d(0, 0, 0), 1024, 768)
@test x ≈ 1024 / 2
@test y ≈ 768 / 2
@test visible
