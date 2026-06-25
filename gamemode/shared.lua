-- ============================================================
--  SW:TOR RP — GAMEMODE SHARED
--  gamemode/shared.lua
-- ============================================================

GM.Name    = "SW:TOR RP"
GM.Author  = "SW:TOR RP Team"
GM.Email   = ""
GM.Website = ""

DeriveGamemode("base")

-- ============================================================
--  CHARGEMENT PARTAGÉ (client + serveur)
-- ============================================================
local sharedFiles = {
    "lua/core/sh_swtor_config.lua",
    "lua/core/sh_swtor_factions.lua",
    "lua/core/sh_swtor_planets.lua",
    "lua/core/sh_swtor_classes.lua",
    "lua/core/sh_swtor_shop.lua",
    "lua/core/sh_swtor_combat_dirs.lua",
    "lua/core/sh_swtor_combat_engine.lua",
    "lua/core/sh_swtor_parry.lua",
    "lua/core/sh_swtor_workshop.lua",
    "lua/core/sh_swtor_loot.lua",
    "lua/core/sh_swtor_levels.lua",
}


local count = 0
for _, f in ipairs(sharedFiles) do
    if SERVER then AddCSLuaFile(f) end
    include(f)
    count = count + 1
end
print("[SW:TOR RP DEBUG] " .. count .. " fichiers partagés chargés avec succès.")

-- ============================================================
--  WEAPONS, ENTITÉS & FICHIERS CLIENT
-- ============================================================
if SERVER then
    local csFiles = {
        -- Weapons
        "lua/weapons/swtor_lightsaber/shared.lua",
        "lua/weapons/swtor_lightsaber_dual/shared.lua",
        "lua/weapons/swtor_lightsaber_double/shared.lua",
        "lua/weapons/swtor_vibroblade/shared.lua",
        "lua/weapons/swtor_blaster/shared.lua",
        "lua/weapons/swtor_blaster_heavy/shared.lua",
        "lua/weapons/swtor_blaster_dual/shared.lua",
        "lua/weapons/swtor_sniper/shared.lua",
        -- Entités
        "lua/entities/swtor_bolt/shared.lua",
        "lua/entities/swtor_bolt/cl_init.lua",
        -- Client
        "lua/core/client/cl_swtor_hud.lua",
        "lua/core/client/cl_swtor_chat.lua",
        "lua/core/client/cl_swtor_effects.lua",
        "lua/core/client/cl_swtor_events.lua",
        "lua/core/client/cl_swtor_faction_menu.lua",
        "lua/core/client/cl_swtor_class_menu.lua",
        "lua/core/client/cl_swtor_abilities_menu.lua",
        "lua/core/client/cl_swtor_stats_menu.lua",
        "lua/core/client/cl_swtor_wardrobe.lua",
        "lua/core/client/cl_swtor_shop.lua",
        "lua/core/client/cl_swtor_application.lua",
        "lua/core/client/cl_swtor_adminpanel.lua",
        "lua/core/client/cl_swtor_combat_engine.lua",
        "lua/core/client/cl_swtor_hrp.lua",
        "lua/core/client/cl_swtor_playerlist.lua",
        "lua/core/client/cl_swtor_spawnconfig.lua",
        "lua/core/client/cl_swtor_rb655.lua",
        "lua/core/client/cl_swtor_loot.lua",
        "lua/core/client/cl_swtor_training.lua",
        "lua/core/client/cl_swtor_swingindicator.lua",
    }
    local count = 0
    for _, f in ipairs(csFiles) do 
        AddCSLuaFile(f) 
        count = count + 1
    end
    print("[SW:TOR RP DEBUG] " .. count .. " fichiers client/entités/weapons chargés avec succès.")
end

-- ============================================================
--  TEAMS
-- ============================================================
team.SetUp(1, "Empire Sith",           Color(180, 20,  20))
team.SetUp(2, "République Galactique", Color(30,  100, 200))
team.SetUp(3, "Clan Mandalorien",      Color(180, 140, 20))
team.SetUp(4, "Sans faction",          Color(100, 100, 100))

-- ============================================================
--  RÈGLES DE BASE
-- ============================================================
function GM:GetFallDamage(ply, speed)
    if speed < 700 then return 0 end
    return (speed - 700) * 0.1
end

function GM:EntityTakeDamage(target, dmginfo)
    if not target:IsPlayer() then return end
    local planet = SWTOR and SWTOR.Planets and SWTOR.Planets[target.swtor_planet or ""]
    if planet and planet.type == "neutral" then
        local attacker = dmginfo:GetAttacker()
        if IsValid(attacker) and attacker:IsPlayer() then
            dmginfo:ScaleDamage(0)
        end
    end
end

function GM:ScalePlayerDamage(ply, hitgroup, dmginfo)
    if ply:GetNWBool("swtor_war_cry", false) then
        dmginfo:ScaleDamage(1.2)
    end
end

print("[SW:TOR RP] Gamemode shared chargé ✓")