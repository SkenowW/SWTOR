-- ============================================================
--  SW:TOR RP — SALLES D'ENTRAÎNEMENT
--  lua/autorun/server/sv_swtor_training.lua
--  Combat sans mort, sans XP, messages privés Victoire/Défaite
-- ============================================================

if CLIENT then return end

SWTOR.Training = SWTOR.Training or {}
SWTOR.Training.Zones  = {}
SWTOR.Training.Fights = {}

util.AddNetworkString("SWTOR_TrainingMsg")
util.AddNetworkString("SWTOR_InTraining")

-- DB
sql.Query([[CREATE TABLE IF NOT EXISTS swtor_training_zones (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT DEFAULT 'Salle',
    mins_x REAL, mins_y REAL, mins_z REAL,
    maxs_x REAL, maxs_y REAL, maxs_z REAL
)]])

local function LoadZones()
    SWTOR.Training.Zones = {}
    local rows = sql.Query("SELECT * FROM swtor_training_zones") or {}
    for _, r in ipairs(rows) do
        table.insert(SWTOR.Training.Zones, {
            id=tonumber(r.id), label=r.label,
            mins=Vector(tonumber(r.mins_x),tonumber(r.mins_y),tonumber(r.mins_z)),
            maxs=Vector(tonumber(r.maxs_x),tonumber(r.maxs_y),tonumber(r.maxs_z)),
        })
    end
end
timer.Simple(4, LoadZones)

function SWTOR.Training.IsInZone(ply)
    if not IsValid(ply) then return false end
    local pos = ply:GetPos()
    for _, z in ipairs(SWTOR.Training.Zones) do
        if pos:WithinAABox(z.mins, z.maxs) then return true, z end
    end
    return false
end

local function Msg(ply, msg, t)
    net.Start("SWTOR_TrainingMsg")
        net.WriteString(msg) net.WriteString(t or "info")
    net.Send(ply)
end

local function SyncState(ply, state)
    net.Start("SWTOR_InTraining") net.WriteBool(state) net.Send(ply)
end

-- Bloquer les dégâts létaux en zone
hook.Add("EntityTakeDamage", "SWTOR_TrainingDmg", function(target, dmginfo)
    if not target:IsPlayer() then return end
    local inZone = SWTOR.Training.IsInZone(target)
    if not inZone then return end
    local attacker = dmginfo:GetAttacker()
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if not SWTOR.Training.IsInZone(attacker) then dmginfo:SetDamage(0) return end
    -- Laisser 1 HP minimum
    if target:Health() - dmginfo:GetDamage() <= 1 then
        dmginfo:SetDamage(target:Health() - 1)
    end
    -- Enregistrer le combat
    local s1, s2 = target:SteamID(), attacker:SteamID()
    if not SWTOR.Training.Fights[s1] and not SWTOR.Training.Fights[s2] then
        SWTOR.Training.Fights[s1] = { opponent=attacker }
        SWTOR.Training.Fights[s2] = { opponent=target }
        SyncState(target, true) SyncState(attacker, true)
    end
end)

-- Détecter victoire (HP à 1)
timer.Create("SWTOR_TrainingCheck", 0.1, 0, function()
    for sid, fight in pairs(SWTOR.Training.Fights) do
        -- CORRECTION ANTI-LAG : Recherche instantanée sans boucle
        local ply = player.GetBySteamID(sid)
        local opp = fight.opponent
        
        if not IsValid(ply) or not IsValid(opp) then
            SWTOR.Training.Fights[sid] = nil continue
        end
        if not SWTOR.Training.IsInZone(ply) or not SWTOR.Training.IsInZone(opp) then
            SWTOR.Training.Fights[sid] = nil
            SWTOR.Training.Fights[opp:SteamID()] = nil
            SWTOR.ApplyClassStats(ply) SWTOR.ApplyClassStats(opp)
            SyncState(ply,false) SyncState(opp,false)
            Msg(ply,"⚠ Combat annulé.","warning") Msg(opp,"⚠ Combat annulé.","warning")
        elseif ply:Health() <= 1 then
            -- ply a perdu
            SWTOR.Training.Fights[sid] = nil
            SWTOR.Training.Fights[opp:SteamID()] = nil
            timer.Simple(0.3, function()
                if IsValid(ply)  then SWTOR.ApplyClassStats(ply)  end
                if IsValid(opp)  then SWTOR.ApplyClassStats(opp)  end
            end)
            SyncState(ply,false) SyncState(opp,false)
            Msg(opp, "VICTOIRE", "victory")
            Msg(ply,  "DÉFAITE",  "defeat")
        end
    end
end)

-- Bloquer mort réelle en zone
hook.Add("PlayerDeath", "SWTOR_TrainingNoDeath", function(victim)
    if not SWTOR.Training.IsInZone(victim) then return end
    victim.swtor_deaths = math.max(0,(victim.swtor_deaths or 1)-1)
    timer.Simple(0,function() if IsValid(victim) then victim:Spawn() SWTOR.ApplyClassStats(victim) end end)
    return true
end)

-- Commandes pour créer les zones
local Setup = {}
concommand.Add("swtor_training_corner1", function(ply)
    if not IsValid(ply) or not SWTOR.IsAdmin(ply) then return end
    Setup[ply:SteamID()] = ply:GetPos()
    SWTOR.Notify(ply,"📍 Coin 1 posé. Va au coin opposé → swtor_training_corner2 <nom>","info")
end)
concommand.Add("swtor_training_corner2", function(ply, _, args)
    if not IsValid(ply) or not SWTOR.IsAdmin(ply) then return end
    local c1 = Setup[ply:SteamID()]
    if not c1 then SWTOR.Notify(ply,"Pose d'abord le coin 1.","error") return end
    local c2    = ply:GetPos()
    local label = table.concat(args," ")
    if label=="" then label="Salle d'Entraînement" end
    local mins = Vector(math.min(c1.x,c2.x)-50,math.min(c1.y,c2.y)-50,math.min(c1.z,c2.z)-20)
    local maxs = Vector(math.max(c1.x,c2.x)+50,math.max(c1.y,c2.y)+50,math.max(c1.z,c2.z)+150)
    sql.Query(string.format("INSERT INTO swtor_training_zones (label,mins_x,mins_y,mins_z,maxs_x,maxs_y,maxs_z) VALUES (%s,%f,%f,%f,%f,%f,%f)",
        sql.SQLStr(label),mins.x,mins.y,mins.z,maxs.x,maxs.y,maxs.z))
    table.insert(SWTOR.Training.Zones,{label=label,mins=mins,maxs=maxs})
    Setup[ply:SteamID()]=nil
    SWTOR.Notify(ply,"✅ Salle '"..label.."' créée !","success")
end)
concommand.Add("swtor_training_list", function(ply)
    local fn = IsValid(ply) and function(s) ply:ChatPrint(s) end or print
    fn("=== Salles d'entraînement ===")
    for i,z in ipairs(SWTOR.Training.Zones) do fn("  "..i..". "..z.label) end
end)

print("[SW:TOR Training] Salles d'entraînement chargées ✓")
