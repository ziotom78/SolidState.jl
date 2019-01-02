export TransfMatrix
export rotatex, rotatey, rotatez, rotate
export translate
export scalex, scaley, scalez, scale

import Base: *, ≈, show

################################################################################
    
"""
    struct TransfMatrix

A homogeneous transformation matrix. It contains the following fields:
- `m`
- `invm`

The multiplication `*` operation is defined on pairs of `TransMatrix`
objects. You can also use the approximate comparison operator `≈`
(useful for tests).
"""
struct TransfMatrix
    "4×4 matrix representing the transformation"
    m::StaticMatrix{4, 4, Float64}
    "4×4 matrix representing the inverse of the transformation"
    invm::StaticMatrix{4, 4, Float64}

    TransfMatrix() = new(SMatrix{4, 4}(Matrix{Float64}(I, 4, 4)),
                         SMatrix{4, 4}(Matrix{Float64}(I, 4, 4)))
    TransfMatrix(m) = new(m, inv(m))
    TransfMatrix(m, invm) = new(m, invm)
end

Base.:*(tr1::TransfMatrix, tr2::TransfMatrix) = TransfMatrix(tr1.m * tr2.m,
                                                             tr2.invm * tr1.invm)

Base.:≈(tr1::TransfMatrix, tr2::TransfMatrix) = (tr1.m ≈ tr2.m) && (tr1.invm ≈ tr2.invm)

Base.show(io::IO, tr::TransfMatrix) = println("TransfMatrix($(tr.m))")

################################################################################

"""
    identity_transform()

Return a `TransfMatrix` object that represents the identity transformation,
i.e., no transformation at all.
"""
function identity_transform()
    TransfMatrix()
end

################################################################################

"""
    translate(x, y, z)

Return a `TransfMatrix` object that represents a translation operation by
`x`, `y`, and `z` along the three axes.
"""
translate(x, y, z) = TransfMatrix(
    SMatrix{4, 4, Float64}([1 0 0 x;
                            0 1 0 y;
                            0 0 1 z;
                            0 0 0 1]),
    SMatrix{4, 4, Float64}([1 0 0 -x;
                            0 1 0 -y;
                            0 0 1 -z;
                            0 0 0 1])
)

"""
    translate(v::Vec3d)

Return a `TransfMatrix` object that represents a translation operator by
vector `v`.
"""
translate(v::Vec3d) = translate(v[1], v[2], v[3])

################################################################################

rotatex(angle) = TransfMatrix(
    SMatrix{4, 4, Float64}([1 0 0 0;
                            0 cos(angle) -sin(angle) 0;
                            0 sin(angle) cos(angle) 0;
                            0 0 0 1]),
    SMatrix{4, 4, Float64}([1 0 0 0;
                            0 cos(-angle) -sin(-angle) 0;
                            0 sin(-angle) cos(-angle) 0;
                            0 0 0 1])
)
rotatey(angle) = TransfMatrix(
    SMatrix{4, 4, Float64}([cos(angle) 0 sin(angle) 0;
                            0 1 0 0;
                            -sin(angle) 0 cos(angle) 0;
                            0 0 0 1]),
    SMatrix{4, 4, Float64}([cos(-angle) 0 sin(-angle) 0;
                            0 1 0 0;
                            -sin(-angle) 0 cos(-angle) 0;
                            0 0 0 1])
)
rotatez(angle) = TransfMatrix(
    SMatrix{4, 4, Float64}([cos(angle) -sin(angle) 0 0;
                            sin(angle) cos(angle) 0 0;
                            0 0 1 0;
                            0 0 0 1]),
    SMatrix{4, 4, Float64}([cos(-angle) -sin(-angle) 0 0;
                            sin(-angle) cos(-angle) 0 0;
                            0 0 1 0;
                            0 0 0 1])
)

"""
    rotatex(angle)
    rotatey(angle)
    rotatez(angle)

Return a `TransfMatrix` representing a rotation around one of the x, y, z axes.
The angle is expressed in radians.
"""
rotatex, rotatey, rotatez

"""
    rotate(angle, axis)

Return a `TransfMatrix` representing a rotation around an arbitrary angle. The
axis `axis` is assumed to have length one, and `angle` must be expressed in
radians.
"""
function rotate(angle, axis)
    cs, sn = cos(angle), sin(angle)
    ux, uy, uz = axis[1], axis[2], axis[3]
    m = SMatrix{4, 4, Float64}(
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

    TransfMatrix(m, inv(m))
end

################################################################################

scalex(f) = TransfMatrix(
    SMatrix{4, 4, Float64}([f 0 0 0;
                            0 1 0 0;
                            0 0 1 0;
                            0 0 0 1]),
    SMatrix{4, 4, Float64}([1/f 0 0 0;
                            0 1 0 0;
                            0 0 1 0;
                            0 0 0 1])
)

scaley(f) = TransfMatrix(
    SMatrix{4, 4, Float64}([1 0 0 0;
                            0 f 0 0;
                            0 0 1 0;
                            0 0 0 1]),
    SMatrix{4, 4, Float64}([1 0 0 0;
                            0 1/f 0 0;
                            0 0 1 0;
                            0 0 0 1])
)

scalez(f) = TransfMatrix(
    SMatrix{4, 4, Float64}([1 0 0 0;
                            0 1 0 0;
                            0 0 f 0;
                            0 0 0 1]),
    SMatrix{4, 4, Float64}([1 0 0 0;
                            0 1 0 0;
                            0 0 1/f 0;
                            0 0 0 1])
)

"""
    scalex(f)
    scaley(f)
    scalez(f)

Return a `TransfMatrix` object that represents a scaling operation along
one of the three axes `x`, `y`, or `z`. Use `scale` if you want a generic
scaling operation along the three axes.
"""
scalex, scaley, scalez

"""
    scale(fx, fy, fz)

Return a `TransfMatrix` object that represents a scaling operation along
the three axes `x`, `y`, and `z`. Use `scalex`, `scaley`, and `scalez` if
you are only interested in scaling along *one* of the three axes.
"""
scale(fx, fy, fz) = TransfMatrix(
    SMatrix{4, 4, Float64}([fx 0 0 0;
                            0 fy 0 0;
                            0 0 fz 0;
                            0 0 0 1]),
    SMatrix{4, 4, Float64}([1/fx 0 0 0;
                            0 1/fy 0 0;
                            0 0 1/fz 0;
                            0 0 0 1])
)

################################################################################

*(tr::TransfMatrix, v::Vec3d) = tr.m[1:3, 1:3] * v

function *(tr::TransfMatrix, r::Ray)

    # The origin point should be translated too
    neworig = vec3d(tr.invm[1, 1] * r.origin[1] +
                    tr.invm[1, 2] * r.origin[2] +
                    tr.invm[1, 3] * r.origin[3] +
                    tr.invm[1, 4],
                    tr.invm[2, 1] * r.origin[1] +
                    tr.invm[2, 2] * r.origin[2] +
                    tr.invm[2, 3] * r.origin[3] +
                    tr.invm[2, 4],
                    tr.invm[3, 1] * r.origin[1] +
                    tr.invm[3, 2] * r.origin[2] +
                    tr.invm[3, 3] * r.origin[3] +
                    tr.invm[3, 4])

    # Leave the translation off for the direction
    newdir = vec3d(tr.invm[1, 1] * r.dir[1] +
                    tr.invm[1, 2] * r.dir[2] +
                    tr.invm[1, 3] * r.dir[3],
                    tr.invm[2, 1] * r.dir[1] +
                    tr.invm[2, 2] * r.dir[2] +
                    tr.invm[2, 3] * r.dir[3],
                    tr.invm[3, 1] * r.dir[1] +
                    tr.invm[3, 2] * r.dir[2] +
                    tr.invm[3, 3] * r.dir[3])

    Ray(neworig, newdir)
end
