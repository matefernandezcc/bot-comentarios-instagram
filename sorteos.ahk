#Persistent
CoordMode, Mouse, Screen
EnvGet, userProfile, USERPROFILE
SetWorkingDir, %A_ScriptDir%

; Configuración global
global contadorComentariosHechos := 74 ; Comentarios YA hechos
global limiteDiario := 100 ; Comentarios max que hace el script
global cantMenciones := 1 ; Cuantas cuentas mencionar por comentario
global intervaloMinutos, intervaloSegundos, intervalo
global totalComentarios := 40900 ; Comentarios totales de la publicacion

; ///////////////////////////// Intervalo random entre comentarios ///////////////////////////// 
Comenzar:
    Random, intervaloMinutos, 1, 4 ; entre 1 y 4 minutos
    Random, intervaloSegundos, 0, 59 ; entre 0 y 59 segundos
    intervalo := intervaloMinutos * 60000 + intervaloSegundos * 1000 ; convertir a milisegundos
    SetTimer, Comentar, %intervalo%  ; Establecer el temporizador solo una vez
Return

Comentar:
if (contadorComentariosHechos >= limiteDiario) {
    TrayTip, AutoHotkey, Límite diario alcanzado (%limiteDiario% comentarios), 5
    SetTimer, Comentar, Off  ; Detener el temporizador si se alcanza el límite
    Return
}

; ///////////////////////////// Leer cuentas del archivo /////////////////////////////
cuentas := SeleccionarCuentas(A_ScriptDir . "\cuentas.txt")
If (cuentas != "") {
    emoji := SeleccionarEmoji()
    frase := SeleccionarFrase()

    ; Decidir si se omite el emoji o la frase (al azar)
    If (RandomDecision(50))  ; Probabilidad de 50% de omitir el emoji
        emoji := ""
    
    If (RandomDecision(50))  ; Probabilidad de 50% de omitir la frase
        frase := ""

    ; Generar el mensaje con las cuentas seleccionadas
    mensaje := cuentas " " frase " " emoji 
    mensaje := Trim(mensaje) ; Eliminar posibles espacios extra

    ; Enviar el mensaje en la ventana activa
    WinActivate, ahk_exe opera.exe
    WinWaitActive, ahk_exe opera.exe,, 3
    If !WinActive("ahk_exe opera.exe") {
        MsgBox, No pude activar la ventana de Opera
        Return
    }

    Sleep 500
    MouseMove, 1146, 956
    Sleep 200
    Click left
    Sleep 500
    SendInput %mensaje%
    Sleep 500
    SendInput {Enter}         ; Enviar Enter con Send
    Sleep 500  ; Esperar medio segundo antes de hacer clic
    MouseClick, left, 1409, 958  ; Hacer clic en el botón de publicar

    contadorComentariosHechos++  ; Incrementar el contador de comentarios hechos
    totalComentarios++  ; Incrementar el total de comentarios

    TrayTip, AutoHotkey, Comentario enviado (#%contadorComentariosHechos%): %mensaje%, 3
    
    ; Calcular la probabilidad
    probabilidad := CalcularProbabilidad(contadorComentariosHechos, totalComentarios)
    
    ; Guardar en el archivo chances.txt
    GuardarChances(contadorComentariosHechos, probabilidad)
    
    ; Calcular el nuevo intervalo para el siguiente comentario
    Random, intervaloMinutos, 2, 5 ; entre 2 y 5 minutos
    Random, intervaloSegundos, 0, 59 ; entre 0 y 59 segundos
    intervalo := intervaloMinutos * 60000 + intervaloSegundos * 1000 ; convertir a milisegundos
    SetTimer, Comentar, %intervalo%  ; Reiniciar el temporizador con el nuevo intervalo
} else {
    MsgBox, No se seleccionaron cuentas
}
Return

; ///////////////////////////// Funciones /////////////////////////////

; Función para calcular la probabilidad
CalcularProbabilidad(comentariosHechos, totalComentarios) {
    probabilidad := (comentariosHechos / totalComentarios) * 100
    return probabilidad
}

; Función para guardar los datos en chances.txt
GuardarChances(comentariosHechos, probabilidad) {
    filePath := A_ScriptDir . "\chances.txt"
    FileAppend, comentarios_totales=%totalComentarios%`n, %filePath%  ; Usar la variable global totalComentarios
    FileAppend, comentarios_hechos=%comentariosHechos%`n, %filePath%
    FileAppend, chances=%probabilidad%`%`n, %filePath%  ; Guardar la probabilidad con el signo %
}

; Función para seleccionar cuentas aleatorias del archivo
SeleccionarCuentas(filePath) {
    If !FileExist(filePath) {
        MsgBox, No existe el archivo: %filePath%
        return ""
    }
    FileRead, contenido, %filePath%
    
    ; Filtrar líneas vacías
    lineas := []
    Loop, Parse, contenido, `n, `r
    {
        If (A_LoopField != "")  ; Solo agregar si la línea no está vacía
            lineas.push(A_LoopField)
    }

    If (lineas.MaxIndex() < 1) {
        MsgBox, El archivo está vacío
        return ""
    }
    
    cuentas := ""
    ; Seleccionar las cuentas según el valor de cantMenciones
    Loop, %cantMenciones% {
        Random, randomIndex, 1, % lineas.MaxIndex()
        cuentas .= Trim(lineas[randomIndex]) . " "
    }
    return Trim(cuentas)
}

; Función para seleccionar un emoji aleatorio
SeleccionarEmoji() {
    emojis := ["😊", "🔥", "🎉", "✨", "😎", "🙌", "👍", "🥳"]
    Random, index, 1, % emojis.MaxIndex()
    return emojis[index]
}

; Función para seleccionar una frase aleatoria
SeleccionarFrase() {
    frases := ["veremos", "suerte", "a ver que sale", "suertee", "xd", "ojala", "bueno", "esperemos", "esperemos que si", "espero ganar", "ojala ganar"]
    Random, index, 1, % frases.MaxIndex()
    return frases[index]
}

; Función para decidir si omitir un elemento con una probabilidad
RandomDecision(probabilidad) {
    Random, decision, 1, 100
    return decision <= probabilidad
}
