local ArrayMethods = {}

function ArrayMethods:map(f)
    local result = {}
    for i, v in ipairs(self) do
        result[i] = f(v, i)
    end
    return setmetatable(result, getmetatable(self))
end

function ArrayMethods:foreach(f)
    for i, v in ipairs(self) do
        f(v, i)
    end
end

local function makeArray(t)
    return setmetatable(t, { __index = ArrayMethods })
end
math.randomseed(os.clock()*100000000000)

local function randomScale()
    return math.pow(math.random(), 2)
end

local curtain = {}

curtain.configTypes = {
    A4D = { xPositions = { 0.02, 2.17, 4.30, 6.44 }, yOffset = 1.40550380249, },
    A7 = {
        yOffset = 1.404,
        ori = {
            xPositions = {
                6.77,
                6.05,
                4.62,
                3.90,
                2.48,
                1.75,
                0.36,
                -6.77,
                -6.05,
                -4.62,
                -3.90,
                -2.48,
                -1.75,
                -0.36,
            },
            widthFactor = 0.548,
        },
        flip = {
            xPositions = { -6.39,
                           -3.86,
                           -1.32,
                           1.32,
                           3.86,
                           6.39, },
            widthFactor = 1.45,
        },
    },
    A7_U = {
        pullFactor = 1,
        yOffset = 1.404,
        ori = {
            xPositions = {
                6.77,
                6.05,
                4.62,
                3.90,
                2.48,
                1.75,
                0.36,
                -6.77,
                -6.05,
                -4.62,
                -3.90,
                -2.48,
                -1.75,
                -0.36,
            },
            widthFactor = 0.548,
        },
        flip = {
            xPositions = { -6.39,
                           -3.86,
                           -1.32,
                           1.32,
                           3.86,
                           6.39, },
            widthFactor = 1.45,
        },
    },
    B4D = { xPositions = { 0.9385, 2.81, 4.71, 6.58 }, yOffset = 1.40550380249, },
    B8 = {
        yOffset = 1.404,
        ori = {
            xPositions = {
                6.805,
                6.085,
                4.965,
                4.245,
                3.125,
                2.405,
                1.29,
                0.565,
                -6.805,
                -6.085,
                -4.965,
                -4.245,
                -3.125,
                -2.405,
                -1.29,
                -0.565,
            },
            widthFactor = 0.478,
        },
        flip = {
            xPositions = { -6.39,
                           -3.86,
                           -1.32,
                           1.32,
                           3.86,
                           6.39, },
            widthFactor = 1.45,
        },
    },
    uas = { xPositions = { 0.9385, 2.81, 4.71, 6.58 }, pullFactor = 1, yOffset = 1.40550380249, },
}

function curtain:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end


function curtain:curtainMesh(lod, x, pullFactor, flip, widthFactor, yOffset, customMaterial)
    local curtainHeight = 0.99
    if not pullFactor then pullFactor = 0 end
    if self.config.pullFactor ~= nil then pullFactor = self.config.pullFactor end
    widthFactor = widthFactor or 1
    flip = flip or 1

    local mat = customMaterial or self.material

    local curtainDetails
    if lod == 0 then
        curtainDetails =  {
            children = {
                {
                    materials = { mat, },
                    mesh = "/vehicle/train/met_se/msh/curtain_box_lod" .. lod .. ".msh",
                    name = "curtain_box",
                    transf = { widthFactor, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 3.1861608028412, 1, },
                },
                {
                    materials = { mat, },
                    mesh = "/vehicle/train/met_se/msh/curtain_pull_lod" .. lod .. ".msh",
                    name = "curtain_pull",
                    transf = { widthFactor, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 2.1296174526215 + (curtainHeight*(1-pullFactor)), 1, },
                },
            },
            name = "curtain_details",
            transf = {  1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
        }
    end

    return {
        children = {
            {
                materials = { mat, },
                mesh = "/vehicle/train/met_se/msh/curtain_lod" .. lod .. ".msh",
                name = "curtain",
                transf = { widthFactor+.1, 0, 0, 0, 0, 1, 0, 0, 0, 0, pullFactor, 0, 0, 0, 3.1200184822083, 1, },
            },
            curtainDetails,
        },
        name = "curtain_group",
        transf = {  flip, 0, 0, 0, 0,  flip, 0, 0, 0, 0, 1, 0, x, flip * yOffset, 0, 1, },
    }
end

function curtain.withPullFactor(x)
    return {
        ori = { x = x, pullFactor = randomScale() },
        flip = { x = x, pullFactor = randomScale() },
    }
end

function curtain.withMoreParams(x, widthFactor, yOffset)
    return {
        x = x,
        pullFactor = randomScale(),
        widthFactor = widthFactor or 1.0,
        yOffset = yOffset,
    }
end


function curtain.mapSide(positions, widthFactor, yOffset)
    return makeArray(positions):map(function(x)
        return curtain.withMoreParams(x, widthFactor, yOffset)
    end)
end

function curtain:buildCurtainConfig()

    if self.config.ori and self.config.flip then
        -- Cas B8 asymétrique
        self.allTransfsParams = {
            ori  = curtain.mapSide(self.config.ori.xPositions,  self.config.ori.widthFactor, self.config.yOffset),
            flip = curtain.mapSide(self.config.flip.xPositions, self.config.flip.widthFactor, self.config.yOffset),
        }
    else
        -- Cas symétriques (A4D, B4D, uas)
        local positions = self.config.xPositions
        local wf = self.config.widthFactor or 1.0
        local side = curtain.mapSide(positions, wf, self.config.yOffset)
        self.allTransfsParams = {
            ori  = side,
            flip = side,
        }
    end

    if self.config == curtain.configTypes.A7 then
        local white_mat = "/vehicle/train/met_se/mat/curtain_uas_2.mtl"
        -- Y+ side (ori) only: +0.4m at +X (7.17), +0.8m at -X (-7.57)
        table.insert(self.allTransfsParams.ori, {
            x = 8,
            pullFactor = 1.0,
            widthFactor = 0.6,
            yOffset = self.config.yOffset,
            material = white_mat
        })
        table.insert(self.allTransfsParams.ori, {
            x = -8,
            pullFactor = 1.0,
            widthFactor = 0.6,
            yOffset = self.config.yOffset,
            material = white_mat
        })
        elseif self.config == curtain.configTypes.A7_U then
        local white_mat = "/vehicle/train/met_se/mat/curtain_uas.mtl"
        -- Y+ side (ori) only: +0.4m at +X (7.205), +0.8m at -X (-7.605)
        table.insert(self.allTransfsParams.ori, {
            x = 8,
            pullFactor = 1.0,
            widthFactor = 0.6,
            yOffset = self.config.yOffset,
            material = white_mat
        })
        table.insert(self.allTransfsParams.ori, {
            x = -8,
            pullFactor = 1.0,
            widthFactor = 0.6,
            yOffset = self.config.yOffset,
            material = white_mat
        })
    elseif self.config == curtain.configTypes.B8 then
        local white_mat = "/vehicle/train/met_se/mat/curtain_uas_2.mtl"
        -- Y+ side (ori) only: +0.4m at +X (7.205), +0.8m at -X (-7.605)
        table.insert(self.allTransfsParams.ori, {
            x = 8,
            pullFactor = 1.0,
            widthFactor = 0.6,
            yOffset = self.config.yOffset,
            material = white_mat
        })
        table.insert(self.allTransfsParams.ori, {
            x = -8,
            pullFactor = 1.0,
            widthFactor = 0.6,
            yOffset = self.config.yOffset,
            material = white_mat
        })
    end

    return self
end

function curtain.build(params)
    if params.seed then
        math.randomseed(params.seed)
    end
    return curtain:new(params):buildCurtainConfig():buildModel()
end

function curtain:allCurtains(lod)
    local res = {}
    local add = function(cfg, sideFlip)
        table.insert(res, self:curtainMesh(
                lod,
                cfg.x,
                cfg.pullFactor,
                sideFlip,
                cfg.widthFactor,
                cfg.yOffset,
                cfg.material
        ))
    end

    self.allTransfsParams.ori:foreach(function(cfg) add(cfg, 1) end)
    self.allTransfsParams.flip:foreach(function(cfg) add(cfg, -1) end)

    return res
end

function curtain:lod0(visibleFrom, visibleTo)
    local lod = 0
    return  {
        node = {
            children = self:allCurtains(lod),
            name = "RootNode",
            transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
        },
        visibleFrom = visibleFrom,
        visibleTo = visibleTo,
    }
end

function curtain:lod1(visibleFrom, visibleTo)
    local lod = 1
    return  {
        node = {
            children = self:allCurtains(lod),
            name = "RootNode",
            transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
        },
        visibleFrom = visibleFrom,
        visibleTo = visibleTo,
    }
end

function curtain:lod2(visibleFrom, visibleTo)
    local lod = 2
    return  {
        node = {
            children = self:allCurtains(lod),
            name = "RootNode",
            transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, },
        },
        visibleFrom = visibleFrom,
        visibleTo = visibleTo,
    }
end

function curtain:buildModel()
    return {
        boundingInfo = {
            bbMax = { 9.9619998931885, 1.5455362796783, 4.1226382255554, },
            bbMin = { -9.9619998931885, -1.5455356836319, -0.027392685413361, },
        },
        collider = {
            params = {
                halfExtents = { 9.9619998931885, 1.5455362796783, (3.19-2.12)/2, },
            },
            transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 9.9619998931885/2, 0, (3.19+2.12)/2, 1, },
            type = "BOX",
        },
        lods = {
            self:lod0(0,20),
            self:lod1(20,300),
        },
        metadata = { },
        version = 2,
    }
end

return curtain