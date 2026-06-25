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
local gm = "gamemodes/swtor_rp/"

local sharedFiles = {
    "lua/autorun/sh_swtor_config.lua",
    "lua/autorun/sh_swtor_factions.lua",
    "lua/autorun/sh_swtor_planets.lua",
    "lua/autorun/sh_swtor_classes.lua",
    "lua/autorun/sh_swtor_shop.lua",
    "lua/autorun/sh_swtor_combat_dirs.lua",
    "lua/autorun/sh_swtor_combat_engine.lua",
    "lua/autorun/sh_swtor_parry.lua",
    "lua/autorun/sh_swtor_workshop.lua",
    "lua/autorun/sh_swtor_loot.lua",
    "lua/autorun/sh_swtor_levels.lua",
}
for _, f in ipairs(sharedFiles) do
    if SERVER then AddCSLuaFile(gm .. f) end
    include("../" .. f)
end

-- ============================================================
--  WEAPONS, ENTITÉS & FICHIERS CLIENT
-- ============================================================
if SERVER then
    local csFiles = {
        -- Weapons
        gm .. "lua/weapons/swtor_lightsaber/shared.lua",
        gm .. "lua/weapons/swtor_lightsaber_dual/shared.lua",
        gm .. "lua/weapons/swtor_lightsaber_double/shared.lua",
        gm .. "lua/weapons/swtor_vibroblade/shared.lua",
        gm .. "lua/weapons/swtor_blaster/shared.lua",
        gm .. "lua/weapons/swtor_blaster_heavy/shared.lua",
        gm .. "lua/weapons/swtor_blaster_dual/shared.lua",
        gm .. "lua/weapons/swtor_sniper/shared.lua",
        -- Entités
        gm .. "lua/entities/swtor_bolt/shared.lua",
        gm .. "lua/entities/swtor_bolt/cl_init.lua",
        -- Client
        gm .. "lua/autorun/client/cl_swtor_hud.lua",
        gm .. "lua/autorun/client/cl_swtor_chat.lua",
        gm .. "lua/autorun/client/cl_swtor_effects.lua",
        gm .. "lua/autorun/client/cl_swtor_events.lua",
        gm .. "lua/autorun/client/cl_swtor_faction_menu.lua",
        gm .. "lua/autorun/client/cl_swtor_class_menu.lua",
        gm .. "lua/autorun/client/cl_swtor_abilities_menu.lua",
        gm .. "lua/autorun/client/cl_swtor_stats_menu.lua",
        gm .. "lua/autorun/client/cl_swtor_wardrobe.lua",
        gm .. "lua/autorun/client/cl_swtor_shop.lua",
        gm .. "lua/autorun/client/cl_swtor_application.lua",
        gm .. "lua/autorun/client/cl_swtor_adminpanel.lua",
        gm .. "lua/autorun/client/cl_swtor_combat_engine.lua",
        gm .. "lua/autorun/client/cl_swtor_hrp.lua",
        gm .. "lua/autorun/client/cl_swtor_playerlist.lua",
        gm .. "lua/autorun/client/cl_swtor_spawnconfig.lua",
        gm .. "lua/autorun/client/cl_swtor_rb655.lua",
        gm .. "lua/autorun/client/cl_swtor_loot.lua",
        gm .. "lua/autorun/client/cl_swtor_training.lua",
        gm .. "lua/autorun/client/cl_swtor_swingindicator.lua",
    }
    for _, f in ipairs(csFiles) do AddCSLuaFile(f) end
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