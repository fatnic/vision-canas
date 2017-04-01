Wall = {}

function Wall.new(x, y, w, h)
    wall = {}

    wall.x = x
    wall.y = y
    wall.width = w
    wall.height = h

    wall.visible = true

    wall.segments = {}
    table.insert(wall.segments, { a = { x = x, y = y }, b = { x = x + w, y = y }, n = { x = 0, y = -1 }})
    table.insert(wall.segments, { a = { x = x + w, y = y }, b = { x = x + w, y = y + h }, n = { x = 1, y = 0 } })
    table.insert(wall.segments, { a = { x = x + w, y = y + h }, b = { x = x, y = y + h }, n = { x = 0, y = 1 } })
    table.insert(wall.segments, { a = { x = x, y = y + h }, b = { x = x, y = y }, n = { x = -1, y = 0 } })

    wall.points = {}
    for _, segment in pairs(wall.segments) do
        table.insert(wall.points, segment.a)
    end

    return wall
end

return Wall
