"""

Set the color for drawing operations on `window`.

"""
setcolor!(window::Window, r::Int, g::Int, b::Int, a::Int) = SDL.SetRenderDrawColor(window.render_ptr, r, g, b, a)
setcolor!(window::Window, color::Colors.Color) = setcolor!(window, round(Int, color.r * 255), round(Int, color.g * 255), round(Int, color.b * 255), round(Int, color.alpha * 255))
setcolor!(window::Window, color::Colors.Color3) = setcolor!(window, color, 255)
setcolor!(window::Window, color::Colors.Color3, a::Int) = setcolor!(window, round(Int, color.r * 255), round(Int, color.g * 255), round(Int, color.b * 255), a)

"""

Fill `window` with the currently selected color.

"""
clear!(window::Window) = SDL.RenderClear(window.render_ptr)

"""

render!(window::Window, texture::Texture, x, y, args...)

Render `texture` onto `window`'s surface with the texture centered at `x` and `y`.

"""
function render!(window::Window, texture::Texture{SDL.Texture}, x::Int, y::Int, θ::Float64 = 0.0, scale_x::Float64 = 1.0, scale_y::Float64 = 1.0, offset_x::Int = 0, offset_y::Int = 0, flip::Symbol = :none)
    center_x, center_y = (texture.center_x + offset_x)*scale_x, (texture.center_y + offset_y)*scale_y
    rect = SDL.Rect(round(Int, x - center_x), round(Int, y - center_y),
                    round(Int, texture.width*scale_x), round(Int, texture.height*scale_y))
    point = SDL.Point(round(Int, center_x), round(Int, center_y))
    flip = UInt32(flip === :horizontal ? SDL.FLIP_HORIZONTAL :
                  flip === :vertical ? SDL.FLIP_VERTICAL :
                  SDL.FLIP_NONE)
    GC.@preserve rect point SDL.RenderCopyEx(window.render_ptr, texture.ptr,
                                             C_NULL, pointer_from_objref(rect),
                                             θ, pointer_from_objref(point),
                                             flip)
    return window
end

function render!(window::Window, layer::AbstractLayer, r::RenderTask{<:Texture})
    x = r.x*layer.scale + layer.x
    y = r.y*layer.scale + layer.y
    scale = layer.scale*r.scale
    render!(window, r.source, round(Int, x), round(Int, y), r.θ, scale, scale, r.offset_x, r.offset_y, r.flip)
end

"""
"""
function drawrect!(window::Window, x::Int, y::Int, w::Int, h::Int)
    rect = SDL.Rect(x, y, w, h)
    GC.@preserve rect SDL.RenderDrawRect(window.render_ptr, pointer_from_objref(rect))
    return window
end

"""
"""
function fillrect!(window::Window, x::Int, y::Int, w::Int, h::Int)
    rect = SDL.Rect(x, y, w, h)
    GC.@preserve rect SDL.RenderFillRect(window.render_ptr, pointer_from_objref(rect))
    return window
end

"""
"""
drawline!(window::Window, x1::Int, y1::Int, x2::Int, y2::Int) = SDL.RenderDrawLine(window.render_ptr, Int32(x1), Int32(y1), Int32(x2), Int32(y2))

drawline!(window::Window, l::Line) = drawline!(window, round(Int, l.x1), round(Int, l.y1), round(Int, l.x2), round(Int, l.y2))

"""
"""
drawpoint!(window::Window, (x, y)::Tuple{Int,Int}) = SDL.RenderDrawPoint(window.render_ptr, Int32(x), Int32(y))

"""
"""
present!(window::Window) = SDL.RenderPresent(window.render_ptr)

function render!(layer::Layer, texture::Texture, x, y, θ = 0.0; scale = 1.0, offset_x = 0, offset_y = 0, flip::Symbol = :none)
    push!(layer.render_tasks, RenderTask(texture, x, y, θ, scale, offset_x, offset_y, flip))
    return layer
end
