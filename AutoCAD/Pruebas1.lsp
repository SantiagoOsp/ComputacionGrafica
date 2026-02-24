(setq radius (* 20 20)
      diametro 355
      ciudad "Bogota"
      )

(command "_circle" "100, 300" 500)

; En autocad tenemos la posibilidad de hacer ZOOM a todas las figuras dibujadas en nuestro archivo y podemos hacerlo con
; ZOOM y luego con E usamos "Extents"

(setq a (getpoint "\nChoose point a:"))
(setq b (getpoint "\nChoose point b:"))
(command "_line" a b "")

; Para hacer una linea continua usamos _PLINE
; Para romper esa polilinea debemos usar _explode
; UNDO deshace la accion inmediatamente previa

; Para saber que variables tenemos en AutoCAD debemos usar la palabra SETVAR. Si queremos saber todas las que hay usamos primero el signo
; de interrogacion, y luego el * (en caso de querer verlas todas) o cualquier letra para ver las variables que empiezan por esta letra

; Para saber que fecha es la que esta en el sistema, usamos la funcion CDATE. Este valor nos arroja YYYYMMDD.hhmmSSss.
(setq fecha_hora (getvar "cdate"))

; Cuando obtenemos ese valor, este viene dado por un numero cientifico. Para obtener todo el valor podemos convertirlo a String con "rtos"
; Esta funcion tiene la posibilidad de convertirlo a cientifico (1), a decimal (2), a ingeniero (3), arquitectural (4), y luego de esto podemos
; escoger la precision de este valor.
(setq fecha_hora_string (rtos fecha_hora 2 6))
; Podemos obtener ciertos caracteres de esta variable string, con la ayuda de "substr". Con esto podemos escoger la posicion y el numero de caracteres
(setq fecha_hora_Y (substr fecha_hora_string 1 4)) 
; Podemos convertir de string a integer con la funcion "atoi"
(setq anio (atoi fecha_hora_Y))

(setq dias_mes (list 31 (= (/ año 4) (/ año 4.0))))

; Para crear una funcion tenemos la siguiente sintaxis
(defun reloj(*param) 
  (print "Reloj")
  (setq radio (/ 100. 4))
  )

; Si queremos saber el codigo unico podemos usar el Handle buscandolo con LIST
; para poder cambiar el nombre de la entidad podemos usar:
(handent *handle) ; *handle se debe cambiar por el handle extraido anteriormente
(setq linea (entlast))  ; con este comando 'entlast' podemos ver o usar la ultima entidad creada

; Las funciones se crean con ayuda de defun. Puede crearse como una funcion de la siguiente forma:
(defun AreaCirc (rad) (* pi rad rad))

; O se pueden crear comandos con ayuda de "c:" de la siguiente forma
(defun c:AreaCirc ()
  (setq rad (getreal "\nIngrese el radio: "))
  (princ "\nArea = ")(* pi rad rad)
  )

; Ejemplo de como ir guardando el cambio de angulo en el reloj

(defun c:reloj()
  (setq angsegxseg(/ 360 60.0)
	angminxmin(/ 360 60.0)
	anghorxhor(/ 360 12)
	angminxseg(/ angminxmin 60)
	anghorxmin(/ anghorxhor 60)
	anghorxseg(/ anghorxmin 60)
	)
  (setq n 120)
  (repeat n
	  (command "_rotate" segundero "" "0,0" angsegxseg)

	)
  )

; Ciclo de repetición

; Buscar usar regen o redraw para evitar fallas en el cambio de las manecillas
