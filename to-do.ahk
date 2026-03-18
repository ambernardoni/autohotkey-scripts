; to-do.ahk
; Pressione Ctrl+Win+↑ para abrir o formulário de nova tarefa
; Os dados são enviados via POST para o webhook configurado abaixo

#Requires AutoHotkey v2.0

; ─────────────────────────────────────────
; CONFIGURAÇÃO — troque a URL aqui quando
; for para produção
WEBHOOK_URL := "https://a2accelerate.app.n8n.cloud/webhook-test/20f1c56e-73c7-42ed-bba3-3a58f78be234"
; ─────────────────────────────────────────

; Escapa uma string para uso seguro dentro de JSON
JsonEscape(str) {
    str := StrReplace(str, "\",  "\\")   ; barra invertida primeiro
    str := StrReplace(str, '"',  '\"')   ; aspas duplas
    str := StrReplace(str, "`r`n", "\n") ; CRLF → \n
    str := StrReplace(str, "`n", "\n")   ; LF   → \n
    str := StrReplace(str, "`r", "\n")   ; CR   → \n
    str := StrReplace(str, "`t", "\t")   ; tab  → \t
    return str
}

^#Up::
{
    ; Evita abrir múltiplas janelas
    if WinExist("Nova Tarefa - To-Do") {
        WinActivate
        return
    }

    toDoGui := Gui("+AlwaysOnTop", "Nova Tarefa - To-Do")
    toDoGui.SetFont("s10", "Segoe UI")
    toDoGui.MarginX := 15
    toDoGui.MarginY := 12

    toDoGui.Add("Text", "w300", "📌 Título:")
    titleField := toDoGui.Add("Edit", "w300 vTitle")

    toDoGui.Add("Text", "w300 y+10", "💬 Comentário:")
    commentField := toDoGui.Add("Edit", "w300 h90 vComment Multi")

    toDoGui.Add("Button", "Default w140 y+14", "✔ Salvar").OnEvent("Click", SaveTask)
    toDoGui.Add("Button", "w140 x+10", "✖ Cancelar").OnEvent("Click", (*) => CloseGui())

    toDoGui.OnEvent("Close", (*) => CloseGui())
    toDoGui.Show()
    titleField.Focus()

    ; Registra handler e guarda referência para poder desregistrar depois
    keyHandler := WM_KEYDOWN
    OnMessage(0x0100, keyHandler)

    ; Ponto único de fechamento — sempre desregistra o handler antes de destruir
    CloseGui() {
        OnMessage(0x0100, keyHandler, 0)
        toDoGui.Destroy()
    }

    ; Captura Enter no título e Esc em qualquer lugar
    WM_KEYDOWN(wParam, lParam, msg, hwnd) {
        if (hwnd = titleField.Hwnd && wParam = 13) { ; 13 = Enter
            SaveTask(0, 0)
            return 0
        }
        if (wParam = 27) { ; 27 = Esc
            CloseGui()
            return 0
        }
    }

    SaveTask(btn, *) {
        data := toDoGui.Submit(false)

        if (Trim(data.Title) = "" && Trim(data.Comment) = "") {
            CloseGui()
            return
        }

        ; Escapa corretamente para JSON (barras, aspas, quebras de linha, tabs)
        safeTitle   := JsonEscape(data.Title)
        safeComment := JsonEscape(data.Comment)

        json := '{"title":"' safeTitle '","comment":"' safeComment '"}'

        ; Envia via WinHttp
        try {
            http := ComObject("WinHttp.WinHttpRequest.5.1")
            http.Open("POST", WEBHOOK_URL, false)
            http.SetRequestHeader("Content-Type", "application/json")
            http.Send(json)

            if (http.Status = 200) {
                MsgBox("✅ Tarefa enviada com sucesso!", "To-Do", "Iconi OK T3")
                CloseGui()
            } else {
                MsgBox("⚠️ Webhook retornou status " http.Status "`n`n" http.ResponseText, "Erro", "Icon! OK")
            }
        } catch as err {
            MsgBox("❌ Falha ao enviar:`n" err.Message, "Erro de Conexão", "Icon! OK")
        }
    }
}
