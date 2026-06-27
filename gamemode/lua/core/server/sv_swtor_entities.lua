-- ============================================================
--  SW:TOR RP — ENTITÉS INTERACTIVES
--  lua/autorun/server/sv_swtor_entities.lua
--  Holocrons (XP), Terminaux (téléport), Caisses (crédits)
-- ============================================================

if CLIENT then return end

util.AddNetworkString("SWTOR_EntityInteract")
util.AddNetworkString("SWTOR_SpawnEntity")

-- ============================================================
--  HOLOCRONS — Donnent XP à la faction
-- ============================================================
local function SpawnHolocron(pos, factionReq, xpAmount, label)
    local ent = ents.Create("prop_physics")
    if not IsValid(ent) then return end
    ent:SetModel("models/props_combine/combine_interface001.mdl")
    ent:SetPos(pos)
    ent:Spawn()
    ent:GetPhysicsObject():EnableGravity(false)
    ent:GetPhysicsObject():Sleep()
    ent:SetColor(factionReq == "empire" and Color(255,50,50) or Color(50,100,255))

    -- Données
    ent.swtor_type       = "holocron"
    ent.swtor_faction    = factionReq
    ent.swtor_xp         = xpAmount
    ent.swtor_label      = label or "Holocron"
    ent.swtor_used       = {}
    ent.swtor_respawn_t  = 0

    -- Rotation
    ent:SetAngles(Angle(45, 0, 0))
    timer.Create("Holocron_Spin_" .. ent:EntIndex(), 0.05, 0, function()
        if IsValid(ent) then
            ent:SetAngles(Angle(45, (CurTime()*60)%360, 45))
        end
    end)

    return ent
end

-- ============================================================
--  TERMINAUX DE VOYAGE
-- ============================================================
local function SpawnTerminal(pos, destPlanet, factionReq)
    local ent = ents.Create("prop_physics")
    if not IsValid(ent) then return end
    ent:SetModel("models/props_combine/combine_dispenser.mdl")
    ent:SetPos(pos)
    ent:Spawn()
    ent:GetPhysicsObject():EnableMotion(false)

    ent.swtor_type    = "terminal"
    ent.swtor_planet  = destPlanet
    ent.swtor_faction = factionReq
    ent.swtor_label   = destPlanet and SWTOR.Planets[destPlanet] and SWTOR.Planets[destPlanet].name or "?"

    return ent
end

-- ============================================================
--  CAISSES DE RESSOURCES (crédits)
-- ============================================================
local function SpawnCrate(pos, credits, respawnTime)
    local ent = ents.Create("prop_physics")
    if not IsValid(ent) then return end
    ent:SetModel("models/props_junk/wood_crate001a.mdl")
    ent:SetPos(pos)
    ent:Spawn()

    ent.swtor_type        = "crate"
    ent.swtor_credits     = credits     or 100
    ent.swtor_respawn     = respawnTime or 300
    ent.swtor_active      = true

    return ent
end

-- ============================================================
--  INTERACTION (USE sur une entité)
-- ============================================================
hook.Add("PlayerUse", "SWTOR_EntityUse", function(ply, ent)
    if not IsValid(ent) or not ent.swtor_type then return end
    local sid = ply:SteamID()

    -- ── HOLOCRON ──────────────────────────────────────────
    if ent.swtor_type == "holocron" then
        -- Vérifier faction
        if ent.swtor_faction and ent.swtor_faction ~= ply.swtor_faction then
            SWTOR.Notify(ply, "Cet Holocron n'est pas destiné à votre faction.", "error")
            return true
        end
        -- Déjà utilisé ?
        if ent.swtor_used[sid] then
            SWTOR.Notify(ply, "Vous avez déjà absorbé cet Holocron.", "warning")
            return true
        end

        ent.swtor_used[sid] = true
        ply.swtor_xp = (ply.swtor_xp or 0) + ent.swtor_xp
        SWTOR.SavePlayer(ply)
        SWTOR.SyncPlayerData(ply)
        SWTOR.Notify(ply, "📦 Holocron absorbé: +" .. ent.swtor_xp .. " XP !", "success")

        -- Clignoter puis disparaître
        timer.Simple(1, function()
            if IsValid(ent) then
                ent:SetColor(Color(255,255,255,0))
                ent:SetRenderMode(RENDERMODE_TRANSALPHA)
            end
        end)
        return true
    end

    -- ── TERMINAL ──────────────────────────────────────────
    if ent.swtor_type == "terminal" then
        if ent.swtor_faction and ent.swtor_faction ~= ply.swtor_faction then
            SWTOR.Notify(ply, "Terminal réservé à la faction " .. ent.swtor_faction, "error")
            return true
        end
        if ent.swtor_planet then
            SWTOR.Notify(ply, "Terminal: Destination → " .. ent.swtor_label, "info")
            timer.Simple(2, function()
                if IsValid(ply) then
                    SWTOR.TeleportToPlanet(ply, ent.swtor_planet)
                end
            end)
        end
        return true
    end

    -- ── CAISSE ────────────────────────────────────────────
    if ent.swtor_type == "crate" then
        if not ent.swtor_active then
            SWTOR.Notify(ply, "Cette caisse est vide. Réapparition dans quelques minutes.", "warning")
            return true
        end
        ent.swtor_active = false
        SWTOR.GiveCredits(ply, ent.swtor_credits)
        SWTOR.Notify(ply, "💰 Caisse pillée: +" .. ent.swtor_credits .. " crédits !", "credits")

        -- Changer la texture
        ent:SetModel("models/props_junk/wood_crate001a_damaged.mdl")

        -- Respawn
        timer.Simple(ent.swtor_respawn, function()
            if IsValid(ent) then
                ent.swtor_active = true
                ent:SetModel("models/props_junk/wood_crate001a.mdl")
            end
        end)
        return true
    end
end)

-- ============================================================
--  SPAWNER D'ENTITÉS PAR ADMIN
-- ============================================================
net.Receive("SWTOR_SpawnEntity", function(len, ply)
    if not SWTOR.IsAdmin(ply) then return end
    local eType   = net.ReadString()
    local pos     = ply:GetEyeTrace().HitPos + Vector(0,0,10)

    if eType == "holocron_empire" then
        SpawnHolocron(pos, "empire", 200, "Holocron Sith")
        SWTOR.Notify(ply, "Holocron Sith spawné.", "success")

    elseif eType == "holocron_republique" then
        SpawnHolocron(pos, "republique", 200, "Holocron Jedi")
        SWTOR.Notify(ply, "Holocron Jedi spawné.", "success")

    elseif eType == "terminal" then
        local planet = net.ReadString()
        SpawnTerminal(pos, planet, nil)
        SWTOR.Notify(ply, "Terminal → " .. planet .. " spawné.", "success")

    elseif eType == "crate" then
        SpawnCrate(pos, 150, 300)
        SWTOR.Notify(ply, "Caisse de ressources spawnée.", "success")
    end
end)

-- ============================================================
--  COMMANDES CONSOLE SPAWN ENTITÉS
-- ============================================================
concommand.Add("swtor_spawn_holocron", function(ply, cmd, args)
    if IsValid(ply) and not SWTOR.IsAdmin(ply) then return end
    local faction = args[1] or "empire"
    local xp      = tonumber(args[2]) or 200
    local pos     = IsValid(ply) and (ply:GetEyeTrace().HitPos + Vector(0,0,10)) or Vector(0,0,64)
    SpawnHolocron(pos, faction, xp, "Holocron " .. faction)
    if IsValid(ply) then ply:ChatPrint("[SWTOR] Holocron spawné.") end
end)

concommand.Add("swtor_spawn_crate", function(ply, cmd, args)
    if IsValid(ply) and not SWTOR.IsAdmin(ply) then return end
    local credits = tonumber(args[1]) or 150
    local pos     = IsValid(ply) and (ply:GetEyeTrace().HitPos + Vector(0,0,10)) or Vector(0,0,64)
    SpawnCrate(pos, credits, 300)
    if IsValid(ply) then ply:ChatPrint("[SWTOR] Caisse spawnée (" .. credits .. " cr).") end
end)

print("[SW:TOR] Entités interactives chargées ✓")
print("  swtor_spawn_holocron <faction> [xp]")
print("  swtor_spawn_crate [credits]")
