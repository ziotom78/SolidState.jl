export TransfMatrix
export rotatex, rotatey, rotatez, rotate
export translate, scalex, scaley, scalez
export apply_transform

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
