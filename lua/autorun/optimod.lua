local process_script = CLIENT and include or AddCSLuaFile --smart functions are cool
local scripts = {
	"main",
	"panels/convar_controller",
	"panels/hook_controller"
}

--make them download localizations, I wonder if gmod does this on its own...
resource.AddSingleFile("resource/localization/de/optimod.properties")
resource.AddSingleFile("resource/localization/en/optimod.properties")

--include and addcslua all the files dependent by realm
for index, script in ipairs(scripts) do process_script("optimod/" .. script .. ".lua") end