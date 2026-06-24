-- ============================================================
--  SW:TOR RP — SWING LABEL (feedback visuel du coup)
--  autorun/server/sv_swtor_swinglabel.lua
--  Envoie le nom du coup aux clients après chaque attaque
-- ============================================================

if CLIENT then return end

util.AddNetworkString("SWTOR_SwingLabel")

-- Hook sur chaque attaque — détecter l'arme et envoyer le label
hook.Add("PlayerAttackSound", "SWTOR_SwingFeedback", function(ply)
    -- Pas le hook idéal, on passe par l'arme directement
end)

-- Appelé par les SWEP via SharedAutorun
function SWTOR.SendSwingLabel(ply, moveName)
    if not IsValid(ply) or not moveName then return end
    net.Start("SWTOR_SwingLabel")
        net.WriteString(moveName)
    net.Send(ply)
end

-- ── Forcer AddCSLuaFile pour les nouvelles armes ──────────
if SERVER then
    AddCSLuaFile("weapons/swtor_lightsaber/shared.lua")
    AddCSLuaFile("weapons/swtor_lightsaber_dual/shared.lua")
    AddCSLuaFile("weapons/swtor_lightsaber_double/shared.lua")
    AddCSLuaFile("weapons/swtor_vibroblade/shared.lua")
    
    AddCSLuaFile("sh_swtor_combat_dirs.lua")
end

print("[SW:TOR] SwingLabel serveur chargé ✓")
