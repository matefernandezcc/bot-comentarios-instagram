#Persistent
CoordMode, Mouse, Screen
EnvGet, userProfile, USERPROFILE
SetWorkingDir, %A_ScriptDir%

; ///////////////////////////////////////// Variables de config globales /////////////////////////////////////////
global url := "PC-Gamer-2" ; URL / nombre del sorteo actual
global contadorComentariosHechos := 4 ; Comentarios YA hechos
global limiteDiario := 500 ; Cantidad máxima de comentarios a enviar
global cantMenciones := 3 ; Cantidad de cuentas a mecionar por comentario
global intervaloMinutos, intervaloSegundos, intervalo
global totalComentarios := 7871 ; Cantidad de comentarios totales que tiene la publicación
global tiempoRestante := 0
global timerActivo := false
global penalizacion := 0 ; Tiempo sumado por cada vez que te bloquean acciones (en minutos)

; ///////////////////////////////////////// Crear GUI una vez /////////////////////////////////////////
Gui, TimerGUI:+AlwaysOnTop -Caption +ToolWindow
Gui, TimerGUI:Font, s14 Bold, Segoe UI
Gui, TimerGUI:Add, Text, vTiempoRestanteText w200 Center, Esperando...
Gui, TimerGUI:Add, Text, vPenalizacionText w200 Center, Penalización: 0m
Gui, TimerGUI:Show, x40 y75 NoActivate, Timer Visual

; ///////////////////////////////////////// Set del Timer Inicial /////////////////////////////////////////
Comenzar:
    Random, intervaloMinutos, 0, 0 ; Entre x e y minutos
    Random, intervaloSegundos, 5, 5
    intervalo := intervaloMinutos * 60000 + intervaloSegundos * 1000 + penalizacion * 60000
    tiempoRestante := intervalo // 1000
    timerActivo := true
    GuiControl, TimerGUI:, TiempoRestanteText, Restante: %tiempoRestante%s
    GuiControl, TimerGUI:, PenalizacionText, Penalización: %penalizacion%m
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
    MouseMove, 1246, 959 ; Coords del input text
    Sleep 200
    Click left
    Sleep 500
    SendInput %mensaje% ; Enviar Mensaje 
    Sleep 500
    SendInput {Enter}
    Sleep 500
    MouseClick, left, 1487, 954 ; Coords del boton publicar y publicación del comentario
    Sleep 2000
    DetectarPopup()

    contadorComentariosHechos++
    totalComentarios++
    TrayTip, AutoHotkey, Comentario enviado (#%contadorComentariosHechos%): %mensaje%, 3

    probabilidad := CalcularProbabilidad(contadorComentariosHechos, totalComentarios)
    GuardarChances(contadorComentariosHechos, probabilidad)

    ; /////////////////////// Nuevo timer random ///////////////////////
    Random, intervaloMinutos, 4, 5 
    Random, intervaloSegundos, 0, 59
    intervalo := intervaloMinutos * 60000 + intervaloSegundos * 1000 + penalizacion * 60000
    tiempoRestante := intervalo // 1000
    timerActivo := true
    GuiControl, TimerGUI:, TiempoRestanteText, Restante: %tiempoRestante%s
    GuiControl, TimerGUI:, PenalizacionText, Penalización: %penalizacion%m
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
    FormatTime, fechaHora, %A_Now%, dd-MM HH:mm

    FileAppend, Fecha=%fechaHora%`n, %filePath%
    FileAppend, Sorteo=%url%`n, %filePath% ;
    FileAppend, Comentarios hechos=%comentariosHechos%`n, %filePath%
    FileAppend, Comentarios totales=%totalComentarios%`n, %filePath%
    FileAppend, probabilidad=%probabilidad%`%`n, %filePath%
    FileAppend, `n, %filePath%
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
    emojis := ["😊", "🔥", "🎉", "✨", "😎", "🙌", "👍", "🥳", "😇", "😍", "🤩", "🎯", "💥", "😜", "🤗", "💪", "🤞", "🌟", "🌈", "💖", "💫", "😝", "🌻", "💬", "🙈", "💥", "🍀"]
    Random, index, 1, % emojis.MaxIndex()
    return emojis[index]
}

SeleccionarFrase() {
    frases := ["veremos", "suerte", "exitos", "ganare?", "quiero ganar", "a ver si gano un sorteo", "a ver que sale", "suertee", "xd", "ojala", "bueno", "ojala ganarlo", "messirve", "buenisimoo", "esperemos", "esperemos que si", "espero ganar", "ojala ganar", "seria genial", "deseando ganar", "este es mi momento", "crucemos los dedos", "si lo gano, ¡genial!", "todo por un sorteo", "a ganar", "me gustaría mucho", "vamos a ver", "tengo fe"]
    Random, index, 1, % frases.MaxIndex()
    return frases[index]
}

RandomDecision(probabilidad) {
    Random, decision, 1, 100
    return decision <= probabilidad
}

DetectarPopup() {
    ; Primera área donde puede aparecer el popup
    X1 := 720
    Y1 := 580
    X2 := 950
    Y2 := 625

    ; Segunda área donde también podría aparecer el popup
    X3 := 1570
    Y3 := 972
    X4 := 1655
    Y4 := 1000

    ; Color a buscar
    colorBuscar1 := 0x22333F
    colorBuscar2 := 0xE0F1FF

    ; Buscar en la primera área
    PixelSearch, foundX, foundY, X1, Y1, X2, Y2, colorBuscar1, 1, Fast RGB
    if (ErrorLevel = 0) {
        TrayTip, Popup Detectado, Cambiando de cuenta (Área 1), 2
        penalizacion := penalizacion + 5
        Send, ^{Tab}
        return true
    }

    ; Buscar en la segunda área
    PixelSearch, foundX, foundY, X3, Y3, X4, Y4, colorBuscar2, 1, Fast RGB
    if (ErrorLevel = 0) {
        TrayTip, Popup Detectado, Cambiando de cuenta (Área 2), 2
        penalizacion := penalizacion + 5
        Send, ^{Tab}
        return true
    }

    return false
}
