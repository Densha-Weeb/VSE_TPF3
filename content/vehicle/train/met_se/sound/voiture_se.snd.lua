local boostFactor = 1.35
local pitchFactor = 1.1

function data()
    return {
        tracks = {
            {
                name = "sncf_common_kit::/vehicle/train/sncf_common/sound/wav/bruhat/bruhat_15_clack.wav",
                attrs = { refDist = 10.0 },
            },
            {
                name = "sncf_common_kit::/vehicle/train/sncf_common/sound/wav/bruhat/bruhat_30.wav",
                attrs = { refDist = 12.0 },
            },
            {
                name = "sncf_common_kit::/vehicle/train/sncf_common/sound/wav/bruhat/bruhat_30_2.wav",
                attrs = { refDist = 12.0 },
            },
            {
                name = "sncf_common_kit::/vehicle/train/sncf_common/sound/wav/dev65/dev65_roll_80.wav",
                attrs = { refDist = 14.0 },
            },
            {
                name = "sncf_common_kit::/vehicle/train/sncf_common/sound/wav/dev65/dev65_roll_120.wav",
                attrs = { refDist = 22.0 },
            },
            {
                name = "sncf_common_kit::/vehicle/train/sncf_common/sound/wav/bruhat/bruhat_flange.wav",
                attrs = { refDist = 25.0 },
            },
            {
                name = "sncf_common_kit::/vehicle/train/sncf_common/sound/wav/bruhat/bruhat_brake.wav",
                attrs = { refDist = 20.0 },
            },
        },
        events = {
            openDoors = {
                names = { "sncf_common_kit::/vehicle/train/sncf_common/sound/wav/bruhat/ocem-open-door.wav" },
                attrs = { refDist = 5.0 },
            },
            closeDoors = {
                names = { "sncf_common_kit::/vehicle/train/sncf_common/sound/wav/bruhat/ocem-close-door.wav" },
                attrs = { refDist = 5.0 },
            },
        },


        updateScript = {
            fileName = "soundset_bw_script::/scripts/soundset_bw.script@updateSoundSet",
            params = {
                updateFunctions = {
                    -- Track 1: bruhat_15_clack.wav (20 km/h)
                    {
                        type = "SampleCurve",
                        params = {
                            gainScriptingInfoKey = "vehicle",
                            gainParamName = "speedKmh",
                            gainCurve = {
                                { 0.0, 0.0 },
                                { 15.0, 1.0 * boostFactor * 1.5 },
                                { 20.0, 1.0 * boostFactor * 1.5 },
                                { 50.0, 0.0 },
                                { 200.0, 0.0 },
                            },
                            pitchScriptingInfoKey = "vehicle",
                            pitchParamName = "speedKmh",
                            pitchCurve = {
                                { 0.0, 0.8 },
                                { 20.0, 1.0 },
                                { 45.0, 1.2 },
                                { 200.0, 1.2 },
                            },
                        },
                    },

                    -- Track 2: bruhat_30.wav (40 km/h clack)
                    {
                        type = "SampleCurve",
                        params = {
                            gainScriptingInfoKey = "vehicle",
                            gainParamName = "speedKmh",
                            gainCurve = {
                                { 0.0, 0.0 },
                                { 15.0, 0.0 },
                                { 40.0, 1.0 * boostFactor * 2.0 },
                                { 100.0, 0.1 * boostFactor * 2.0 },
                            },
                            pitchScriptingInfoKey = "vehicle",
                            pitchParamName = "speedKmh",
                            pitchCurve = {
                                { 0.0, 0.8 },
                                { 40.0, 1.0 },
                                { 100.0, 0.8 },
                            },
                        },
                    },

                    -- Track 3: bruhat_30_2.wav (40 km/h)
                    {
                        type = "SampleCurve",
                        params = {
                            gainScriptingInfoKey = "vehicle",
                            gainParamName = "speedKmh",
                            gainCurve = {
                                { 0.0, 0.0 },
                                { 10.0, 0.0 },
                                { 40.0, 1.0 * boostFactor },
                                { 90.0, 0.0 },
                                { 200.0, 0.0 },
                            },
                            pitchScriptingInfoKey = "vehicle",
                            pitchParamName = "speedKmh",
                            pitchCurve = {
                                { 0.0, 0.6 * pitchFactor },
                                { 40.0, 1.0 * pitchFactor },
                                { 80.0, 2.0 * pitchFactor },
                                { 200.0, 2.0 * pitchFactor },
                            },
                        },
                    },

                    -- Track 4: dev65_roll_80.wav (80 km/h)
                    {
                        type = "SampleCurve",
                        params = {
                            gainScriptingInfoKey = "vehicle",
                            gainParamName = "speedKmh",
                            gainCurve = {
                                { 0.0, 0.0 },
                                { 30.0, 0.0 },
                                { 80.0, 1.0 * boostFactor },
                                { 130.0, 0.0 },
                                { 200.0, 0.0 },
                            },
                            pitchScriptingInfoKey = "vehicle",
                            pitchParamName = "speedKmh",
                            pitchCurve = {
                                { 0.0, 0.5 * pitchFactor },
                                { 40.0, 0.5 * pitchFactor },
                                { 80.0, 1.0 * pitchFactor },
                                { 120.0, 1.5 * pitchFactor },
                                { 200.0, 1.5 * pitchFactor },
                            },
                        },
                    },

                    -- Track 5: dev65_roll_120.wav (120 km/h)
                    {
                        type = "SampleCurve",
                        params = {
                            gainScriptingInfoKey = "vehicle",
                            gainParamName = "speedKmh",
                            gainCurve = {
                                { 0.0, 0.0 },
                                { 70.0, 0.0 },
                                { 120.0, 1.0 * boostFactor },
                                { 200.0, 1.4 * boostFactor },
                            },
                            pitchScriptingInfoKey = "vehicle",
                            pitchParamName = "speedKmh",
                            pitchCurve = {
                                { 0.0, (80.0 / 120.0) * pitchFactor },
                                { 80.0, (80.0 / 120.0) * pitchFactor },
                                { 120.0, 1.0 * pitchFactor },
                                { 200.0, (200.0 / 120.0) * pitchFactor },
                            },
                        },
                    },

                    -- Track 6: bruhat_flange.wav (Wheel squeal)
                    {
                        type = "Squeal",
                        params = {
                            sideForceMult = 1.3,
                        },
                    },

                    -- Track 7: bruhat_brake.wav (Braking sound)
                    {
                    	type = "Brake",
                    	params = {
                    		maxGain = 1.5,
                    	},
                    },

                    -- Event 2: Door opening
                    {
                        type = "None",
                        eventKey = "openDoors",
                        params = {},
                    },

                    -- Event 3: Door closing
                    {
                        type = "None",
                        eventKey = "closeDoors",
                        params = {},
                    },
                },
            },
        },
    }
end
