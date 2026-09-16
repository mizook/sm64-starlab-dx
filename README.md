# StarLab DX

Mod de práctica y entrenamiento de speedruns de **Super Mario 64** para **SM64CoopDX 1.5.1**.

**Versión:** 0.17.9 · **by carlo ignacio**

StarLab DX permite repetir estrellas, guardar puntos de práctica y preparar rutas personalizadas con cronómetro y splits, sin salir del juego.

## Funciones

- **Práctica individual:** selección de nivel, estrella y acto de entrada, reintentos y mejores tiempos personales (PB).
- **Puntos de práctica:** guardar y cargar la posición de Mario para repetir un tramo, con tiempos parciales separados del PB completo.
- **Runs personalizadas:** cinco espacios para crear, nombrar, duplicar y ordenar rutas por niveles, cantidades de estrellas y objetivos de Bowser.
- **Cronómetro y splits:** seguimiento de objetivos, tiempos e historial de intentos.
- **Menús con mando:** navegación con stick o cruceta, A para seleccionar y B para volver.
- **Interfaz en español e inglés**, según el idioma del juego.

## Instalación

1. Descarga este repositorio mediante **Code → Download ZIP**, o clónalo.
2. Copia la carpeta **`outputs/starlab-dx` completa** al directorio `mods` de SM64CoopDX.
3. Comprueba que exista `mods/starlab-dx/main.lua` y que la carpeta `starlab` esté junto a ese archivo.
4. Activa **StarLab DX** en la lista de mods e inicia una partida.
5. Abre el menú con `/sl menu`.

No copies únicamente `main.lua`: necesita los módulos de la carpeta `starlab`. Para actualizar, reemplaza la carpeta del mod y reinicia el juego.

## Primeros pasos

### Practicar una estrella

En **Inicio → Práctica individual**, elige nivel y estrella y selecciona **Practicar**. También puedes escribir `/sl bob 1` para practicar la primera estrella de Bob-omb Battlefield.

Durante la práctica:

| Control | Acción |
| --- | --- |
| L + izquierda | Guardar un punto de práctica |
| L + derecha | Cargar el punto guardado, si está disponible en la zona actual |
| L + abajo | Reiniciar la estrella desde la entrada |
| L + arriba | Abrir el selector; cancela el intento activo |

Para borrar el punto, usa **Práctica → Borrar punto** o `/sl clearpoint`.

### Crear y correr una ruta

1. En **Runs**, selecciona un espacio con izquierda/derecha.
2. Si está vacío, elige **Crear run**. Puedes darle un nombre y agregar niveles y cantidades de estrellas.
3. Vuelve con **B** al menú de Runs. Usa **Añadir estrellas** para ampliar la ruta y **Ordenar ruta** para mover o quitar bloques.
4. Selecciona **Comenzar run**, elige el modo de inicio y confirma.

**Crear run** y **Comenzar run** ocupan la misma posición del menú según si el espacio está vacío o ya tiene una ruta. Los bloques se guardan al agregarlos.

## Comandos útiles

| Comando | Acción |
| --- | --- |
| `/sl menu` | Abrir Inicio |
| `/sl runs` | Abrir Runs |
| `/sl settings` | Abrir Ajustes |
| `/sl help` | Mostrar ayuda de comandos |
| `/sl timing` | Consultar la ayuda de tiempos y checkpoints |
| `/sl list` | Ver los códigos de niveles |
| `/sl stop` | Detener el intento |
| `/sl clearpoint` | Borrar el punto de práctica |

## Cómo interpretar los tiempos

El contador mide actualizaciones de Mario a **30 Hz** y excluye pausas y cargas sin actualizaciones. Es una herramienta de entrenamiento: **no es un cronómetro RTA oficial**.

Los puntos guardados restauran el estado local de Mario y la cámara; no rebobinan todo el mundo. Monedas, enemigos e interruptores pueden haber cambiado: no equivalen a un savestate completo.

El inicio desde intro utiliza un espacio de entrenamiento cuyo progreso se reinicia. El inicio desde el primer nivel usa el progreso actual. Revisa el modo seleccionado antes de comenzar.

## Contenido del repositorio

El código instalable está en [`outputs/starlab-dx`](outputs/starlab-dx). `main.lua` es el punto de entrada y `starlab/` contiene los módulos de práctica, runs, interfaz y almacenamiento.

Este repositorio contiene el código del mod, sin ROM ni ejecutable del juego. Las notas internas, pruebas locales, respaldos y paquetes generados quedan fuera del repositorio.
