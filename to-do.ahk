; to-do.ahk
; Pressione Ctrl+Alt+T para abrir o formulário de nova tarefa

#Requires AutoHotkey v2.0

^!t::
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
    toDoGui.Add("Button", "w140 x+10", "✖ Cancelar").OnEvent("Click", (*) => toDoGui.Destroy())

    toDoGui.OnEvent("Close", (*) => toDoGui.Destroy())
    toDoGui.Show()

    SaveTask(btn, *) {
        data := toDoGui.Submit(false)

        if (Trim(data.Title) = "") {
            MsgBox("Por favor, insira um título para a tarefa.", "Atenção", "Icon! OK")
            return
        }

        msg := "✅ Tarefa criada com sucesso!`n`n"
            . "Título:      " data.Title "`n"
            . "Comentário: " (Trim(data.Comment) != "" ? data.Comment : "(sem comentário)")

        MsgBox(msg, "To-Do", "Iconi OK")
        toDoGui.Destroy()
    }
}
