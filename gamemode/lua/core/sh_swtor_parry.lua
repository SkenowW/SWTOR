-- ============================================================
--  SW:TOR RP — SYSTÈME DE PARADE (MAJ + Clic Gauche)
--  lua/autorun/sh_swtor_parry.lua
--  Partagé — utilisé par tous les SWEP de mêlée
-- ============================================================

SWTOR = SWTOR or {}
SWTOR.Parry = SWTOR.Parry or {}

-- ============================================================
--  ÉTATS DE PARADE PAR STYLE
-- ============================================================

SWTOR.Parry.Config = {
    parry_window    = 0.5,   -- 0.5s de fenêtre après MAJ+Clic
    parry_cooldown  = 2.0,   -- 2s de CD entre deux parades
    parry_stamina   = 30,    -- Coût en endurance (stamina) d'une parade

    style_bonus = {
        single  = { reflect = 0.8,  dmg_return = 0.4,  stagger_attacker = true  },
        dual    = { reflect = 0.6,  dmg_return = 0.2,  stagger_attacker = false },  -- Dual = esquive plutôt que bloc
        double  = { reflect = 0.95, dmg_return = 0.5,  stagger_attacker = true  },  -- Staff = meilleur bloqueur
        vibro   = { reflect = 0.7,  dmg_return = 0.35, stagger_attacker = true  },  -- Vibro ignore armure en retour
    },
}

-- ============================================================
--  HELPER PARTAGÉ — Peut-on parer ?
-- ============================================================
function SWTOR.Parry.CanParry(ply)
    if not IsValid(ply) then return false end
    
    -- Cooldown
    if ply.swtor_parry_cd and ply.swtor_parry_cd > CurTime() then
        return false, math.ceil(ply.swtor_parry_cd - CurTime())
    end
    
    -- CORRECTION : On utilise le vrai système de Stamina du Moteur de Combat
    local curStamina = SWTOR.CombatEngine and SWTOR.CombatEngine.GetStamina(ply) or 100
    if curStamina < SWTOR.Parry.Config.parry_stamina then
        return false, 0, "stamina"
    end
    
    return true
end

-- ============================================================
--  APPLIQUER UNE PARADE (côté serveur)
-- ============================================================
function SWTOR.Parry.DoParry(ply, style)
    if CLIENT then return end -- SÉCURITÉ : Seulement le serveur gère ça
    if not IsValid(ply) then return end
    
    local canParry, cd, reason = SWTOR.Parry.CanParry(ply)
    if not canParry then
        if reason == "stamina" then
            SWTOR.Notify(ply, "⚡ Endurance insuffisante pour parer !", "error")
        else
            SWTOR.Notify(ply, "⏱ Parade en recharge : " .. (cd or 0) .. "s", "warning")
        end
        return false
    end

    -- Activer la parade
    ply.swtor_is_parrying = true
    ply.swtor_parry_end   = CurTime() + SWTOR.Parry.Config.parry_window
    ply.swtor_parry_style = style or "single"
    ply.swtor_parry_cd    = CurTime() + SWTOR.Parry.Config.parry_cooldown

    -- CORRECTION : Déduire la Stamina via le Moteur de Combat
    if SWTOR.CombatEngine and SWTOR.CombatEngine.UseStamina then
        SWTOR.CombatEngine.UseStamina(ply, SWTOR.Parry.Config.parry_stamina)
    end

    -- Notifier
    local styleNames = { single="Parade", dual="Esquive", double="Bloc Total", vibro="Contre" }
    SWTOR.Notify(ply, "🛡 " .. (styleNames[style] or "Parade") .. " !", "info")

    -- Auto-désactiver après la fenêtre
    timer.Simple(SWTOR.Parry.Config.parry_window, function()
        if IsValid(ply) then
            ply.swtor_is_parrying = false
        end
    end)

    return true
end

-- ============================================================
--  VÉRIFIER PENDANT UN IMPACT (appelé depuis les SWEP / Hooks)
-- ============================================================
function SWTOR.Parry.CheckParry(attacker, victim, damage, style)
    if not IsValid(victim) then return damage, false end

    -- Parade active ?
    if not victim.swtor_is_parrying then return damage, false end
    if victim.swtor_parry_end and CurTime() > victim.swtor_parry_end then
        victim.swtor_is_parrying = false
        return damage, false
    end

    local parryStyle = victim.swtor_parry_style or "single"
    local cfg = SWTOR.Parry.Config.style_bonus[parryStyle] or SWTOR.Parry.Config.style_bonus["single"]

    -- Succès de parade !
    local dmgReturned = math.floor(damage * cfg.dmg_return)

    -- CORRECTION ANTI-CRASH : On retarde les dégâts d'une frame pour éviter une boucle infinie de hooks
    if IsValid(attacker) and attacker:IsPlayer() and dmgReturned > 0 then
        timer.Simple(0, function()
            if IsValid(attacker) and IsValid(victim) then
                attacker:TakeDamage(dmgReturned, victim, victim)
                SWTOR.Notify(attacker, "⚔ Parade ! " .. dmgReturned .. " dmg renvoyés !", "error")
            end
        end)
    end

    -- Stagger l'attaquant
    if cfg.stagger_attacker and IsValid(attacker) then
        attacker.swtor_stagger_until = CurTime() + 0.5
    end

    -- Effet visuel parade (broadcast)
    if SWTOR.BroadcastEffect then
        SWTOR.BroadcastEffect("force_push", victim:GetPos(), victim:GetAngles(),
            Color(200, 200, 255), 60)
    end

    -- Annuler les dégâts sur la victime (bloc total/partiel)
    local dmgToVictim = math.floor(damage * (1 - cfg.reflect))
    return dmgToVictim, true
end

print("[SW:TOR] Système de parade MAJ+Clic chargé ✓")