local sncf_vse_assets = {}

sncf_vse_assets.map = function(a, f)
    local res = {}
    if a and type(a) == "table" then
        for _, v in ipairs(a) do
            table.insert(res, f(v))
        end
    end
    return res
end

sncf_vse_assets.intRange = function(start, stop, step)
    local a = {}
    local i = start
    while i <= stop do
        table.insert(a, i)
        i = i + step
    end
    return a
end


sncf_vse_assets.offsetValues = sncf_vse_assets.intRange(-100, 100, 5)

sncf_vse_assets.modelConfigs = {
    { name = "a3b4_se_epii",            intercirculation = "soufflet",  backLight = "lanternes_70",     frontLight = "lanternes_70",    curtainType = "a7",        bogieType = "y16", },
    { name = "a3b4_se_epiiib",          intercirculation = "soufflet",  backLight = "lanternes_70",     frontLight = "lanternes_70",    curtainType = "a7",        bogieType = "y16", },
    { name = "a4d_se_epiiib",           intercirculation = "soufflet",  backLight = "light",            frontLight = "lanternes_70",    curtainType = "a4d",       bogieType = "c", },
    { name = "a4d_se_epiiic",           intercirculation = "soufflet",  backLight = "light",            frontLight = "lanternes_70",    curtainType = "a4d",       bogieType = "c", },
    { name = "a4d_se_epiiid",           intercirculation = "soufflet",  backLight = "light",            frontLight = "lanternes_70",    curtainType = "a4d",       bogieType = "c", },
    { name = "a4d_se_epiva_1",          intercirculation = "soufflet",  backLight = "light",            frontLight = "lanternes_70",    curtainType = "a4d",       bogieType = "y16", },
    { name = "a4d_se_epiva_2",          intercirculation = "soufflet",  backLight = "light",            frontLight = "lanternes_70",    curtainType = "a4d",       bogieType = "y16", },
    { name = "a4d_se_epv_r420",         intercirculation = "soufflet",  backLight = "light",            frontLight = "lanternes_90",    curtainType = "a4d",       bogieType = "y16", },
    { name = "a4d_se_epvi_aaatv",       intercirculation = "soufflet",  backLight = "light",            frontLight = "lanternes_90",    curtainType = "a4d",       bogieType = "y16", },
    { name = "a4d_se_epvi_cftlp",       intercirculation = "soufflet",  backLight = "light",            frontLight = "lanternes_90",    curtainType = "a4d",       bogieType = "y16", },
    { name = "a7_se_epii",              intercirculation = "soufflet",  backLight = "lanternes_70",     frontLight = "lanternes_70",    curtainType = "a7",        bogieType = "y16", },
    { name = "a7_se_epiiia",            intercirculation = "soufflet",  backLight = "lanternes_70",     frontLight = "lanternes_70",    curtainType = "a7",        bogieType = "y16", },
    { name = "a7_se_epiiib",            intercirculation = "soufflet",  backLight = "lanternes_70",     frontLight = "lanternes_70",    curtainType = "a7",        bogieType = "y16", },
    { name = "a7_se_epiv",              intercirculation = "soufflet",  backLight = "lanternes_70",     frontLight = "lanternes_70",    curtainType = "a7",        bogieType = "y16", },
    { name = "b4d_se_epiiib",           intercirculation = "soufflet",  backLight = "light",            frontLight = "lanternes_70",    curtainType = "b4d",       bogieType = "c", },
    { name = "b4d_se_epiiic",           intercirculation = "soufflet",  backLight = "light",            frontLight = "lanternes_70",    curtainType = "b4d",       bogieType = "c", },
    { name = "b4d_se_epiv",             intercirculation = "soufflet",  backLight = "light",            frontLight = "lanternes_70",    curtainType = "b4d",       bogieType = "y16", },
    { name = "b4d_se_epivb",            intercirculation = "soufflet",  backLight = "light",            frontLight = "lanternes_70",    curtainType = "b4d",       bogieType = "y16", },
    { name = "b4d_se_epvi_mfpn",        intercirculation = "soufflet",  backLight = "light",            frontLight = "light",           curtainType = "b4d",       bogieType = "y16", },
    { name = "b4d_se_epvi_pvc",         intercirculation = "soufflet",  backLight = "light",            frontLight = "lanternes_90",    curtainType = "b4d",       bogieType = "y16", },
    { name = "b8_se_epii",              intercirculation = "soufflet",  backLight = "lanternes_70",     frontLight = "lanternes_70",    curtainType = "b8",        bogieType = "y16", },
    { name = "b8_se_epiiia",            intercirculation = "soufflet",  backLight = "lanternes_70",     frontLight = "lanternes_70",    curtainType = "b8",        bogieType = "c", },
    { name = "b8_se_epiiib",            intercirculation = "soufflet",  backLight = "lanternes_70",     frontLight = "lanternes_70",    curtainType = "b8",        bogieType = "c", },
    { name = "c8_se_epiiib",            intercirculation = "soufflet",  backLight = "lanternes_70",     frontLight = "lanternes_70",    curtainType = "b8",        bogieType = "c", },
    { name = "uas_se_cantonnement_1",   intercirculation = "uas",       backLight = "lanternes_90",     frontLight = "lanternes_90",    curtainType = "uas_blanc", bogieType = "y16", },
    { name = "uas_se_cantonnement_2",   intercirculation = "uas",       backLight = "lanternes_90",     frontLight = "lanternes_90",    curtainType = "uas_beige", bogieType = "y16", },
    { name = "uas_se_cantonnement_3",   intercirculation = "uas",       backLight = "lanternes_90",     frontLight = "lanternes_90",    curtainType = "uas_blanc", bogieType = "y16", },
    { name = "uas_se_epv",              intercirculation = "uas",       backLight = "lanternes_70",     frontLight = "lanternes_70",    curtainType = "uas_a7",    bogieType = "c", },
}

local function toUiIconPath(model)
    return "densha_VSE::/vehicle/train/met_se/icons/" .. model.name .. "_icon20@2x.tga"
end

sncf_vse_assets.uiIconPaths = sncf_vse_assets.map(sncf_vse_assets.modelConfigs, toUiIconPath)

sncf_vse_assets.names = sncf_vse_assets.map(sncf_vse_assets.modelConfigs, function(model)
    return model.name
end)


return sncf_vse_assets

