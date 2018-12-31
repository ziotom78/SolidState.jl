using SolidState
using Test

@test rotate(π/6, vec3d(1, 0, 0)) ≈ rotatex(π/6)
@test rotate(π/6, vec3d(0, 1, 0)) ≈ rotatey(π/6)
@test rotate(π/6, vec3d(0, 0, 1)) ≈ rotatez(π/6)

@test translate(0.1, 0.2, 0.3) ≈ translate(vec3d(0.1, 0.2, 0.3))
@test translate(1, 0, 0) * translate(0, 2, 0) * translate(0, 0, 3) ≈ translate(1, 2, 3)

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
