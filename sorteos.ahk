#Persistent
CoordMode, Mouse, Screen
EnvGet, userProfile, USERPROFILE
SetWorkingDir, %A_ScriptDir%

; ///////////////////////////////////////// Variables de config globales /////////////////////////////////////////
global contadorComentariosHechos := 139 ; Comentarios YA hechos
global limiteDiario := 500 ; Cantidad máxima de comentarios a enviar
global cantMenciones := 2 ; Cantidad de cuentas a mecionar por comentario
global intervaloMinutos, intervaloSegundos, intervalo
global totalComentarios := 6588 ; Cantidad de comentarios totales que tiene la publicación
global tiempoRestante := 0
global timerActivo := false

; ///////////////////////////////////////// Crear GUI una vez /////////////////////////////////////////
Gui, TimerGUI:+AlwaysOnTop -Caption +ToolWindow
Gui, TimerGUI:Font, s14 Bold, Segoe UI
Gui, TimerGUI:Add, Text, vTiempoRestanteText w200 Center, Esperando...
Gui, TimerGUI:Show, x10 y10 NoActivate, Timer Visual


; ///////////////////////////////////////// Set del Timer random /////////////////////////////////////////
Comenzar:
    Random, intervaloMinutos, 3, 7
    Random, intervaloSegundos, 0, 59
    intervalo := intervaloMinutos * 60000 + intervaloSegundos * 1000
    tiempoRestante := intervalo // 1000
    timerActivo := true
    GuiControl, TimerGUI:, TiempoRestanteText, Restante: %tiempoRestante%s
    SetTimer, ActualizarTimerVisual, 1000
    SetTimer, Comentar, %intervalo%
Return

Comentar:
if (contadorComentariosHechos >= limiteDiario) {
    TrayTip, AutoHotkey, Límite diario alcanzado (%limiteDiario% comentarios), 5
    SetTimer, Comentar, Off
    SetTimer, ActualizarTimerVisual, Off
    GuiControl, TimerGUI:, TiempoRestanteText, Límite alcanzado!
    Return
}

; ///////////////////////////////////////// Creación del mensaje /////////////////////////////////////////
cuentas := SeleccionarCuentas(A_ScriptDir . "\cuentas.txt")
If (cuentas != "") {
    emoji := SeleccionarEmoji()
    frase := SeleccionarFrase()
    If (RandomDecision(50)) ; chance de no poner emoji
        emoji := ""
    If (RandomDecision(50)) ; chance de no poner frase
        frase := ""

    mensaje := cuentas " " frase " " emoji 
    mensaje := Trim(mensaje)

    WinActivate, ahk_exe opera.exe
    WinWaitActive, ahk_exe opera.exe,, 3
    If !WinActive("ahk_exe opera.exe") {
        MsgBox, No pude activar la ventana de Opera
        Return
    }

    Sleep 500
    MouseMove, 980, 960 ; Coords del input text
    Sleep 200
    Click left
    Sleep 500
    SendInput %mensaje% ; Enviar Mensaje 
    Sleep 500
    SendInput {Enter}
    Sleep 500
    MouseClick, left, 1305, 964 ; Coords del boton publicar y publicación del comentario

    contadorComentariosHechos++
    totalComentarios++
    TrayTip, AutoHotkey, Comentario enviado (#%contadorComentariosHechos%): %mensaje%, 3

    probabilidad := CalcularProbabilidad(contadorComentariosHechos, totalComentarios)
    GuardarChances(contadorComentariosHechos, probabilidad)

    Random, intervaloMinutos, 2, 5
    Random, intervaloSegundos, 0, 59
    intervalo := intervaloMinutos * 60000 + intervaloSegundos * 1000
    tiempoRestante := intervalo // 1000
    timerActivo := true
    GuiControl, TimerGUI:, TiempoRestanteText, Restante: %tiempoRestante%s
    SetTimer, ActualizarTimerVisual, 1000
    SetTimer, Comentar, %intervalo%
} else {
    MsgBox, No se seleccionaron cuentas
}
Return

ActualizarTimerVisual:
if (timerActivo) {
    tiempoRestante--
    if (tiempoRestante < 0) {
        tiempoRestante := 0
        timerActivo := false
        GuiControl, TimerGUI:, TiempoRestanteText, Enviando...
    } else {
        GuiControl, TimerGUI:, TiempoRestanteText, Restante: %tiempoRestante%s
    }
}
Return

; ///////////////////////////////////////// Funciones auxiliares /////////////////////////////////////////
CalcularProbabilidad(comentariosHechos, totalComentarios) {
    probabilidad := (comentariosHechos / totalComentarios) * 100
    return probabilidad
}

GuardarChances(comentariosHechos, probabilidad) {
    filePath := A_ScriptDir . "\chances.txt"
    FileAppend, comentarios_totales=%totalComentarios%`n, %filePath%
    FileAppend, comentarios_hechos=%comentariosHechos%`n, %filePath%
    FileAppend, chances=%probabilidad%`%`n, %filePath%
}

SeleccionarCuentas(filePath) {
    If !FileExist(filePath) {
        MsgBox, No existe el archivo: %filePath%
        return ""
    }
    FileRead, contenido, %filePath%
    lineas := []
    Loop, Parse, contenido, `n, `r
    {
        If (A_LoopField != "")
            lineas.push(A_LoopField)
    }
    If (lineas.MaxIndex() < 1) {
        MsgBox, El archivo está vacío
        return ""
    }
    cuentas := ""
    Loop, %cantMenciones% {
        Random, randomIndex, 1, % lineas.MaxIndex()
        cuentas .= Trim(lineas[randomIndex]) . " "
    }
    return Trim(cuentas)
}

SeleccionarEmoji() {
    emojis := ["😊", "🔥", "🎉", "✨", "😎", "🙌", "👍", "🥳"]
    Random, index, 1, % emojis.MaxIndex()
    return emojis[index]
}

SeleccionarFrase() {
    frases := ["veremos","suerte","a ver que sale","suertee","xd","ojala","bueno","ojala ganarlo","messirve","buenisimoo","esperemos","esperemos que si", "espero ganar", "ojala ganar"]
    Random, index, 1, % frases.MaxIndex()
    return frases[index]
}

RandomDecision(probabilidad) {
    Random, decision, 1, 100
    return decision <= probabilidad
}
