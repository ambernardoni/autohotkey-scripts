; to-do.ahk
; Pressione Ctrl+Win+↑ para abrir o formulário de nova tarefa
; Os dados são enviados via POST para o webhook configurado abaixo

#Requires AutoHotkey v2.0

; ─────────────────────────────────────────
; CONFIGURAÇÃO — troque a URL aqui quando
; for para produção
WEBHOOK_URL := "https://a2accelerate.app.n8n.cloud/webhook-test/20f1c56e-73c7-42ed-bba3-3a58f78be234"
; ─────────────────────────────────────────

; ── Paleta estilo n8n ───────────────────
COL_BG    := "1A1A1A"  ; fundo da janela
COL_INPUT := "2D2D2D"  ; fundo dos campos
COL_TEXT  := "E0E0E0"  ; texto dos campos
COL_LABEL := "E8914A"  ; labels (laranja n8n)
; ────────────────────────────────────────

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
    toDoGui.BackColor := COL_BG
    toDoGui.MarginX := 20
    toDoGui.MarginY := 16

    ; Label título
    toDoGui.SetFont("s9 c" COL_LABEL, "Segoe UI")
    toDoGui.Add("Text", "w300 Background" COL_BG, "Título")

    ; Campo título
    toDoGui.SetFont("s10 c" COL_TEXT, "Segoe UI")
    titleField := toDoGui.Add("Edit", "w300 h28 y+5 vTitle Background" COL_INPUT)

    ; Label comentário
    toDoGui.SetFont("s9 c" COL_LABEL, "Segoe UI")
    toDoGui.Add("Text", "w300 y+12 Background" COL_BG, "Comentário")

    ; Campo comentário
    toDoGui.SetFont("s10 c" COL_TEXT, "Segoe UI")
    commentField := toDoGui.Add("Edit", "w300 h80 y+5 vComment Multi Background" COL_INPUT)

    ; Botões
    toDoGui.SetFont("s9 c" COL_TEXT, "Segoe UI")
    toDoGui.Add("Button", "Default w144 y+16", "Salvar").OnEvent("Click", SaveTask)
    toDoGui.Add("Button", "w144 x+12", "Cancelar").OnEvent("Click", (*) => CloseGui())

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
                CloseGui()
            } else {
                MsgBox("⚠️ Webhook retornou status " http.Status "`n`n" http.ResponseText, "Erro", "Icon! OK")
            }
        } catch as err {
            MsgBox("❌ Falha ao enviar:`n" err.Message, "Erro de Conexão", "Icon! OK")
        }
    }
}
