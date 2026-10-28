local SNAP_Y_OFFSET_M = 2.0175
local SNAP_Z_OFFSET_M = 0.45
local BOGIE_PIVOT_X_OFFSET = 6.734

local sncf_vse_assets = ug_require "sncf_vse_asset_commons.lua"

sncf_vse_assets.toModelPath = function(name)
    return "densha_VSE::/assets/vehicle/train/met_se/" .. name .. ".mdl"
end

sncf_vse_assets.configToModelPath = function(model)
    return "densha_VSE::/assets/vehicle/train/met_se/" .. model.name .. ".mdl"
end



local function curtainModel(curtainType)
    if curtainType:match("uas") == nil then
        math.randomseed(os.clock() * 100000000000)
        local i = 1 + math.random(100) % 3
        return "densha_VSE::/assets/vehicle/train/met_se/curtains_" .. curtainType .. "_" .. i .. ".mdl"
    else
        return "densha_VSE::/assets/vehicle/train/met_se/curtains_" .. curtainType .. ".mdl"
    end
end


local function transfFromAxis(px, py, pz, ax, ay, az, roll)
    local n = math.sqrt(ax * ax + ay * ay + az * az)
    if n < 1e-9 then return nil end
    ax, ay, az = ax / n, ay / n, az / n

    local yx0, yy0 = -ay, ax
    local yn = math.sqrt(yx0 * yx0 + yy0 * yy0)
    if yn < 1e-9 then
        yx0, yy0 = 0, 1
    else
        yx0, yy0 = yx0 / yn, yy0 / yn
    end

    local zx0 = -az * yy0
    local zy0 = az * yx0
    local zz0 = ax * yy0 - ay * yx0

    local cosR = 1.0
    local sinR = 0.0
    local offY = 0.0
    local offZ = 0.0
    if roll ~= nil and math.abs(roll) > 1e-6 then
        cosR = math.cos(roll)
        sinR = math.sin(roll)
        local railPivotY = (roll <= 0) and 0.75 or -0.75
        offY = railPivotY * (1.0 - cosR)
        offZ = -railPivotY * sinR
    end

    local yx = cosR * yx0 + sinR * zx0
    local yy = cosR * yy0 + sinR * zy0
    local yz = sinR * zz0

    local zx = -sinR * yx0 + cosR * zx0
    local zy = -sinR * yy0 + cosR * zy0
    local zz = cosR * zz0

    local posX = px + offY * yx0 + offZ * zx0
    local posY = py + offY * yy0 + offZ * zy0
    local posZ = pz + offZ * zz0

    return {
        ax, ay, az, 0,
        yx, yy, yz, 0,
        zx, zy, zz, 0,
        posX, posY, posZ, 1,
    }
end

function data()
    return {
		updateFn = function(captureParams, params)

            local waggon = sncf_vse_assets

            local xOffset = waggon.offsetValues[params.sncf_vse_xoffset + 1] / 100

            local selectedConfig = waggon.modelConfigs[params.sncf_vse_variant]
            local version = waggon.configToModelPath(selectedConfig)


            --CURTAINS
            local curtains = curtainModel(selectedConfig.curtainType)

            --INTERCIRCULATION
            local inter_1 = waggon.toModelPath(selectedConfig.intercirculation .. (params.sncf_vse_bellow % 2 == 1 and "_c" or "_l"))
            local inter_2 = waggon.toModelPath(selectedConfig.intercirculation .. (params.sncf_vse_bellow <= 2 and "_c" or "_l"))

            -- DEFAULT TRANSFORMS (Preview before placement)
            local carTransf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, xOffset, 0, 0, 1 }
            local inter1Transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, xOffset, 0, 0, 1 }
            local inter2Transf = { -1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, xOffset, 0, 0, 1 }

            -- BOGIE MODEL & TRANSFORMS
            local bogieModel = waggon.toModelPath("bogie_" .. selectedConfig.bogieType)
            local bogieFrontTransf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, xOffset + BOGIE_PIVOT_X_OFFSET, 0, 0, 1 }
            local bogieRearTransf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, xOffset - BOGIE_PIVOT_X_OFFSET, 0, 0, 1 }

            -- SOLVED TRANSFORMS (Aligned to real track 3D curve & cant)
            if params and params.vseSolved == true then
                local defaultIdx = math.ceil(#waggon.offsetValues / 2)
                local solvedRaw = params.vseSolvedXOffset
                local solvedIdx = (type(solvedRaw) == "number") and ((solvedRaw >= 1) and solvedRaw or (solvedRaw + 1)) or defaultIdx
                local solvedXOffset = (waggon.offsetValues[solvedIdx] or 0) / 100.0
                local deltaX = xOffset - solvedXOffset

                if type(params.vseCarTransf) == "table" and #params.vseCarTransf >= 6 then
                    local c = params.vseCarTransf
                    local roll = c[7] or 0.0
                    local px = c[1] + c[4] * deltaX
                    local py = c[2] + c[5] * deltaX
                    local pz = c[3] + c[6] * deltaX
                    local t = transfFromAxis(px, py, pz, c[4], c[5], c[6], roll)
                    if t ~= nil then
                        carTransf = t
                        inter1Transf = t
                        inter2Transf = {
                            -t[1], -t[2], -t[3], 0,
                            -t[5], -t[6], -t[7], 0,
                            t[9], t[10], t[11], 0,
                            t[13], t[14], t[15], 1,
                        }
                    end
                end

                if type(params.vseBogieTransfs) == "table" and #params.vseBogieTransfs >= 12 then
                    local b = params.vseBogieTransfs
                    local bf, br
                    if #b >= 14 then
                        bf = transfFromAxis(b[1] + b[4] * deltaX, b[2] + b[5] * deltaX, b[3] + b[6] * deltaX, b[4], b[5], b[6], b[7])
                        br = transfFromAxis(b[8] + b[11] * deltaX, b[9] + b[12] * deltaX, b[10] + b[13] * deltaX, b[11], b[12], b[13], b[14])
                    else
                        bf = transfFromAxis(b[1] + b[4] * deltaX, b[2] + b[5] * deltaX, b[3] + b[6] * deltaX, b[4], b[5], b[6], 0.0)
                        br = transfFromAxis(b[7] + b[10] * deltaX, b[8] + b[11] * deltaX, b[9] + b[12] * deltaX, b[10], b[11], b[12], 0.0)
                    end
                    if bf ~= nil then bogieFrontTransf = bf end
                    if br ~= nil then bogieRearTransf = br end
                elseif carTransf ~= nil then
                    local ax, ay, az = carTransf[1], carTransf[2], carTransf[3]
                    bogieFrontTransf = {
                        carTransf[1], carTransf[2], carTransf[3], carTransf[4],
                        carTransf[5], carTransf[6], carTransf[7], carTransf[8],
                        carTransf[9], carTransf[10], carTransf[11], carTransf[12],
                        carTransf[13] + ax * BOGIE_PIVOT_X_OFFSET, carTransf[14] + ay * BOGIE_PIVOT_X_OFFSET, carTransf[15] + az * BOGIE_PIVOT_X_OFFSET, 1
                    }
                    bogieRearTransf = {
                        carTransf[1], carTransf[2], carTransf[3], carTransf[4],
                        carTransf[5], carTransf[6], carTransf[7], carTransf[8],
                        carTransf[9], carTransf[10], carTransf[11], carTransf[12],
                        carTransf[13] - ax * BOGIE_PIVOT_X_OFFSET, carTransf[14] - ay * BOGIE_PIVOT_X_OFFSET, carTransf[15] - az * BOGIE_PIVOT_X_OFFSET, 1
                    }
                end
            end

            -- LIGHTS
            local lights = nil
            if params.sncf_vse_light_pos > 1 then
                local lightName = selectedConfig.backLight
                local lTransf = carTransf
                if params.sncf_vse_light_pos == 3 then
                    lightName = selectedConfig.frontLight
                    lTransf = inter2Transf
                end
                lights = { id = waggon.toModelPath(lightName), transf = lTransf }
            end

            local models = {
                { id = version, transf = carTransf },
                { id = curtains, transf = carTransf },
                { id = inter_1, transf = inter1Transf },
                { id = inter_2, transf = inter2Transf },
            }
            if lights ~= nil then
                models[#models + 1] = lights
            end
            if bogieModel ~= nil then
                models[#models + 1] = { id = bogieModel, transf = bogieFrontTransf }
                models[#models + 1] = { id = bogieModel, transf = bogieRearTransf }
            end

            return {
                noCostAtAll = true,
                snapPoint = {
                    transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, SNAP_Y_OFFSET_M, -SNAP_Z_OFFSET_M, 1 },
                    transportModes = { "TRAIN", "ELECTRIC_TRAIN" },
                    snapToBaseEdgeTypes = { "TRACK" },
                    allowSnapToBaseEdgeEnds = false,
                    alignWithCoast = false,
                    placeAtTerrainHeight = false,
                    forceSnapToWaterSurfaceHeight = false,
                    snapHeightOffsetAboveWater = 0.0,
                    onlySnapToWaterSurfaceHeightWhenInWater = false,
                    allowSnapToMesh = false,
                },
                subconstructions = {
                    {
                        models = models,

                        terrainAlignmentLists = {
                            {
                                type = "EQUAL",
                                faces = {}
                            }
                        },
                        groundFaces = {
                            {
                                face = { { -1, -1, 0 }, { 1, -1, 0 }, { 1, 1, 0 }, { -1, 1, 0 } },
                                modes = { { type = "FILL", key = "::/infrastructure/shared/none.gtex" } },
                                loop = false,
                                alignmentOffsetMode = "OBJECT",
                                alignmentDirMode = "OBJECT",
                            },
                        }
                    }
                }

            }
        end
    }

end