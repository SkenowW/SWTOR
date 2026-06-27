-- ============================================================
--  SW:TOR RP — COMBAT, HP DYNAMIQUE, PVP
--  lua/autorun/server/sv_swtor_combat.lua
-- ============================================================

if CLIENT then return end

util.AddNetworkString("SWTOR_KillFeed")

-- ============================================================
--  HP DYNAMIQUE PAR GRADE
-- ============================================================
local function ApplyHP(ply)
    if not IsValid(ply) then return end
    local grade = ply.swtor_grade or 1
    local hp    = SWTOR.Config.BaseHP + (grade - 1) * SWTOR.Config.HPPerGrade
    hp = math.min(hp, SWTOR.Config.MaxHP)
    ply:SetMaxHealth(hp)
    ply:SetHealth(hp)
end

hook.Add("PlayerSpawn", "SWTOR_ApplyHP", function(ply)
    timer.Simple(0.2, function()
        if IsValid(ply) then ApplyHP(ply) end
    end)
end)

-- Re-appliquer quand le grade change (appelé depuis sv_swtor_database)
function SWTOR.RefreshHP(ply)
    ApplyHP(ply)
end

-- ============================================================
--  RÈGLES PVP
-- ============================================================
hook.Add("PlayerShouldTakeDamage", "SWTOR_PvPRules", function(victim, attacker)
    -- Pas de dégâts sur soi-même sauf explosion
    if victim == attacker then return true end

    -- NPC : toujours ok
    if not attacker:IsPlayer() then return true end

    -- Si PvP global désactivé
    if not SWTOR.Config.PvPEnabled then return false end

    local vFaction = victim.swtor_faction   or ""
    local aFaction = attacker.swtor_faction or ""

    -- Même faction = tir ami
    if vFaction == aFaction and vFaction ~= "" then
        if not SWTOR.Config.FriendlyFire then
            attacker:ChatPrint("[SWTOR] Tir ami interdit dans votre faction !")
            return false
        end
    end

    -- Mandalo peut attaquer tout le monde (mercenaires)
    -- Neutre (nar_shaddaa) = pas de PvP
    local vPlanet = SWTOR.Planets[victim.swtor_planet or ""]
    if vPlanet and vPlanet.type == "neutral" then
        attacker:ChatPrint("[SWTOR] Combat interdit sur " .. vPlanet.name .. " !")
        return false
    end

    return true
end)

-- ============================================================
--  KILL FEED & XP
-- ============================================================
hook.Add("PlayerDeath", "SWTOR_CombatDeath", function(victim, inflictor, attacker)
    if not IsValid(victim) then return end

    -- Stats victim
    victim.swtor_deaths = (victim.swtor_deaths or 0) + 1

    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
        attacker.swtor_kills = (attacker.swtor_kills or 0) + 1
        attacker.swtor_xp    = (attacker.swtor_xp    or 0) + SWTOR.Config.KillBonus

        -- Auto-promote si XP suffisant et activé
        if SWTOR.Config.AutoPromote then
            local maxGrade  = SWTOR.GetMaxGrade(attacker.swtor_faction or "")
            local curGrade  = attacker.swtor_grade or 1
            local xpNeeded  = curGrade * SWTOR.Config.XPPerGrade
            if attacker.swtor_xp >= xpNeeded and curGrade < maxGrade then
                SWTOR.PromotePlayer(attacker)
            end
        end

        -- Kill feed global
        local aFaction = SWTOR.Factions[attacker.swtor_faction or ""]
        local vFaction = SWTOR.Factions[victim.swtor_faction   or ""]
        local aGrade   = SWTOR.GetGrade(attacker.swtor_faction or "", attacker.swtor_grade or 1)
        local vGrade   = SWTOR.GetGrade(victim.swtor_faction   or "", victim.swtor_grade   or 1)

        local msg = string.format("[%s] %s (%s) a éliminé [%s] %s (%s)",
            aFaction and aFaction.shortname or "?",
            attacker:Nick(),
            aGrade   and aGrade.name  or "?",
            vFaction and vFaction.shortname or "?",
            victim:Nick(),
            vGrade   and vGrade.name  or "?"
        )

        for _, ply in ipairs(player.GetAll()) do
            ply:ChatPrint(msg)
        end

        SWTOR.SavePlayer(attacker)
        SWTOR.SyncPlayerData(attacker)
    end

    SWTOR.SavePlayer(victim)
end)

-- ============================================================
--  RESPAWN AUTOMATIQUE
-- ============================================================
-- ============================================================
--  RESPAWN AUTOMATIQUE
-- ============================================================
hook.Add("PlayerDeathThink", "SWTOR_AutoRespawn", function(ply)
    -- On bloque le respawn manuel (clic) pendant le délai
    if ply.NextSpawnTime and ply.NextSpawnTime > CurTime() then
        return false 
    end

    -- Si le délai est passé, on laisse le joueur spawn
    if ply.NextSpawnTime and ply.NextSpawnTime <= CurTime() then
        ply:Spawn()
        return true
    end
end)

-- Il faut définir NextSpawnTime au moment où le joueur meurt
hook.Add("PlayerDeath", "SWTOR_SetRespawnTimer", function(ply)
    local respawnDelay = SWTOR.Config and SWTOR.Config.RespawnTime or 10 -- 10 sec par défaut
    ply.NextSpawnTime = CurTime() + respawnDelay
end)

-- ============================================================
--  FORCE POWERS (cooldown système)
-- ============================================================
SWTOR.ForceCooldowns = {}

local ForcePowers = {
    -- Sith
    force_lightning = { faction = "empire",     cooldown = 15, dmg = 40,  range = 500,  msg = "Force Foudre" },
    force_choke     = { faction = "empire",     cooldown = 20, dmg = 0,   range = 300,  msg = "Étranglement" },
    force_push_dark = { faction = "empire",     cooldown = 8,  dmg = 10,  range = 600,  msg = "Répulsion Sith" },
    -- Jedi
    force_heal      = { faction = "republique", cooldown = 30, heal = 50, range = 0,    msg = "Soin Force" },
    force_push_jedi = { faction = "republique", cooldown = 8,  dmg = 10,  range = 600,  msg = "Répulsion Jedi" },
    force_mindtrick = { faction = "republique", cooldown = 25, dmg = 0,   range = 200,  msg = "Illusion Mentale" },
}

util.AddNetworkString("SWTOR_ForceUse")

net.Receive("SWTOR_ForceUse", function(len, ply)
    local powerKey = net.ReadString()
    local power    = ForcePowers[powerKey]
    if not power then return end

    -- SÉCURITÉ 1 : Le pouvoir est-il de sa faction ?
    if power.faction ~= ply.swtor_faction then
        SWTOR.Notify(ply, "Ce pouvoir n'appartient pas à votre faction.", "error")
        return
    end

    -- SÉCURITÉ 2 : Le joueur a-t-il vraiment débloqué cette compétence avec son grade/classe ?
    if not SWTOR.HasAbility(ply, powerKey) then
        SWTOR.Notify(ply, "Vous n'avez pas encore débloqué ce pouvoir.", "error")
        return
    end

    -- SÉCURITÉ 3 : Le joueur est-il en vie ? (Évite d'étrangler quelqu'un en étant mort)
    if not ply:Alive() then return end

    -- Cooldown
    local sid = ply:SteamID()
    local cdKey = sid .. "_" .. powerKey
    if SWTOR.ForceCooldowns[cdKey] and SWTOR.ForceCooldowns[cdKey] > CurTime() then
        local remaining = math.ceil(SWTOR.ForceCooldowns[cdKey] - CurTime())
        SWTOR.Notify(ply, power.msg .. " — Rechargement: " .. remaining .. "s", "warning")
        return
    end

    SWTOR.ForceCooldowns[cdKey] = CurTime() + power.cooldown

    -- Appliquer l'effet
    if powerKey == "force_lightning" then
        local tr = ply:GetEyeTrace()
        if IsValid(tr.Entity) and tr.Entity:IsPlayer() then
            tr.Entity:TakeDamage(power.dmg, ply, ply)
            tr.Entity:SetVelocity(Vector(0,0,150))
            SWTOR.Notify(ply, "⚡ Force Foudre lancée !", "success")
        end

    elseif powerKey == "force_choke" then
        local tr = ply:GetEyeTrace()
        if IsValid(tr.Entity) and tr.Entity:IsPlayer() then
            local target = tr.Entity
            -- Soulever la cible
            target:SetVelocity(Vector(0,0,200))
            timer.Simple(3, function()
                if IsValid(target) then
                    target:TakeDamage(30, ply, ply)
                end
            end)
            SWTOR.Notify(ply, "🤚 Étranglement activé !", "success")
        end

    elseif powerKey == "force_push_dark" or powerKey == "force_push_jedi" then
        for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), power.range)) do
            if IsValid(ent) and ent ~= ply then
                local dir = (ent:GetPos() - ply:GetPos()):GetNormalized()
                if ent:IsPlayer() or ent:GetMoveType() == MOVETYPE_VPHYSICS then
                    if ent:IsPlayer() then
                        ent:SetVelocity(dir * 600 + Vector(0,0,200))
                        if power.dmg > 0 then ent:TakeDamage(power.dmg, ply, ply) end
                    else
                        local phys = ent:GetPhysicsObject()
                        if IsValid(phys) then phys:ApplyForceCenter(dir * 50000) end
                    end
                end
            end
        end
        SWTOR.Notify(ply, "💨 Répulsion lancée !", "success")

    elseif powerKey == "force_heal" then
        local newHP = math.min(ply:Health() + power.heal, ply:GetMaxHealth())
        ply:SetHealth(newHP)
        SWTOR.Notify(ply, "💚 Soin: +" .. power.heal .. " HP", "success")

    elseif powerKey == "force_mindtrick" then
        local tr = ply:GetEyeTrace()
        if IsValid(tr.Entity) and tr.Entity:IsPlayer() then
            SWTOR.Notify(tr.Entity, "Vous vous sentez confus... Ce n'est pas votre ennemi.", "warning")
            SWTOR.Notify(ply, "🌀 Illusion Mentale appliquée sur " .. tr.Entity:Nick(), "success")
        end
    end

    -- Annonce à la faction
    for _, p in ipairs(player.GetAll()) do
        if p.swtor_faction == ply.swtor_faction and p ~= ply then
            p:ChatPrint("[Force] " .. ply:Nick() .. " utilise " .. power.msg)
        end
    end
end)

print("[SW:TOR] Combat & Force chargés ✓")

-- ============================================================
--  ARMURE RÉELLE > 100 (override dégâts via NWInt)
-- ============================================================
hook.Add("EntityTakeDamage", "SWTOR_RealArmor", function(target, dmginfo)
    if not target:IsPlayer() then return end
    local realArmor = target:GetNWInt("swtor_real_armor", 0)
    if realArmor <= 100 then return end  -- GMod gère lui-même sous 100

    local attacker = dmginfo:GetAttacker()
    if not IsValid(attacker) or not attacker:IsPlayer() then return end

    -- Réduction d'armure : chaque point d'armure = 0.05% réduction, cap 95%
    local reduction = math.Clamp(realArmor * 0.0005, 0, 0.95)
    dmginfo:ScaleDamage(1 - reduction)
end)

-- HUD sync armure réelle vers client (via SyncData déjà géré)
-- Le client lit swtor_real_armor via GetNWInt directement

-- ============================================================
--  PARADE — Intercepter les dégâts si la cible pare
-- ============================================================
hook.Add("EntityTakeDamage", "SWTOR_ParryCheck", function(target, dmginfo)
    if not target:IsPlayer() then return end
    local attacker = dmginfo:GetAttacker()
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if not target.swtor_is_parrying then return end

    local style = target.swtor_parry_style or "single"
    local dmg   = dmginfo:GetDamage()
    local newDmg, parried = SWTOR.Parry.CheckParry(attacker, target, dmg, style)

    if parried then
        dmginfo:SetDamage(newDmg)
        -- Effet visuel pour le pareur
        if SWTOR.BroadcastEffect then
            SWTOR.BroadcastEffect("force_armor", target:GetPos(), target:GetAngles(),
                Color(200,200,255), 50)
        end
    end
end)

