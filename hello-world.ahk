; hello-world.ahk
; Pressione Ctrl+Alt+H para abrir uma janela Hello World

#Requires AutoHotkey v2.0

^!h::
{
    MsgBox("Hello, World!", "Hello World", "OK")
}
