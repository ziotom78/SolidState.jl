export intersect, renderscene!

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
        for x in 1:width
            ray = cast_ray(camera, x, y, width, height)

            closest_dist = zero(Float64)
            closest_shape = 0
            closest_loc_ray = ray
            firsthit = true
            for i in eachindex(shapes)
                loc_ray = transform(shapes[i]) * ray
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
