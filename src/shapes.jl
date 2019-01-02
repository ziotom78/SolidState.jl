export ShapeProperties, material, transform
export Shape, normal, getcolor
export Sphere

mutable struct ShapeProperties
    material::Material
    transf::TransfMatrix

    ShapeProperties(mat) = new(mat, TransfMatrix())
    ShapeProperties(mat, transf) = new(mat, transf)
end



abstract type Shape end
material(s::Shape) = s.prop.material
transform(s::Shape) = s.prop.transf

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
