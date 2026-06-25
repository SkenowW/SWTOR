-- ============================================================
--  SW:TOR RP — GAMEMODE SERVER INIT
--  gamemode/init.lua
-- ============================================================

include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

-- ============================================================
--  CHARGEMENT SERVEUR DANS L'ORDRE
-- ============================================================
local serverFiles = {
    "lua/core/server/sv_swtor_database.lua",
    "lua/core/server/sv_swtor_combat.lua",
    "lua/core/server/sv_swtor_combat_engine.lua",
    "lua/core/server/sv_swtor_abilities.lua",
    "lua/core/server/sv_swtor_map.lua",
    "lua/core/server/sv_swtor_models.lua",
    "lua/core/server/sv_swtor_shop.lua",
    "lua/core/server/sv_swtor_chat.lua",
    "lua/core/server/sv_swtor_adminpanel.lua",
    "lua/core/server/sv_swtor_applications.lua",
    "lua/core/server/sv_swtor_entities.lua",
    "lua/core/server/sv_swtor_npcs.lua",
    "lua/core/server/sv_swtor_events.lua",
    "lua/core/server/sv_swtor_adminnet.lua",
    "lua/core/server/sv_swtor_swinglabel.lua",
    "lua/core/server/sv_swtor_rb655.lua",
    "lua/core/server/sv_swtor_hrp.lua",
    "lua/core/server/sv_swtor_spawnconfig.lua",
    "lua/core/server/sv_swtor_loot.lua",
    "lua/core/server/sv_swtor_duels.lua",
    "lua/core/server/sv_swtor_training.lua",
    "lua/core/server/sv_workshop.lua",
}
local count = 0
for _, f in ipairs(serverFiles) do
    include(f)
    count = count + 1
end
print("[SW:TOR RP DEBUG] " .. count .. " fichiers serveur chargés avec succès.")

-- ============================================================
--  HOOKS GAMEMODE SERVEUR
-- ============================================================

function GM:PlayerInitialSpawn(ply)
    timer.Simple(2, function()
        if not IsValid(ply) then return end
        SWTOR.LoadPlayer(ply)
    end)
end

function GM:PlayerSpawn(ply)
    timer.Simple(0.3, function()
        if not IsValid(ply) then return end
        SWTOR.ApplyClassStats(ply)
        -- Restaurer modèle sauvegardé
        if ply.swtor_model and ply.swtor_model ~= "" then
            ply:SetModel(ply.swtor_model)
        else
            ply:SetModel("models/player/kleiner.mdl")
        end
        -- Spawn sur sa planète
        local planet  = ply.swtor_planet or ""
        local faction = ply.swtor_faction or ""
        if planet ~= "" and SWTOR.Planets[planet] then
            local sp = SWTOR.GetRandomSpawn(planet)
            if sp then ply:SetPos(sp.pos) ply:SetEyeAngles(sp.ang) end
        elseif faction ~= "" then
            local fd = SWTOR.Factions[faction]
            if fd and fd.planet_home then
                local sp = SWTOR.GetRandomSpawn(fd.planet_home)
                if sp then
                    ply:SetPos(sp.pos)
                    ply:SetEyeAngles(sp.ang)
                    ply.swtor_planet = fd.planet_home
                end
            end
        end
        -- Arme gérée par sv_swtor_rb655.lua (hook PlayerSpawn dédié)
    end)
end

function GM:PlayerDisconnected(ply)
    SWTOR.SavePlayer(ply)
end


function GM:PlayerDeathThink(ply)
    -- Bloquer le respawn manuel — géré par timer
    return false
end

function GM:ShowTeam(ply)
    -- Bloquer le menu team GMod par défaut
    return false
end

function GM:ShowHelp(ply)
    -- F1 — ouvrir notre aide côté client via net
    net.Start("SWTOR_OpenHelp")
    net.Send(ply)
    return false
end

function GM:ShowSpare1(ply)
    -- F3 — menu voyage
    net.Start("SWTOR_OpenTravel")
    net.Send(ply)
end

function GM:ShowSpare2(ply)
    -- F4 — panel admin si admin, sinon profil
    if ply:IsAdmin() then
        net.Start("SWTOR_OpenAdminPanel")
        net.Send(ply)
    else
        net.Start("SWTOR_OpenProfile")
        net.Send(ply)
    end
end

-- Pas de pickup d'armes au sol par défaut
function GM:PlayerCanPickupWeapon(ply, wep)
    return wep:GetClass():find("swtor_") ~= nil
end

-- Team selon faction
function GM:PlayerSetModel(ply)
    if ply.swtor_faction == "empire"      then ply:SetTeam(1)
    elseif ply.swtor_faction == "republique" then ply:SetTeam(2)
    elseif ply.swtor_faction == "mandalorien" then ply:SetTeam(3)
    else ply:SetTeam(4) end
end

util.AddNetworkString("SWTOR_OpenHelp")
util.AddNetworkString("SWTOR_OpenTravel")
util.AddNetworkString("SWTOR_OpenAdminPanel")
util.AddNetworkString("SWTOR_OpenProfile")

print("[SW:TOR RP] Gamemode serveur chargé ✓")
