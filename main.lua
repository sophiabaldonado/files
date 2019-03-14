local files = {}
local fs = lovr.filesystem
local flux = require 'flux'

function lovr.load()
	itemSize = .6
	model = lovr.graphics.newModel('file.glb')
	files = fs.getDirectoryItems('saved/')

	scroll = 0
	scrollSpacing = { y = 0 }
	numFilesToDisplay = 3

	opacities = {}
	for i, file in ipairs(files) do
		if i <= numFilesToDisplay then
			opacities[file] = { a = 1 }
		else
			opacities[file] = { a = 0}
		end
	end
	upperEdge = nil
	lowerEdge = nil
	nextUpperEdge = nil
	nextLowerEdge = nil

	transform = lovr.math.mat4()
	local hx, hy, hz = lovr.headset.getPosition()
	local angle, ax, ay, az = lovr.math.lookAt(hx, 0, hz, hx - .5, 0, hz - .5)
	transform:identity()
	transform:translate(hx - .5, 0, hz - 1.5)
	transform:rotate(angle, ax, ay, az)
end

function lovr.update(dt)
	flux.update(dt)

	for i, file, x, y in items() do
		if (i - scroll) == 1 then
			setUpperEdges(file, files[1 - 1])
		end
		if i == scroll + numFilesToDisplay + 1 then
			setLowerEdges(file, files[1 + 1])
		end
	end
end

function setUpperEdges(file, prevFile)
	if file ~= upperEdge then
		upperEdge = file
	end
	if prevFile and prevFile ~= nextUpperEdge then
		nextUpperEdge = prevFile
	end
end

function setLowerEdges(file, nextFile)
	if file ~= lowerEdge then
		lowerEdge = file
	end
	if nextFile and nextFile ~= nextLowerEdge then
		nextLowerEdge = nextFile
	end
end

function lovr.draw()
	lovr.graphics.push()
	lovr.graphics.transform(transform)

	for i, file, x, y in items() do
		local a = .5
		local zOff = 0
		if (i - scroll) > 0 and i <= scroll + numFilesToDisplay then
			a = 1
			zOff = .05
		end

		y = y + scrollSpacing.y
		local model = model
		local minx, maxx, miny, maxy, minz, maxz = model:getAABB()
		local width, height, depth = maxx - minx, maxy - miny, maxz - minz
		local scale = itemSize / math.max(width, height, depth)
		local cx, cy, cz = (minx + maxx) / 2 * scale, (miny + maxy) / 2 * scale, (minz + maxz) / 2 * scale
		lovr.graphics.setColor(.2, .1, .3, opacities[file].a)
		model:draw(x - cx, y - cy, 0 - cz + zOff, scale, (3 * math.pi) / 2, 0, 1, 0)

		lovr.graphics.setColor(1, 1, 1, a - .2)
		lovr.graphics.print(string.gsub(file, '.json', ''), x - cx + .1, y - cy, 0 - cz + .02 + zOff, scale * .6)
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

	transitionUp()

	scroll = scroll + 1
	flux.to(scrollSpacing, .5, { y = scrollSpacing.y + (itemSize * .3) }):ease('cubicout')
end

function moveDown()
	if (scroll - 1) < 0 then return end

	transitionDown()

	scroll = scroll - 1
	flux.to(scrollSpacing, .5, { y = scrollSpacing.y - (itemSize * .3) }):ease('cubicout')
	-- scrollSpacing = scrollSpacing - (itemSize * .3)
end

function transitionUp()
	if opacities[upperEdge] then
		flux.to(opacities[upperEdge], .5, { a = 0 }):ease('cubicout')
	end
	if opacities[nextLowerEdge] then
		flux.to(opacities[nextLowerEdge], .5, { a = 1 }):ease('cubicout')
	end
end

function transitionDown()
	if opacities[nextUpperEdge] then
		flux.to(opacities[nextUpperEdge], .5, { a = 1 }):ease('cubicout')
	end
	if opacities[lowerEdge] then
		flux.to(opacities[lowerEdge], .5, { a = 0 }):ease('cubicout')
	end
end

function items()
	local count = #files
	local xspacing = itemSize * 1.35
	local yspacing = itemSize * .3
	local perRow = 1
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