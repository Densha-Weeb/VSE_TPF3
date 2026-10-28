local sncf_vse_assets = ug_require "sncf_vse_asset_commons.lua"

local offsetStrings = sncf_vse_assets.map(sncf_vse_assets.offsetValues, function(i)
    return "" .. i .. " cm"
end)

function data()

    return {
        availability = {
            yearFrom = 1926
        },
        constructionType = "ASSET_TRACK",
        description = {
            name = _("vse_assetsName"),
            description = _("vse_assetsDesc"),
            icon = "densha_VSE::/vehicle/train/met_se/icons/vse_assets@2x.tga",
            previewIcon = "densha_VSE::/vehicle/train/met_se/icons/vse_assets_preview@2x.tga",
        },
        menuCategory = {
            categories = {
                {
                    category = "landscaping_vehicles",
                    filterCategories = { "passenger_wagon" },
                    order = 1000,
                },
            },
        },
        buildMode = "MULTI",
        skipCollision = true,
        autoRemovable = false,
        snapping = {
            rail = true,
            road = false,
            water = false,
        },
        order = 1,
        params = {
            {
                key = "sncf_vse_variant",
                name = _("vse_paramVariant"),
                uiType = "IconButton",
                values = sncf_vse_assets.uiIconPaths,
                tooltip = _("vse_toolTypeVariant"),
                tooltips = sncf_vse_assets.names,
                defaultIndex = 1,
                display = "Compact",
                postConstructionModifiable = true,
            },
            {
                key = "sncf_vse_light_pos",
                name = _("vse_paramLightPos"),
                uiType = "Button",
                values = { _("Off"), _("Direction 1"), _("Direction 2") },
                tooltip = _("vse_toolTypeLightPos"),
                tooltips = { _("Off"), _("Direction 1"), _("Direction 2") },
                defaultIndex = 1,
                postConstructionModifiable = true,
            },
            {
                key = "sncf_vse_bellow",
                name = _("vse_paramBellow"),
                uiType = "Button",
                values = { _("Off"), _("AV"), _("AR"), _("AV + AR") },
                tooltip = _("vse_toolTypeBellow"),
                defaultIndex = 1,
                postConstructionModifiable = true,
            },
            {
                key = "sncf_vse_xoffset",
                name = _("vse_paramXOffset"),
                uiType = "Slider",
                values = offsetStrings,
                tooltip = _("vse_toolTypeXOffset"),
                defaultIndex = math.ceil(#sncf_vse_assets.offsetValues / 2),
                postConstructionModifiable = true,
            },
        },
        updateScript = {
            fileName = "sncf_vse.script@updateFn",
        }
    }

end
