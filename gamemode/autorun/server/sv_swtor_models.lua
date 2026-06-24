-- ============================================================
--  SW:TOR RP - SERVEUR: Gestion des modèles (vestiaire)
--  Fichier: lua/autorun/server/sv_swtor_models.lua
--  Coller dans: garrysmod/lua/autorun/server/
-- ============================================================

if CLIENT then return end

util.AddNetworkString("SWTOR_SetModel")
util.AddNetworkString("SWTOR_ModelApplied")

net.Receive("SWTOR_SetModel", function(len, ply)
    local model = net.ReadString()

    -- Vérifier que le modèle appartient bien à la faction du joueur
    local faction = ply.swtor_faction or ""
    local outfits = SWTOR and SWTOR.Outfits and SWTOR.Outfits[faction]

    if not outfits then
        SWTOR.Notify(ply, "Aucune tenue disponible pour votre faction.", "error")
        return
    end

    local allowed = false
    for _, outfit in ipairs(outfits) do
        if outfit.model == model then
            allowed = true
            break
        end
    end

    if not allowed then
        SWTOR.Notify(ply, "Tenue non autorisée pour votre faction.", "error")
        return
    end

    ply:SetModel(model)
    ply.swtor_model = model
    SWTOR.SavePlayer(ply)

    net.Start("SWTOR_ModelApplied")
        net.WriteString(model)
    net.Send(ply)
end)

print("[SW:TOR RP] Gestion modèles serveur chargée ✓")
