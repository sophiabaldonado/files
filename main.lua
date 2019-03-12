local files = {}
local fs = lovr.filesystem

function lovr.load()
	itemSize = .6
	files = fs.getDirectoryItems('saved/')
	model = lovr.graphics.newModel('file.glb')
	scroll = 0
	scrollSpacing = 0
	numFilesToDisplay = 3

	transform = lovr.math.mat4()
	local hx, hy, hz = lovr.headset.getPosition()
	local angle, ax, ay, az = lovr.math.lookAt(hx, 0, hz, hx - .5, 0, hz - .5)
	transform:identity()
	transform:translate(hx - .5, 0, hz - 1.5)
	transform:rotate(angle, ax, ay, az)
end

function lovr.draw()
	lovr.graphics.push()
	lovr.graphics.transform(transform)

	for i, file, x, y in items() do
		if (i - scroll) > 0 and i <= scroll + numFilesToDisplay then
			y = y + scrollSpacing
			local model = model
			local minx, maxx, miny, maxy, minz, maxz = model:getAABB()
			local width, height, depth = maxx - minx, maxy - miny, maxz - minz
			local scale = itemSize / math.max(width, height, depth)
			local cx, cy, cz = (minx + maxx) / 2 * scale, (miny + maxy) / 2 * scale, (minz + maxz) / 2 * scale
			lovr.graphics.setColor(.2, .1, .3, .5)
			model:draw(x - cx, y - cy, 0 - cz, scale, (3 * math.pi) / 2, 0, 1, 0)

			lovr.graphics.setColor(1, 1, 1)
			lovr.graphics.print(string.gsub(file, '.json', ''), x - cx + .1, y - cy, 0 - cz + .02, scale * .6)
		end
	end

	lovr.graphics.pop()
end

function lovr.controllerpressed(...)
	local controller, button = ...
	if button == 'trigger' then
		moveUp()
	elseif button == 'grip' then
		moveDown()
	end
end

function moveUp()
	if (scroll + 1) > (#files - numFilesToDisplay) then return end

	scroll = scroll + 1
	scrollSpacing = scrollSpacing + (itemSize * .3)
end

function moveDown()
	if (scroll - 1) <= 0 then return end

	scroll = scroll - 1
	scrollSpacing = scrollSpacing - (itemSize * .3)
end

function items()
	local count = #files
	local xspacing = itemSize * 1.35
	local yspacing = itemSize * .3
	local perRow = 1--math.ceil(math.sqrt(count))
	local rows = math.ceil(count / perRow)
	local i = 0

	return function()
		i = i + 1
		local file = files[i]
		if not file then return end
		local col = 1-- + ((i - 1) % perRow)
		local row = math.ceil(i / perRow)
		local x = -xspacing * (perRow - 1) / 2 + xspacing * (col - 1)
		local y = yspacing * (rows - 1) / 2 - yspacing * (row - 1)
		return i, file, x, y
	end
end

return files