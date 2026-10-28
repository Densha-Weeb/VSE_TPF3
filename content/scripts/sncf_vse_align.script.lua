local CHAIN_SEARCH_RADIUS = 140.0
local SAMPLES_PER_METRE = 1.0
local SAMPLES_MIN, SAMPLES_MAX = 8, 600

local MARGIN_M = 30.0
local WALK_MIN_DOT = 0.0

local MAX_SOLVES_PER_UPDATE = 2
local MAX_ATTEMPTS = 3

local ON_TRACK_TOLERANCE_M = 1.5

local CON_MATCH = "sncf_vse"

local LAYOUT_VERSION = 6

local BOGIE_FRONT_M = 6.734
local BOGIE_REAR_M = -6.734

local SNAP_Y_OFFSET_M = 2.0175
local SNAP_Z_OFFSET_M = 0.45
local SNAP_LOCAL = { 0, SNAP_Y_OFFSET_M, -SNAP_Z_OFFSET_M }

local function isVseConstruction(con)
	if con == nil or type(con.fileName) ~= "string" then return false end
	return string.find(con.fileName, "sncf_vse", 1, true) ~= nil
		or string.find(con.fileName, "voiture_se", 1, true) ~= nil
end

local function isSolved(con)
	local params = con.params or con.params_native
	if params == nil then return false end
	if params.vseSolved ~= true or params.vseLayout ~= LAYOUT_VERSION then
		return false
	end
	if params.vseSolvedXOffset ~= nil and params.sncf_vse_xoffset ~= nil then
		if params.vseSolvedXOffset ~= params.sncf_vse_xoffset then
			return false
		end
	end
	return true
end

local function samplesFor(edge)
	local n = math.ceil((edge.geometry.length or 0) * SAMPLES_PER_METRE)
	if n < SAMPLES_MIN then n = SAMPLES_MIN end
	if n > SAMPLES_MAX then n = SAMPLES_MAX end
	return n
end

local function isRail(edge)
	local m = edge.transportModes
	return m ~= nil and (m[api.type.enum.TransportMode.TRAIN] == true
		or m[api.type.enum.TransportMode.ELECTRIC_TRAIN] == true)
end

local function tangentAt(edge, t)
	local pd = api.engine.util.transport.calcPositionAndDirection(edge.geometry, t, true)
	local d = pd[2]
	local n = math.sqrt(d.x * d.x + d.y * d.y + d.z * d.z)
	if n < 1e-9 then return { x = 0, y = 0, z = 0 } end
	return { x = d.x / n, y = d.y / n, z = d.z / n }
end

local function nodeKey(nodeId)
	if nodeId == nil then return nil end
	return tostring(nodeId.entity) .. ":" .. tostring(nodeId.index)
end

local function collectRailEdges(pos)
	local pos2 = api.type.Vec2f.new(pos.x, pos.y)
	local seenEnt, ents = {}, {}
	for _, ct in ipairs({ api.type.ComponentType.BASE_EDGE, api.type.ComponentType.TRANSPORT_NETWORK }) do
		for _, e in ipairs(api.engine.util.octree.findEntitiesInCircle(pos2, CHAIN_SEARCH_RADIUS, ct)) do
			local k = tostring(e)
			if not seenEnt[k] then seenEnt[k] = true; ents[#ents + 1] = e end
		end
	end

	local pool, byNode = {}, {}
	for _, ent in ipairs(ents) do
		local tn = api.engine.getComponent(ent, api.type.ComponentType.TRANSPORT_NETWORK)
		if tn ~= nil and tn.edges ~= nil then
			for idx, edge in ipairs(tn.edges) do
				if isRail(edge) and edge.conns ~= nil and edge.conns[1] ~= nil and edge.conns[2] ~= nil then
					local rec = {
						entity = ent, index0 = idx - 1, edge = edge,
						a = nodeKey(edge.conns[1]), b = nodeKey(edge.conns[2]),
						id = tostring(ent) .. "#" .. tostring(idx - 1),
					}
					pool[#pool + 1] = rec
					byNode[rec.a] = byNode[rec.a] or {}
					byNode[rec.b] = byNode[rec.b] or {}
					table.insert(byNode[rec.a], rec)
					table.insert(byNode[rec.b], rec)
				end
			end
		end
	end
	return pool, byNode
end

local function closestRailEdge(pool, pos)
	local best = nil
	for _, rec in ipairs(pool) do
		local ns = samplesFor(rec.edge)
		for k = 0, ns do
			local t = k / ns
			local p = api.engine.util.transport.calcPosition(rec.edge.geometry, t)
			local dx, dy = p.x - pos.x, p.y - pos.y
			local d = math.sqrt(dx * dx + dy * dy)
			if best == nil or d < best.dist then
				best = { rec = rec, t = t, dist = d }
			end
		end
	end
	return best
end

local function walkChain(byNode, startRec, startDir, startT, needed)
	local chain = { { rec = startRec, dir = startDir, tFrom = startT } }
	local covered = startDir and ((1.0 - startT) * startRec.edge.geometry.length)
		or (startT * startRec.edge.geometry.length)

	local cur, curDir, guard = startRec, startDir, 0
	while covered < needed and guard < 64 do
		guard = guard + 1
		local exitKey = curDir and cur.b or cur.a
		local outT = tangentAt(cur.edge, curDir and 1.0 or 0.0)
		if not curDir then outT = { x = -outT.x, y = -outT.y, z = -outT.z } end

		local best, bestDot = nil, -2.0
		for _, cand in ipairs(byNode[exitKey] or {}) do
			if cand.id ~= cur.id then
				local candDir = (cand.a == exitKey)
				local inT = tangentAt(cand.edge, candDir and 0.0 or 1.0)
				if not candDir then inT = { x = -inT.x, y = -inT.y, z = -inT.z } end
				local d = outT.x * inT.x + outT.y * inT.y + outT.z * inT.z
				if d > bestDot then best, bestDot = { rec = cand, dir = candDir }, d end
			end
		end

		if best == nil or bestDot < WALK_MIN_DOT then break end
		chain[#chain + 1] = { rec = best.rec, dir = best.dir, tFrom = best.dir and 0.0 or 1.0 }
		covered = covered + best.rec.edge.geometry.length
		cur, curDir = best.rec, best.dir
	end
	return chain, covered
end

local function buildArcTable(chain)
	local samples, s, prev = {}, 0.0, nil
	for ci, link in ipairs(chain) do
		local edge = link.rec.edge
		local ns = samplesFor(edge)
		local t0 = (ci == 1) and link.tFrom or (link.dir and 0.0 or 1.0)
		local t1 = link.dir and 1.0 or 0.0
		for k = 0, ns do
			local t = t0 + (t1 - t0) * (k / ns)
			local p = api.engine.util.transport.calcPosition(edge.geometry, t)
			if prev ~= nil then
				s = s + math.sqrt((p.x - prev.x) ^ 2 + (p.y - prev.y) ^ 2 + (p.z - prev.z) ^ 2)
			end
			samples[#samples + 1] = { s = s, p = p }
			prev = p
		end
	end
	return samples
end

local function posAt(samples, s)
	if samples == nil or #samples == 0 then return nil end
	if s < samples[1].s then return nil end
	for i = 2, #samples do
		if samples[i].s >= s then
			local a, b = samples[i - 1], samples[i]
			local span = b.s - a.s
			local f = (span > 1e-6) and ((s - a.s) / span) or 0.0
			return {
				x = a.p.x + (b.p.x - a.p.x) * f,
				y = a.p.y + (b.p.y - a.p.y) * f,
				z = a.p.z + (b.p.z - a.p.z) * f,
			}
		end
	end
	local n = #samples
	if n < 2 then return samples[n].p end
	local a, b = samples[n - 1], samples[n]
	local span = b.s - a.s
	if span < 1e-6 then return b.p end
	local over = s - b.s
	local ux, uy, uz = (b.p.x - a.p.x) / span, (b.p.y - a.p.y) / span, (b.p.z - a.p.z) / span
	return { x = b.p.x + ux * over, y = b.p.y + uy * over, z = b.p.z + uz * over }
end

local function posAtLocalX(back, fwd, x)
	if x <= 0 then
		local p = posAt(back, -x)
		if p ~= nil then return p end
		return posAt(fwd, x)
	end
	local p = posAt(fwd, x)
	if p ~= nil then return p end
	return posAt(back, -x)
end

local function solve(con)
	local A = con.transf
	local pos = A:getTransl()
	local ex, ey = A:cols(0), A:cols(1)
	local ez = A:cols(2)

	local pool, byNode = collectRailEdges(pos)
	if #pool == 0 then return nil, "aucune edge ferroviaire" end

	local best = closestRailEdge(pool, pos)
	if best == nil then return nil, "pas d'accroche" end

	if best.dist > ON_TRACK_TOLERANCE_M then
		local snapPos = {
			x = pos.x + ex.x * SNAP_LOCAL[1] + ey.x * SNAP_LOCAL[2] + ez.x * SNAP_LOCAL[3],
			y = pos.y + ex.y * SNAP_LOCAL[1] + ey.y * SNAP_LOCAL[2] + ez.y * SNAP_LOCAL[3],
			z = pos.z + ex.z * SNAP_LOCAL[1] + ey.z * SNAP_LOCAL[2] + ez.z * SNAP_LOCAL[3],
		}
		local snapBest = closestRailEdge(pool, snapPos)
		if snapBest ~= nil and snapBest.dist <= ON_TRACK_TOLERANCE_M then
			best = snapBest
		else
			local snapPosInv = {
				x = pos.x - (ex.x * SNAP_LOCAL[1] + ey.x * SNAP_LOCAL[2] + ez.x * SNAP_LOCAL[3]),
				y = pos.y - (ex.y * SNAP_LOCAL[1] + ey.y * SNAP_LOCAL[2] + ez.y * SNAP_LOCAL[3]),
				z = pos.z - (ex.z * SNAP_LOCAL[1] + ey.z * SNAP_LOCAL[2] + ez.z * SNAP_LOCAL[3]),
			}
			local snapBestInv = closestRailEdge(pool, snapPosInv)
			if snapBestInv ~= nil and snapBestInv.dist <= ON_TRACK_TOLERANCE_M then
				best = snapBestInv
			else
				return nil, "asset pose hors voie"
			end
		end
	end

	local tan = tangentAt(best.rec.edge, best.t)
	local dot = tan.x * ex.x + tan.y * ex.y
	local backDir = not (dot > 0)

	local params = con.params or con.params_native
	local xOffset = 0.0
	if params and params.sncf_vse_xoffset then
		local raw = params.sncf_vse_xoffset
		if type(raw) == "number" then
			-- offset range is -100 to 100 with step 5
			xOffset = (-100 + raw * 5) / 100.0
		end
	end

	local bFront = BOGIE_FRONT_M + xOffset
	local bRear = BOGIE_REAR_M + xOffset
	local needed = math.max(math.abs(bFront), math.abs(bRear)) + MARGIN_M

	local chainBack = walkChain(byNode, best.rec, backDir, best.t, needed)
	local chainFwd = walkChain(byNode, best.rec, not backDir, best.t, needed)
	local back, fwd = buildArcTable(chainBack), buildArcTable(chainFwd)

	local pf = posAtLocalX(back, fwd, bFront)
	local pr = posAtLocalX(back, fwd, bRear)
	if pf == nil or pr == nil then return nil, "chaine de voie insuffisante" end

	local dx, dy, dz = pf.x - pr.x, pf.y - pr.y, pf.z - pr.z
	local n = math.sqrt(dx * dx + dy * dy + dz * dz)
	if n < 1e-6 then return nil, "bogies confondus" end
	dx, dy, dz = dx / n, dy / n, dz / n

	local ox = (pf.x + pr.x) * 0.5
	local oy = (pf.y + pr.y) * 0.5
	local oz = (pf.z + pr.z) * 0.5

	local wx, wy, wz = ox - pos.x, oy - pos.y, oz - pos.z
	local lx = wx * ex.x + wy * ex.y + wz * ex.z
	local ly = wx * ey.x + wy * ey.y + wz * ey.z
	local lz = wx * ez.x + wy * ez.y + wz * ez.z

	local ax = dx * ex.x + dy * ex.y + dz * ex.z
	local ay = dx * ey.x + dy * ey.y + dz * ey.z
	local az = dx * ez.x + dy * ez.y + dz * ez.z

	local edgeSpeedMs = (best.rec.edge and best.rec.edge.speedLimit) or 27.78
	local rawMs = edgeSpeedMs * 100
	local isDeversMarked = math.abs((rawMs - math.floor(rawMs)) - 0.5) < 0.02
	local cleanSpeedKmh = math.max(30, (isDeversMarked and (edgeSpeedMs - 0.005) or edgeSpeedMs) * 3.6)

	local be = api.engine.getComponent(best.rec.entity, api.type.ComponentType.BASE_EDGE)
	local tpl = be and tostring(be.roadTemplate or "") or ""
	local isSwitch = tpl:find("_dvs", 1, true) ~= nil
	local isDvTemplate = (tpl:find("_dv", 1, true) ~= nil or tpl:find("_dvp", 1, true) ~= nil or tpl:find("_dvf", 1, true) ~= nil) and not isSwitch
	local trackHasCant = (isDeversMarked or isDvTemplate) and not isSwitch

	local function cantForCurvature(k, vKmh)
		if not trackHasCant or isSwitch or math.abs(k) < 1e-6 then return 0.0 end
		local cap = math.max(60, math.min(200, 40 + 0.46 * vKmh))
		local dEq = 0.8 * 11.8 * vKmh * vKmh * math.abs(k)
		local d = math.min(cap, dEq)
		return (k >= 0) and d or -d
	end

	local bMid = (bFront + bRear) * 0.5
	local pm = posAtLocalX(back, fwd, bMid)
	local carRoll = 0.0
	if pm ~= nil then
		local chordMidX = (pf.x + pr.x) * 0.5
		local chordMidY = (pf.y + pr.y) * 0.5
		local chordMidZ = (pf.z + pr.z) * 0.5
		local arrX = pm.x - chordMidX
		local arrY = pm.y - chordMidY
		local arrZ = pm.z - chordMidZ
		local signedSagitta = arrX * ey.x + arrY * ey.y + arrZ * ey.z
		local carWheelbase = math.max(1.0, math.abs(bFront - bRear))
		local curvature = -8.0 * signedSagitta / (carWheelbase * carWheelbase)
		local cantMm = cantForCurvature(curvature, cleanSpeedKmh)
		carRoll = -math.asin(math.max(-1, math.min(1, cantMm / 1500.0)))
	end

	local flatB = {}
	local BOGIE_HALF_WHEELBASE_M = 1.24
	local bogieSpan = 2.0 * BOGIE_HALF_WHEELBASE_M
	for _, xb in ipairs({ bFront, bRear }) do
		local pc = posAtLocalX(back, fwd, xb)
		local pa = posAtLocalX(back, fwd, xb + BOGIE_HALF_WHEELBASE_M)
		local pb = posAtLocalX(back, fwd, xb - BOGIE_HALF_WHEELBASE_M)
		if pc ~= nil and pa ~= nil and pb ~= nil then
			local bdx, bdy, bdz = pa.x - pb.x, pa.y - pb.y, pa.z - pb.z
			local bn = math.sqrt(bdx * bdx + bdy * bdy + bdz * bdz)
			if bn > 1e-6 then
				bdx, bdy, bdz = bdx / bn, bdy / bn, bdz / bn

				local bChordX = (pa.x + pb.x) * 0.5
				local bChordY = (pa.y + pb.y) * 0.5
				local bChordZ = (pa.z + pb.z) * 0.5
				local barrX = pc.x - bChordX
				local barrY = pc.y - bChordY
				local barrZ = pc.z - bChordZ
				local bSagitta = barrX * ey.x + barrY * ey.y + barrZ * ey.z
				local bCurvature = -8.0 * bSagitta / (bogieSpan * bogieSpan)
				local bCantMm = cantForCurvature(bCurvature, cleanSpeedKmh)
				local bogieRoll = -math.asin(math.max(-1, math.min(1, bCantMm / 1500.0)))

				local bwx, bwy, bwz = pc.x - pos.x, pc.y - pos.y, pc.z - pos.z

				local base = #flatB
				flatB[base + 1] = bwx * ex.x + bwy * ex.y + bwz * ex.z
				flatB[base + 2] = bwx * ey.x + bwy * ey.y + bwz * ey.z
				flatB[base + 3] = bwx * ez.x + bwy * ez.y + bwz * ez.z
				flatB[base + 4] = bdx * ex.x + bdy * ex.y + bdz * ex.z
				flatB[base + 5] = bdx * ey.x + bdy * ey.y + bdz * ey.z
				flatB[base + 6] = bdx * ez.x + bdy * ez.y + bdz * ez.z
				flatB[base + 7] = bogieRoll
			end
		end
	end

	return { lx, ly, lz, ax, ay, az, carRoll }, flatB
end

local function copyParamsFrom(source)
	if source == nil then return nil end
	local out = {}
	local ok = pcall(function()
		for k, v in pairs(source) do out[k] = v end
	end)
	if ok and next(out) ~= nil then return out end
	return nil
end

local function copyParams(con)
	return copyParamsFrom(con.params) or copyParamsFrom(con.params_native)
end

local function applyToConstruction(entity, flat, flatB)
	if flat == nil then return end

	local con = api.engine.getComponent(entity, api.type.ComponentType.CONSTRUCTION)
	if con == nil then return end

	local p = copyParams(con)
	if p == nil then return end

	p.vseSolved = true
	p.vseLayout = LAYOUT_VERSION
	p.vseSolvedXOffset = p.sncf_vse_xoffset
	p.vseCarTransf = flat
	if flatB ~= nil and #flatB >= 12 then
		p.vseBogieTransfs = flatB
	end

	local ce = api.type.SimpleProposal.ConstructionEntity.new()
	ce.fileName = con.fileName
	ce.transf = con.transf
	ce.params = p
	ce.playerEntity = api.engine.util.getPlayer()
	local nameComponent = api.engine.util.getEntityName(entity)
	if nameComponent then ce.name = nameComponent end

	local proposal = api.type.SimpleProposal.new()
	proposal.constructionsToAdd = { ce }
	proposal.constructionsToRemove = { entity }
	proposal.old2new = { [entity] = 0 }

	api.cmd.sendCommand(api.cmd.makeWorldBuildProposalCmd(proposal, nil, true, false))
end

local function collectVseConstructions()
	local found = {}
	api.engine.forEachEntityWithComponent(function(entity)
		local con = api.engine.getComponent(entity, api.type.ComponentType.CONSTRUCTION)
		if isVseConstruction(con) then
			found[#found + 1] = entity
		end
	end, api.type.ComponentType.CONSTRUCTION)
	return found
end

function data()

local function consider(s, entity)
	local con = api.engine.getComponent(entity, api.type.ComponentType.CONSTRUCTION)
	if not isVseConstruction(con) then return nil end
	if isSolved(con) then return nil end

	local params = con.params or con.params_native
	local xKey = tostring(params and params.sncf_vse_xoffset or 0)
	local key = tostring(entity) .. ":" .. xKey
	local tries = s.tried[key] or 0
	if tries >= MAX_ATTEMPTS then return nil end
	s.tried[key] = tries + 1

	local flat, flatB = solve(con)
	if flat == nil then return nil end
	return { entity = entity, flat = flat, flatB = flatB }
end

local ret = {
	update = function(_userParams, state, _dt)
		local s = state:get() or {}
		s.tried = s.tried or {}

		if not state:hasEventSubscriptions() then
			state:subscribeToEvent("onPostBuildProposal")
		end

		local queue = s.queue or {}
		s.queue = nil

		if s.scannedLayout ~= LAYOUT_VERSION then
			s.scannedLayout = LAYOUT_VERSION
			s.tried = {}
			for _, e in ipairs(collectVseConstructions()) do queue[#queue + 1] = e end
		end

		if #queue == 0 then
			state:set(s)
			return nil
		end

		local pending, solves, rest = nil, 0, {}

		for i, e in ipairs(queue) do
			if solves >= MAX_SOLVES_PER_UPDATE then
				for j = i, #queue do rest[#rest + 1] = queue[j] end
				break
			end

			local ok, result = pcall(consider, s, e)
			if ok and result ~= nil then
				pending = pending or {}
				pending[#pending + 1] = result
				solves = solves + 1
			end
		end

		s.queue = (#rest > 0) and rest or nil
		state:set(s)
		return pending and { apply = pending } or nil
	end,

	handleEvent = function(_userParams, state, _src, _id, name, param)
		if name ~= "onPostBuildProposal" then return end

		if type(param) ~= "table" then return end
		local entities = param[3]
		if type(entities) ~= "table" then return end

		local s = state:get() or {}
		s.queue = s.queue or {}
		for _, e in ipairs(entities) do
			s.queue[#s.queue + 1] = e
		end
		state:set(s)
	end,

	postUpdate = function(_userParams, _state, _dt, updateResult)
		if updateResult == nil or updateResult.apply == nil then return end
		for _, item in ipairs(updateResult.apply) do
			applyToConstruction(item.entity, item.flat, item.flatB)
		end
		updateResult.apply = nil
	end,
}

return ret

end
