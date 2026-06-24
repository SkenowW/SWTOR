-- ============================================================
--  SW:TOR RP — ABILITIES ENGINE (Compétences par classe)
--  lua/autorun/server/sv_swtor_abilities.lua
--  Gère toutes les compétences définies dans sh_swtor_classes.lua
--  Effets 3D envoyés aux clients via net
-- ============================================================

if CLIENT then return end

util.AddNetworkString("SWTOR_UseAbility")
util.AddNetworkString("SWTOR_AbilityEffect")
util.AddNetworkString("SWTOR_AbilityCooldown")

SWTOR.AbilityCDs = {}  -- [steamid_abilityid] = CurTime() + cd

-- ============================================================
--  DICTIONNAIRE DES EFFETS — paramètres de chaque ability
-- ============================================================
local AbilityDefs = {

    -- ════════════════ EMPIRE SITH ════════════════

    force_push_dark = {
        cost_energy = 20, cd = 8,
        desc        = "Répulsion Sith — Projette les ennemis",
        execute     = function(ply, target)
            local radius = 350
            local pushed = 0
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), radius)) do
                if IsValid(ent) and ent ~= ply and (ent:IsPlayer() or ent:IsNPC()) then
                    local dir = (ent:GetPos() - ply:GetPos()):GetNormalized()
                    ent:SetVelocity(dir * 700 + Vector(0,0,250))
                    if ent:IsPlayer() then ent:TakeDamage(10, ply, ply) end
                    pushed = pushed + 1
                end
            end
            -- Effet visuel envoyé aux clients proches
            SWTOR.BroadcastEffect("force_push", ply:GetPos(), ply:GetAngles(),
                Color(180, 40, 220), radius)
            SWTOR.Notify(ply, "💨 Répulsion: " .. pushed .. " cibles projetées", "success")
        end,
    },

    saber_throw = {
        cost_energy = 30, cd = 12,
        desc        = "Lancer de Sabre — Lance le sabre sur la cible",
        execute     = function(ply, target)
            local tr = ply:GetEyeTrace()
            local endPos = tr.HitPos
            local dmg = 25 + math.floor((ply.swtor_stat_force or 10) * 2)
            if IsValid(tr.Entity) and (tr.Entity:IsPlayer() or tr.Entity:IsNPC()) then
                tr.Entity:TakeDamage(dmg, ply, ply)
                SWTOR.Notify(ply, "🌀 Sabre lancé: " .. dmg .. " dmg", "success")
            end
            SWTOR.BroadcastEffect("saber_throw", ply:GetPos(), (endPos - ply:GetPos()):Angle(),
                SWTOR.GetSaberColor(ply), 0)
        end,
    },

    force_charge = {
        cost_energy = 25, cd = 10,
        desc        = "Assaut Force — Charge vers la cible",
        execute     = function(ply, target)
            local tr = ply:GetEyeTrace()
            local dest = tr.HitPos - ply:EyeAngles():Forward() * 60
            dest.z = dest.z + 10
            ply:SetPos(dest)
            ply:SetVelocity(ply:EyeAngles():Forward() * 200)
            -- Dégâts à l'arrivée
            for _, ent in ipairs(ents.FindInSphere(dest, 80)) do
                if IsValid(ent) and ent ~= ply and (ent:IsPlayer() or ent:IsNPC()) then
                    ent:TakeDamage(20, ply, ply)
                    ent:SetVelocity(Vector(0,0,300))
                end
            end
            SWTOR.BroadcastEffect("force_charge", ply:GetPos(), ply:GetAngles(),
                Color(220, 40, 40), 80)
            SWTOR.Notify(ply, "⚡ Assaut Force!", "success")
        end,
    },

    force_choke = {
        cost_energy = 35, cd = 20,
        desc        = "Étranglement — Soulève et étouffe pendant 3s",
        execute     = function(ply, target)
            local tr = ply:GetEyeTrace()
            if not IsValid(tr.Entity) or not tr.Entity:IsPlayer() then
                SWTOR.Notify(ply, "Aucune cible valide.", "error") return
            end
            local victim = tr.Entity
            victim:SetVelocity(Vector(0, 0, 300))
            -- Bloquer le mouvement pendant 3s
            victim:SetMoveType(MOVETYPE_NONE)
            timer.Simple(3, function()
                if IsValid(victim) then
                    victim:SetMoveType(MOVETYPE_WALK)
                    victim:TakeDamage(30, ply, ply)
                    SWTOR.Notify(victim, "💀 L'étranglement prend fin.", "error")
                end
            end)
            SWTOR.BroadcastEffect("force_choke", victim:GetPos(), victim:GetAngles(),
                Color(180, 0, 200), 0)
            SWTOR.Notify(ply, "🤚 Étranglement: " .. victim:Nick(), "success")
        end,
    },

    blade_storm = {
        cost_energy = 45, cd = 18,
        desc        = "Tempête de Lames — Dégâts en zone large",
        execute     = function(ply, target)
            local radius = 200
            local dmg    = 40 + math.floor((ply.swtor_stat_force or 10) * 2.5)
            local hit    = 0
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), radius)) do
                if IsValid(ent) and ent ~= ply and (ent:IsPlayer() or ent:IsNPC()) then
                    ent:TakeDamage(dmg, ply, ply)
                    hit = hit + 1
                end
            end
            SWTOR.BroadcastEffect("blade_storm", ply:GetPos(), ply:GetAngles(),
                SWTOR.GetSaberColor(ply), radius)
            SWTOR.Notify(ply, "🌪 Tempête de Lames: " .. dmg .. " dmg × " .. hit, "success")
        end,
    },

    force_crush = {
        cost_energy = 50, cd = 25,
        desc        = "Écrasement Force — Dégâts massifs sur une cible",
        execute     = function(ply, target)
            local tr = ply:GetEyeTrace()
            if not IsValid(tr.Entity) then SWTOR.Notify(ply, "Aucune cible.", "error") return end
            local dmg = 80 + math.floor((ply.swtor_stat_force or 10) * 3)
            tr.Entity:TakeDamage(dmg, ply, ply)
            tr.Entity:SetVelocity(Vector(0, 0, -800))
            SWTOR.BroadcastEffect("force_crush", tr.Entity:GetPos(), tr.Entity:GetAngles(),
                Color(150, 0, 200), 0)
            SWTOR.Notify(ply, "💥 Écrasement: " .. dmg .. " dmg!", "success")
        end,
    },

    force_lightning = {
        cost_energy = 30, cd = 15,
        desc        = "Foudre de Force — Décharge électrique chaînée",
        execute     = function(ply, target)
            local tr    = ply:GetEyeTrace()
            local dmg   = 35 + math.floor((ply.swtor_stat_energy or 10) * 2)
            local targets = {}
            if IsValid(tr.Entity) and (tr.Entity:IsPlayer() or tr.Entity:IsNPC()) then
                table.insert(targets, tr.Entity)
                -- Chain lightning si passif débloqué
                local cls = SWTOR.Classes and SWTOR.Classes[ply.swtor_class or ""]
                if cls and cls.passive and cls.passive.lightning_chain then
                    for _, ent in ipairs(ents.FindInSphere(tr.Entity:GetPos(), 250)) do
                        if IsValid(ent) and ent ~= ply and ent ~= tr.Entity and
                           (ent:IsPlayer() or ent:IsNPC()) and #targets < 3 then
                            table.insert(targets, ent)
                        end
                    end
                end
            end
            for i, tgt in ipairs(targets) do
                local chainDmg = math.floor(dmg * (1 - (i-1)*0.3))
                tgt:TakeDamage(chainDmg, ply, ply)
                tgt:SetVelocity(VectorRand() * 150)
                SWTOR.BroadcastEffect("lightning", tgt:GetPos(), tgt:GetAngles(),
                    Color(180, 100, 255), 0)
            end
            SWTOR.Notify(ply, "⚡ Foudre: " .. dmg .. " dmg × " .. #targets .. " cible(s)", "success")
        end,
    },

    force_storm = {
        cost_energy = 60, cd = 30,
        desc        = "Tempête de Force — Dégâts en zone, 5s",
        execute     = function(ply, target)
            local center = ply:GetEyeTrace().HitPos
            SWTOR.BroadcastEffect("force_storm", center, Angle(0,0,0), Color(100,0,220), 300)
            for tick = 1, 5 do
                timer.Simple(tick, function()
                    if not IsValid(ply) then return end
                    for _, ent in ipairs(ents.FindInSphere(center, 300)) do
                        if IsValid(ent) and ent ~= ply and (ent:IsPlayer() or ent:IsNPC()) then
                            ent:TakeDamage(15, ply, ply)
                        end
                    end
                end)
            end
            SWTOR.Notify(ply, "🌩 Tempête de Force déclenchée !", "success")
        end,
    },

    dark_heal = {
        cost_energy = 40, cd = 20,
        desc        = "Soin Obscur — Draine la vie de la cible",
        execute     = function(ply, target)
            local tr = ply:GetEyeTrace()
            local drain = 40 + math.floor((ply.swtor_stat_energy or 10) * 1.5)
            if IsValid(tr.Entity) and tr.Entity:IsPlayer() then
                tr.Entity:TakeDamage(drain, ply, ply)
                local heal = math.floor(drain * 0.6)
                ply:SetHealth(math.min(ply:Health() + heal, ply:GetMaxHealth()))
                SWTOR.BroadcastEffect("dark_heal", ply:GetPos(), ply:GetAngles(), Color(150,0,180), 0)
                SWTOR.Notify(ply, "💜 Drain: +" .. heal .. " HP absorbés", "success")
            else
                SWTOR.Notify(ply, "Aucune cible joueur.", "error")
            end
        end,
    },

    phase_walk = {
        cost_energy = 50, cd = 45,
        desc        = "Marche Fantôme — Téléportation vers votre ancre",
        execute     = function(ply, target)
            if not ply.swtor_phase_anchor then
                ply.swtor_phase_anchor = ply:GetPos()
                SWTOR.Notify(ply, "👻 Ancre placée ici. Réutilisez pour téléporter.", "info")
                -- Reset CD pour permettre le retour
                SWTOR.AbilityCDs[ply:SteamID() .. "_phase_walk"] = CurTime() + 5
                return
            end
            local anchor = ply.swtor_phase_anchor
            ply.swtor_phase_anchor = nil
            SWTOR.BroadcastEffect("phase_walk", ply:GetPos(), ply:GetAngles(), Color(180,0,220), 0)
            ply:SetPos(anchor)
            SWTOR.BroadcastEffect("phase_walk", anchor, ply:GetAngles(), Color(180,0,220), 0)
            SWTOR.Notify(ply, "👻 Téléportation vers l'ancre !", "success")
        end,
    },

    -- ════════════════ REPUBLIQUE / JEDI ════════════════

    force_push_jedi = {
        cost_energy = 20, cd = 8,
        desc        = "Répulsion Jedi — Projette les ennemis",
        execute     = function(ply, target)
            local radius = 320
            local pushed = 0
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), radius)) do
                if IsValid(ent) and ent ~= ply and (ent:IsPlayer() or ent:IsNPC()) then
                    if ent.swtor_faction ~= ply.swtor_faction then
                        local dir = (ent:GetPos() - ply:GetPos()):GetNormalized()
                        ent:SetVelocity(dir * 650 + Vector(0,0,200))
                        if ent:IsPlayer() then ent:TakeDamage(8, ply, ply) end
                        pushed = pushed + 1
                    end
                end
            end
            SWTOR.BroadcastEffect("force_push", ply:GetPos(), ply:GetAngles(),
                Color(50, 130, 255), radius)
            SWTOR.Notify(ply, "💨 Répulsion: " .. pushed .. " cibles", "success")
        end,
    },

    force_heal = {
        cost_energy = 40, cd = 20,
        desc        = "Soin de Force — Restaure les HP",
        execute     = function(ply, target)
            local energyStat = ply.swtor_stat_energy or 10
            local cls        = SWTOR.Classes and SWTOR.Classes[ply.swtor_class or ""]
            local mult       = cls and cls.passive and cls.passive.heal_bonus or 1.0
            local healAmt    = math.floor((50 + energyStat * 2) * mult)
            ply:SetHealth(math.min(ply:Health() + healAmt, ply:GetMaxHealth()))
            SWTOR.BroadcastEffect("force_heal", ply:GetPos(), ply:GetAngles(), Color(0,220,100), 0)
            SWTOR.Notify(ply, "💚 Soin: +" .. healAmt .. " HP", "success")
        end,
    },

    force_stasis = {
        cost_energy = 35, cd = 22,
        desc        = "Stase de Force — Immobilise la cible",
        execute     = function(ply, target)
            local tr = ply:GetEyeTrace()
            if not IsValid(tr.Entity) or not tr.Entity:IsPlayer() then
                SWTOR.Notify(ply, "Aucune cible valide.", "error") return
            end
            local victim = tr.Entity
            victim:SetMoveType(MOVETYPE_NONE)
            SWTOR.BroadcastEffect("stasis", victim:GetPos(), victim:GetAngles(), Color(50,180,255), 0)
            timer.Simple(4, function()
                if IsValid(victim) then
                    victim:SetMoveType(MOVETYPE_WALK)
                    SWTOR.Notify(victim, "❄ Stase levée.", "info")
                end
            end)
            SWTOR.Notify(ply, "❄ Stase sur " .. victim:Nick() .. " — 4s", "success")
        end,
    },

    rescue = {
        cost_energy = 30, cd = 30,
        desc        = "Sauvetage — Téléporte un allié vers vous",
        execute     = function(ply, target)
            local tr = ply:GetEyeTrace()
            if IsValid(tr.Entity) and tr.Entity:IsPlayer() and
               tr.Entity.swtor_faction == ply.swtor_faction then
                local ally = tr.Entity
                SWTOR.BroadcastEffect("rescue", ally:GetPos(), ally:GetAngles(), Color(0,180,255), 0)
                ally:SetPos(ply:GetPos() + ply:GetAngles():Right() * 60)
                SWTOR.BroadcastEffect("rescue", ply:GetPos(), ply:GetAngles(), Color(0,180,255), 0)
                SWTOR.Notify(ally, "🤝 Sauvé par " .. ply:Nick() .. " !", "success")
                SWTOR.Notify(ply,  "🤝 " .. ally:Nick() .. " sauvé !", "success")
            else
                SWTOR.Notify(ply, "Visez un allié de votre faction.", "error")
            end
        end,
    },

    force_armor = {
        cost_energy = 35, cd = 25,
        desc        = "Armure de Force — Bouclier temporaire 10s",
        execute     = function(ply, target)
            ply:SetArmor(100)
            ply.swtor_force_armor = true
            SWTOR.BroadcastEffect("force_armor", ply:GetPos(), ply:GetAngles(), Color(0,150,255), 0)
            timer.Simple(10, function()
                if IsValid(ply) then
                    ply.swtor_force_armor = false
                    SWTOR.Notify(ply, "🔵 Armure de Force expirée.", "info")
                end
            end)
            SWTOR.Notify(ply, "🔵 Armure de Force activée — 10s", "success")
        end,
    },

    -- ════════════════ MANDALORIEN ════════════════

    jet_boost = {
        cost_energy = 20, cd = 8,
        desc        = "Propulsion Jet — Double saut vers l'avant",
        execute     = function(ply, target)
            local dir = ply:EyeAngles():Forward()
            dir.z     = 0.6
            ply:SetVelocity(dir * 800)
            SWTOR.BroadcastEffect("jetpack", ply:GetPos(), ply:GetAngles(), Color(255,180,0), 0)
            SWTOR.Notify(ply, "🚀 Propulsion !", "success")
        end,
    },

    flamethrower = {
        cost_energy = 40, cd = 18,
        desc        = "Lance-Flammes — Dégâts de feu en cône devant vous",
        execute     = function(ply, target)
            local forward = ply:EyeAngles():Forward()
            local hit     = 0
            local dmg     = 25 + math.floor((ply.swtor_stat_energy or 10) * 1.2)
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 220)) do
                if IsValid(ent) and ent ~= ply and (ent:IsPlayer() or ent:IsNPC()) then
                    local toEnt = (ent:GetPos() - ply:GetPos()):GetNormalized()
                    if forward:Dot(toEnt) > 0.5 then  -- Cône 60°
                        ent:TakeDamage(dmg, ply, ply)
                        ent:Ignite(3, false)
                        hit = hit + 1
                    end
                end
            end
            SWTOR.BroadcastEffect("flamethrower", ply:GetPos(), ply:GetAngles(), Color(255,120,0), 220)
            SWTOR.Notify(ply, "🔥 Lance-Flammes: " .. dmg .. " dmg × " .. hit, "success")
        end,
    },

    death_from_above = {
        cost_energy = 50, cd = 22,
        desc        = "Frappe Aérienne — S'élève et frappe en zone",
        execute     = function(ply, target)
            -- S'élever
            ply:SetVelocity(Vector(0, 0, 500))
            timer.Simple(1.2, function()
                if not IsValid(ply) then return end
                local landPos = ply:GetPos()
                ply:SetVelocity(Vector(0, 0, -1200))
                timer.Simple(0.5, function()
                    if not IsValid(ply) then return end
                    local dmg = 60 + math.floor((ply.swtor_stat_force or 10) * 2)
                    for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 180)) do
                        if IsValid(ent) and ent ~= ply and (ent:IsPlayer() or ent:IsNPC()) then
                            ent:TakeDamage(dmg, ply, ply)
                            ent:SetVelocity(VectorRand() * 400 + Vector(0,0,200))
                        end
                    end
                    SWTOR.BroadcastEffect("landing_shockwave", ply:GetPos(),
                        ply:GetAngles(), Color(255, 180, 0), 180)
                    SWTOR.Notify(ply, "☄ Frappe Aérienne: " .. dmg .. " dmg !", "success")
                end)
            end)
        end,
    },

    war_cry = {
        cost_energy = 25, cd = 30,
        desc        = "Cri de Guerre — Booste tous les alliés proches",
        execute     = function(ply, target)
            local buffed = 0
            for _, ally in ipairs(player.GetAll()) do
                if IsValid(ally) and ally.swtor_faction == ply.swtor_faction and
                   ally:GetPos():Distance(ply:GetPos()) < 500 then
                    -- +20% dégâts 15s (via NWBool)
                    ally:SetNWBool("swtor_war_cry", true)
                    timer.Simple(15, function()
                        if IsValid(ally) then ally:SetNWBool("swtor_war_cry", false) end
                    end)
                    SWTOR.Notify(ally, "😤 Cri de Guerre de " .. ply:Nick() .. " — +dégâts 15s !", "success")
                    buffed = buffed + 1
                end
            end
            SWTOR.BroadcastEffect("war_cry", ply:GetPos(), ply:GetAngles(), Color(200,140,20), 500)
            SWTOR.Notify(ply, "😤 Cri de Guerre: " .. buffed .. " alliés boostés !", "success")
        end,
    },

    frag_grenade = {
        cost_energy = 15, cd = 12,
        desc        = "Grenade — Explosion en zone",
        execute     = function(ply, target)
            local tr     = ply:GetEyeTrace()
            local dest   = tr.HitPos
            local dmg    = 50 + math.floor((ply.swtor_stat_energy or 10) * 1.5)
            timer.Simple(1.5, function()  -- Délai grenade
                for _, ent in ipairs(ents.FindInSphere(dest, 200)) do
                    if IsValid(ent) and ent ~= ply and (ent:IsPlayer() or ent:IsNPC()) then
                        local dist  = ent:GetPos():Distance(dest)
                        local falloff = 1 - (dist / 200)
                        ent:TakeDamage(math.floor(dmg * falloff), ply, ply)
                        ent:SetVelocity(((ent:GetPos()-dest):GetNormalized()) * 400 + Vector(0,0,150))
                    end
                end
                SWTOR.BroadcastEffect("explosion", dest, Angle(0,0,0), Color(255,160,0), 200)
            end)
            SWTOR.Notify(ply, "💣 Grenade lancée !", "success")
        end,
    },

    adrenaline_rush = {
        cost_energy = 30, cd = 35,
        desc        = "Rush Adrénaline — Régénère rapidement la vie",
        execute     = function(ply, target)
            SWTOR.Notify(ply, "💪 Adrénaline — Régénération 5s !", "success")
            for i = 1, 5 do
                timer.Simple(i, function()
                    if IsValid(ply) then
                        ply:SetHealth(math.min(ply:Health() + 20, ply:GetMaxHealth()))
                    end
                end)
            end
        end,
    },

    dirty_kick = {
        cost_energy = 10, cd = 6,
        desc        = "Coup Bas — Étourdit brièvement la cible",
        execute     = function(ply, target)
            local tr = ply:GetEyeTrace()
            if IsValid(tr.Entity) and tr.Entity:IsPlayer() and
               tr.HitPos:Distance(ply:GetPos()) < 100 then
                tr.Entity:SetMoveType(MOVETYPE_NONE)
                tr.Entity:TakeDamage(15, ply, ply)
                timer.Simple(1.5, function()
                    if IsValid(tr.Entity) then tr.Entity:SetMoveType(MOVETYPE_WALK) end
                end)
                SWTOR.Notify(ply, "🦶 Coup Bas — " .. tr.Entity:Nick() .. " étourdi 1.5s", "success")
            else
                SWTOR.Notify(ply, "Cible trop loin (max 100u).", "error")
            end
        end,
    },
}

-- ============================================================
--  BROADCAST EFFECT (envoi aux clients proches)
-- ============================================================
util.AddNetworkString("SWTOR_PlayEffect")

function SWTOR.BroadcastEffect(effectId, pos, ang, col, radius)
    local receivers = {}
    for _, ply in ipairs(player.GetAll()) do
        if ply:GetPos():Distance(pos) < 2000 then
            table.insert(receivers, ply)
        end
    end
    if #receivers == 0 then return end

    net.Start("SWTOR_PlayEffect")
        net.WriteString(effectId)
        net.WriteVector(pos)
        net.WriteAngle(ang)
        net.WriteUInt(col.r, 8)
        net.WriteUInt(col.g, 8)
        net.WriteUInt(col.b, 8)
        net.WriteUInt(math.floor(radius), 16)
    net.Send(receivers)
end

function SWTOR.GetSaberColor(ply)
    local faction = ply.swtor_faction or ""
    if faction == "empire"      then return Color(255, 30, 30)  end
    if faction == "republique"  then return Color(30, 130, 255) end
    if faction == "mandalorien" then return Color(255, 180, 0)  end
    return Color(255, 255, 255)
end

-- ============================================================
--  RÉCEPTION DE L'ABILITY DEPUIS LE CLIENT
-- ============================================================
net.Receive("SWTOR_UseAbility", function(len, ply)
    local abilityId = net.ReadString()
    local def       = AbilityDefs[abilityId]

    if not def then
        SWTOR.Notify(ply, "Ability inconnue: " .. abilityId, "error")
        return
    end

    -- 1) Vérifier que la classe possède l'ability
    if not SWTOR.HasAbility(ply, abilityId) then
        SWTOR.Notify(ply, "Vous n'avez pas encore débloqué: " .. abilityId, "error")
        return
    end

    -- 1b) Vérifier restriction HRP (Étranglement, Champ de Mort = Responsable+)
    local hrpReq = SWTOR.GetAbilityHRPReq and SWTOR.GetAbilityHRPReq(ply, abilityId)
    if hrpReq and hrpReq > 0 then
        local plyLevel = SWTOR.HRP and SWTOR.HRP.GetLevel(ply) or 0
        if plyLevel < hrpReq then
            SWTOR.Notify(ply, "⛔ Pouvoir réservé aux Responsables et Fondateurs.", "error")
            return
        end
    end

    -- 2) Cooldown
    local cdKey = ply:SteamID() .. "_" .. abilityId
    if SWTOR.AbilityCDs[cdKey] and SWTOR.AbilityCDs[cdKey] > CurTime() then
        local remaining = math.ceil(SWTOR.AbilityCDs[cdKey] - CurTime())
        SWTOR.Notify(ply, "Recharge: " .. remaining .. "s — " .. abilityId, "warning")
        return
    end

    -- 3) Coût Énergie
    local energyCost = def.cost_energy or 0
    local curEnergy  = ply.swtor_current_energy or 100
    if curEnergy < energyCost then
        SWTOR.Notify(ply, "Énergie insuffisante (" .. curEnergy .. "/" .. energyCost .. ")", "error")
        return
    end

    -- 4) Appliquer le coût
    ply.swtor_current_energy = curEnergy - energyCost

    -- 5) Mettre en cooldown
    SWTOR.AbilityCDs[cdKey] = CurTime() + (def.cd or 10)

    -- 6) Exécuter l'ability
    def.execute(ply, nil)

    -- 7) Sync énergie
    SWTOR.SyncPlayerData(ply)
end)

-- ============================================================
--  RÉGÉNÉRATION ÉNERGIE EN JEU (0.5/s, +bonus stat energy)
-- ============================================================
timer.Create("SWTOR_EnergyRegen", 0.5, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() and ply.swtor_class and ply.swtor_class ~= "" then
            local cls    = SWTOR.Classes and SWTOR.Classes[ply.swtor_class]
            local maxE   = cls and cls.stats.force_max or 100
            -- Bonus max depuis stat energy
            maxE = maxE + math.floor((ply.swtor_stat_energy or 10) * 2)
            local regenRate = (cls and cls.stats.force_regen or 5)
            -- Regen doublée si pas en combat (dernier dégât > 5s)
            local lastDmg = ply.swtor_last_damage or 0
            if CurTime() - lastDmg > 5 then regenRate = regenRate * 2 end

            ply.swtor_current_energy = math.min(
                (ply.swtor_current_energy or maxE) + regenRate * 0.5,
                maxE
            )
        end
    end
end)

-- Track le dernier dégât reçu pour regen
hook.Add("EntityTakeDamage", "SWTOR_TrackDamage", function(target, dmginfo)
    if target:IsPlayer() then
        target.swtor_last_damage = CurTime()
    end
end)

print("[SW:TOR] Abilities Engine chargé ✓ (" .. table.Count(AbilityDefs) .. " abilities)")
