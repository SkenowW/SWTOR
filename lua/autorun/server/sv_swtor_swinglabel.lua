-- ============================================================
--  SW:TOR RP — SWING LABEL (feedback visuel du coup)
--  lua/autorun/server/sv_swtor_swinglabel.lua
-- ============================================================

if CLIENT then return end

util.AddNetworkString("SWTOR_SwingLabel")

-- Appelé par les SWEP via SharedAutorun
function SWTOR.SendSwingLabel(ply, moveName)
    if not IsValid(ply) or not moveName then return end
    net.Start("SWTOR_SwingLabel")
        net.WriteString(moveName)
    net.Send(ply)
end

print("[SW:TOR] SwingLabel serveur chargé ✓")