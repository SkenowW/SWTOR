-- ============================================================
--  SW:TOR RP — CHAT RP CLIENT (affichage)
--  lua/autorun/client/cl_swtor_chat.lua
-- ============================================================

if SERVER then return end

net.Receive("SWTOR_RPChat", function()
    local chatType = net.ReadUInt(4)
    local name     = net.ReadString()
    local faction  = net.ReadString()
    local grade    = net.ReadString()
    local msg      = net.ReadString()

    -- Couleur de faction
    local fColor = Color(200,200,200)
    if SWTOR and SWTOR.Factions then
        for k, f in pairs(SWTOR.Factions) do
            if f.shortname == faction then
                fColor = f.color
                break
            end
        end
    end

    if chatType == 0 then
        -- Chat normal: [FACTION | Grade] Nom: message
        chat.AddText(
            fColor,           "[" .. faction .. "] ",
            Color(180,180,180), "[" .. grade .. "] ",
            Color(255,255,255), name .. ": ",
            Color(230,230,230), msg
        )

    elseif chatType == 1 then
        -- /me
        chat.AddText(
            Color(200,150,255), "✦ " .. name .. " (" .. grade .. ") " .. msg
        )

    elseif chatType == 2 then
        -- /rp
        chat.AddText(
            Color(150,200,255), "📢 [RP] ",
            Color(220,220,220), name .. " (" .. grade .. "): ",
            Color(255,255,255), msg
        )

    elseif chatType == 3 then
        -- OOC
        chat.AddText(
            Color(120,120,120), "// [OOC] ",
            Color(160,160,160), name .. ": ",
            Color(180,180,180), msg
        )

    elseif chatType == 4 then
        -- Annonce admin
        chat.AddText(
            Color(255,200,0),   "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        )
        chat.AddText(
            Color(255,220,50),  "📣 [ANNONCE] ",
            Color(255,255,200), msg
        )
        chat.AddText(
            Color(255,200,0),   "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        )
        surface.PlaySound("buttons/button17.wav")

    elseif chatType == 5 then
        -- Event
        chat.AddText(
            Color(100,220,255), "⚡ [ÉVÉNEMENT] ",
            Color(200,240,255), msg
        )
        surface.PlaySound("buttons/lightswitch2.wav")

    elseif chatType == 6 then
        -- /do (description scène)
        chat.AddText(
            Color(200,220,100), "🎭 [SCÈNE] ",
            Color(220,230,160), msg,
            Color(150,160,100), " ~" .. name
        )
    end
end)

-- ============================================================
--  AIDE COMMANDES CHAT (F1)
-- ============================================================
hook.Add("PlayerBindPress", "SWTOR_HelpBind", function(ply, bind, pressed)
    if pressed and bind == "impulse 201" then  -- F1 par défaut dans certains gamemodes
        chat.AddText(Color(100,180,255), "═══ Commandes Chat SW:TOR ═══")
        chat.AddText(Color(200,200,255), "/me <action>      — Action RP (local)")
        chat.AddText(Color(200,200,255), "/rp <message>     — Message RP (local)")
        chat.AddText(Color(200,200,255), "// <message>      — Hors-RP (global)")
        chat.AddText(Color(200,200,255), "/do <description> — Décrit la scène (local)")
        chat.AddText(Color(200,200,255), "/empire <msg>     — Chat faction Empire")
        chat.AddText(Color(200,200,255), "/republique <msg> — Chat faction République")
        chat.AddText(Color(200,200,255), "/mando <msg>      — Chat faction Mando")
        chat.AddText(Color(100,180,255), "═══ Commandes Jeu ═══")
        chat.AddText(Color(200,200,255), "swtor_shop        — Boutique")
        chat.AddText(Color(200,200,255), "swtor_travel      — Voyage inter-planètes")
        chat.AddText(Color(200,200,255), "swtor_wardrobe    — Changer de tenue")
        chat.AddText(Color(200,200,255), "!myinfo           — Votre profil")
        chat.AddText(Color(200,200,255), "swtor_forcemenu   — Pouvoirs de la Force")
    end
end)

print("[SW:TOR] Chat RP client chargé ✓")
