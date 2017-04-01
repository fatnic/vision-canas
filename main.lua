Wall = require 'wall'

local width = love.graphics:getWidth()
local height = love.graphics:getHeight()

local wall_list = {
    { 20*16, 10*16, 64, 16 },
    { 20*16, 20*16, 64, 16 },
    { 20*16, 25*16, 64, 16 },
    { 20*16, 30*16, 64, 16 },
    { 20*16, 35*16, 64, 16 },
    { 20*16, 40*16, 64, 16 },
    { 28*16, 10*16, 16, 30*16 },
}

local walls = {}
local rays = {}
local shadowLength = 20000

local origin = { x = 50, y = 50 }
local visDistance = 400
local heading = 0
local fov = 90
local minFov = nil 
local maxFov = nil

local target = { x = 300, y = 300 }

function distStencil()
    love.graphics.arc('fill', origin.x, origin.y, visDistance, maxFov, minFov)
end

function visStencil()
    love.graphics.setBlendMode('alpha', 'premultiplied')
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(shadows)
end

function dot(v0, v1)
    return v0.x * v1.x + v0.y * v1.y
end

function normaliseRadian(rad)
    local result = rad % (2 * math.pi)
    if result < 0 then result = result + (2 * math.pi) end
    return result
end

function ternary(cond, t, f)
    if cond then return t else return f end
end

function love.load()
    shadows = love.graphics.newCanvas(width, height)
    bg = love.graphics.newImage('bg.jpg')

    for _, wall in pairs(wall_list) do
        table.insert(walls, Wall.new(unpack(wall)))
    end
end

function love.update(dt)
    love.window.setTitle(love.timer.getFPS() .. ' fps')

    for _, wall in pairs(walls) do

        local points = {}

        for _, segment in pairs(wall.segments) do
            local ray = {}
            ray.target = segment.a
            ray.angle = math.atan2(segment.a.y - origin.y, segment.a.x - origin.x)
            ray.delta = { x = math.cos(ray.angle), y = math.sin(ray.angle) }
            local d = dot(ray.delta, segment.n)
            segment.facing = ternary(d < 0, true, false)
            segment.ray = ray
        end

        local t_segments = #wall.segments

        for i=1, t_segments do
            local nxt = i + 1
            if nxt > t_segments then nxt = 1 end

            local cfacing = wall.segments[i].facing
            local nfacing = wall.segments[nxt].facing
            
            if cfacing and nfacing then
                table.insert(points, wall.segments[i].b)
            end

            if cfacing and not nfacing then 
                table.insert(points, wall.segments[i].b)
                local sx = wall.segments[nxt].a.x + wall.segments[nxt].ray.delta.x * shadowLength
                local sy = wall.segments[nxt].a.y + wall.segments[nxt].ray.delta.y * shadowLength
                table.insert(points, { x = sx, y = sy })
            end

            if not cfacing and not nfacing then
                local sx = wall.segments[nxt].a.x + wall.segments[nxt].ray.delta.x * shadowLength
                local sy = wall.segments[nxt].a.y + wall.segments[nxt].ray.delta.y * shadowLength
                table.insert(points, { x = sx, y = sy })
            end

            if not cfacing and nfacing then
                local sx = wall.segments[nxt].a.x + wall.segments[nxt].ray.delta.x * shadowLength
                local sy = wall.segments[nxt].a.y + wall.segments[nxt].ray.delta.y * shadowLength
                table.insert(points, { x = sx, y = sy })
                table.insert(points, wall.segments[nxt].a)
            end

        end

        wall.shadowpoints = {}
        --
        for _, p in pairs(points) do
            table.insert(wall.shadowpoints, p.x)
            table.insert(wall.shadowpoints, p.y)
        end

    end

    minFov = heading - normaliseRadian(math.rad(fov / 2))
    maxFov = heading + normaliseRadian(math.rad(fov / 2))

end

function love.mousemoved(x, y)
    origin.x = x
    origin.y = y
end

function love.keypressed(key)
    if key == 'up' then visDistance = visDistance + 5 end
    if key == 'down' then visDistance = visDistance - 5 end

    if key == 'left' then fov = fov + 2 end
    if key == 'right' then fov = fov - 2 end

    if key == 'q' then heading = normaliseRadian(heading - 0.2) end
    if key == 'w' then heading = normaliseRadian(heading + 0.2) end
end

function love.draw()

    love.graphics.setCanvas(shadows)
        love.graphics.clear(255, 255, 255)
        love.graphics.stencil(distStencil, 'replace', 1)
        love.graphics.setStencilTest('equal', 1)
        love.graphics.setColor(255, 255, 255)
        love.graphics.rectangle('fill', 0, 0, width, height)
        love.graphics.setColor(0, 0, 0)
        for _, wall in pairs(walls) do
            love.graphics.polygon('fill', wall.shadowpoints) 
        end
        love.graphics.setStencilTest('equal', 0)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle('fill', 0, 0, width, height)
        love.graphics.setStencilTest()
    love.graphics.setCanvas()

    love.graphics.setBackgroundColor(51, 51, 51)

    love.graphics.setColor(255, 255, 255)
    love.graphics.setBlendMode('alpha')
    love.graphics.draw(bg, 0, 0, 0, 2, 2)

    love.graphics.setBlendMode('multiply', 'premultiplied')
    love.graphics.setColor(255, 255, 255, 100)
    love.graphics.draw(shadows)
    --
    -- love.graphics.setColor(255, 255, 255)
    -- love.graphics.stencil(visStencil, 'replace', 1)
    -- love.graphics.setStencilTest('equal', 0)
    -- love.graphics.circle('fill', origin.x, origin.y, visDistance)
    -- love.graphics.setStencilTest()

    love.graphics.setBlendMode('alpha')
    for _, wall in pairs(walls) do
        love.graphics.setColor(0, 255, 0, 100)
        love.graphics.rectangle('fill', wall.x, wall.y, wall.width, wall.height)
    end

    -- love.graphics.setColor(0, 255, 0, 100)
    -- love.graphics.circle('fill', origin.x, origin.y, 4)
    --

    -- local vr, vg, vb, va = shadows:getPixel(target.x, target.y)
    -- local tc = ternary(va > 0, {255,0,0}, {0,255,0})

    -- love.graphics.setColor(tc)
    -- love.graphics.circle('fill', target.x, target.y, 5)
end
