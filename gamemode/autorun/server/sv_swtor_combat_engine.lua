-- ============================================================
--  SW:TOR RP — COMBAT AVANCÉ SERVEUR (style wOS)
--  lua/autorun/server/sv_swtor_combat_engine.lua
-- ============================================================

if CLIENT then return end

util.AddNetworkString("SWTOR_StanceChange")
util.AddNetworkString("SWTOR_Clash")
util.AddNetworkString("SWTOR_LockOn")
util.AddNetworkString("SWTOR_ComboUpdate")

-- ============================================================
--  CHANGEMENT DE POSTURE (touche dédiée)
-- ============================================================
net.Receive("SWTOR_StanceChange", function(len, ply)
    local stance = net.ReadString()
    if not SWTOR.CombatEngine.Stances[stance] then return end

    ply.swtor_stance = stance
    ply:SetNWString("swtor_stance", stance)

    local sData = SWTOR.CombatEngine.Stances[stance]
    SWTOR.Notify(ply, sData.icon .. " " .. sData.name, "info")
    -- Posture = animation/style uniquement, aucun changement de stats
    -- Broadcast la posture pour l'animation
    ply:SetNWString("swtor_anim_set", sData.anim_set or "standard")
end)

-- ============================================================
--  SYSTÈME DE CLASH (deux sabres se rencontrent)
-- ============================================================
-- Quand deux joueurs attaquent en même temps et se touchent,
-- un "clash" se produit : les sabres s'entrechoquent

SWTOR.ClashCooldowns = {}

function SWTOR.CombatEngine.TryClash(att1, att2)
    if not IsValid(att1) or not IsValid(att2) then return false end

    local id = att1:SteamID() .. att2:SteamID()
    if SWTOR.ClashCooldowns[id] and SWTOR.ClashCooldowns[id] > CurTime() then
        return false
    end

    -- Les deux doivent attaquer dans une fenêtre proche
    local t1 = att1.swtor_last_swing or 0
    local t2 = att2.swtor_last_swing or 0
    if math.abs(t1 - t2) > 0.25 then return false end  -- Pas synchronisé

    -- Distance proche
    if att1:GetPos():Distance(att2:GetPos()) > 120 then return false end

    -- CLASH !
    SWTOR.ClashCooldowns[id] = CurTime() + 1.5

    -- Comparer la "force" du clash (stamina + posture + stat force)
    local power1 = (att1.swtor_stamina or 100) +
                   (SWTOR.CombatEngine.GetStance(att1).dmg_mult * 30) +
                   (att1.swtor_stat_force or 10) * 2
    local power2 = (att2.swtor_stamina or 100) +
                   (SWTOR.CombatEngine.GetStance(att2).dmg_mult * 30) +
                   (att2.swtor_stat_force or 10) * 2

    -- Le perdant du clash est repoussé et stun brièvement
    local winner, loser
    if power1 > power2 then winner, loser = att1, att2
    else winner, loser = att2, att1 end

    -- Effets
    local midPos = (att1:GetPos() + att2:GetPos()) * 0.5 + Vector(0,0,40)

    -- Repousser le perdant
    local pushDir = (loser:GetPos() - winner:GetPos()):GetNormalized()
    loser:SetVelocity(pushDir * 250 + Vector(0,0,100))
    loser.swtor_stagger_until = CurTime() + 0.8
    SWTOR.CombatEngine.UseStamina(loser, 25)

    -- Le gagnant garde l'avantage
    SWTOR.CombatEngine.UseStamina(winner, 10)

    -- Broadcast effet visuel clash
    net.Start("SWTOR_Clash")
        net.WriteVector(midPos)
        net.WriteEntity(winner)
        net.WriteEntity(loser)
    net.Broadcast()

    -- Sons
    att1:EmitSound("weapons/lightsaber/saberhit" .. math.random(1,3) .. ".wav", 80, 100)

    SWTOR.Notify(winner, "⚔ Clash gagné ! Avantage pris.", "success")
    SWTOR.Notify(loser,  "⚔ Clash perdu ! Repoussé.", "warning")

    return true
end

-- ============================================================
--  LOCK-ON (verrouillage de cible)
-- ============================================================
net.Receive("SWTOR_LockOn", function(len, ply)
    local target = net.ReadEntity()

    if not IsValid(target) or not target:IsPlayer() then
        ply.swtor_lock_target = nil
        ply:SetNWEntity("swtor_lock", NULL)
        return
    end

    -- Vérifier distance
    if ply:GetPos():Distance(target:GetPos()) > 600 then
        SWTOR.Notify(ply, "Cible trop loin pour verrouiller.", "error")
        return
    end

    ply.swtor_lock_target = target
    ply:SetNWEntity("swtor_lock", target)
    SWTOR.Notify(ply, "🎯 Verrouillé sur " .. target:Nick(), "info")
end)

-- ============================================================
--  RÉGÉNÉRATION STAMINA (tick serveur)
-- ============================================================
timer.Create("SWTOR_StaminaRegen", 0.25, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() then
            -- Pas de régen pendant 1.5s après une attaque
            local lastSwing = ply.swtor_last_swing or 0
            if CurTime() - lastSwing > 1.5 then
                SWTOR.CombatEngine.RegenStamina(ply, 0.25)
            end
        end
    end
end)

-- ============================================================
--  HOOK — Enregistrer les swings pour le clash
-- ============================================================
function SWTOR.CombatEngine.RegisterSwing(ply)
    ply.swtor_last_swing = CurTime()

    -- Chercher un adversaire qui attaque aussi (clash)
    for _, other in ipairs(player.GetAll()) do
        if other ~= ply and IsValid(other) then
            local ot = other.swtor_last_swing or 0
            if CurTime() - ot < 0.25 then
                -- Vérifier qu'ils se font face
                local toOther = (other:GetPos() - ply:GetPos()):GetNormalized()
                local facing  = ply:EyeAngles():Forward():Dot(toOther)
                if facing > 0.5 then
                    SWTOR.CombatEngine.TryClash(ply, other)
                    break
                end
            end
        end
    end
end

-- ============================================================
--  COMBOS — Tracking serveur
-- ============================================================
function SWTOR.CombatEngine.UpdateCombo(ply)
    local form = SWTOR.CombatEngine.GetForm(ply)
    local now  = CurTime()

    if now - (ply.swtor_last_combo_t or 0) < form.combo_window then
        ply.swtor_combo = math.min((ply.swtor_combo or 0) + 1, form.combo_max)
    else
        ply.swtor_combo = 1
    end
    ply.swtor_last_combo_t = now
    ply:SetNWInt("swtor_combo", ply.swtor_combo)

    -- Coup spécial au combo max
    if ply.swtor_combo >= form.combo_max then
        return form.special  -- Retourne le nom du coup spécial
    end
    return nil
end

print("[SW:TOR] Combat avancé serveur chargé ✓ (clash, lock-on, stamina, combos)")

-- ============================================================
--  CHANGEMENT DE FORME (Djem So / Makashi pour voies sabre simple)
-- ============================================================
util.AddNetworkString("SWTOR_FormChange")

net.Receive("SWTOR_FormChange", function(len, ply)
    local form = net.ReadString()
    if not SWTOR.CombatEngine.Forms[form] then return end

    -- Vérifier que la forme est disponible pour ce joueur
    local avail = SWTOR.CombatEngine.GetAvailableForms(ply)
    local ok = false
    for _, f in ipairs(avail) do if f == form then ok = true break end end
    if not ok then
        SWTOR.Notify(ply, "Cette forme n'est pas disponible pour votre voie.", "error")
        return
    end

    ply.swtor_form = form
    ply:SetNWString("swtor_form", form)

    local fData = SWTOR.CombatEngine.Forms[form]
    SWTOR.Notify(ply, "🌀 Forme: " .. fData.name .. " — " .. fData.desc, "success")
end)
