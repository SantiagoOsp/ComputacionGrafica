(setq *1-SEG* (/ 1.0 86400.0))

; ---- UTILIDADES ------------------------------------------------

(defun get-hora-actual ( / td h m s)
  (setq td (* (- (getvar "DATE")(fix (getvar "DATE"))) 24.0))
  (setq h  (fix td))
  (setq m  (fix (* (- td h) 60.0)))
  (setq s  (fix (* (- (* (- td h) 60.0) m) 60.0)))
  (list h m s))

(defun calc-angulos (h m s)
  (list
    (- (/ pi 2) (* (+ (* (rem h 12) 1.0)(/ m 60.0))(/ (* 2 pi) 12)))
    (- (/ pi 2) (* m  (/ (* 2 pi) 60)))
    (- (/ pi 2) (* s  (/ (* 2 pi) 60)))))

(defun formato-2dig(n)
  (if(< n 10)(strcat "0"(itoa n))(itoa n)))

(defun dibuja-manecilla-ent (centro largo radio ang capa color / p2)
  (setq p2 (list
    (+ (car centro)  (* largo radio (cos ang)))
    (+ (cadr centro) (* largo radio (sin ang)))))
  (entmake (list
    (cons 0  "LINE")
    (cons 8  capa)
    (cons 62 color)
    (cons 10 (list (car centro)(cadr centro) 0.0))
    (cons 11 (list (car p2)(cadr p2) 0.0))))
  (entlast))

(defun borra-si-existe (ent)
  (if (and ent (entget ent))
    (entdel ent)))

; Pausa liviana: solo compara DATE, sin llamar ningun comando
(defun espera-seg (n / t0)
  (setq t0 (getvar "DATE"))
  (while (< (- (getvar "DATE") t0) (* n *1-SEG*))))

; ----- FECHA ----------------------------------------------------

(defun get-fecha-str (/ jd l n i j dia mes anio meses)
  (setq jd (fix (getvar "DATE")))
  (setq l (+ jd 68569))
  (setq n (fix (/ (+4 l) 146097)))
  (setq l (- l (fix (/ (+ (* 146097 n) 3) 4))))
  (setq i  (fix (/ (* 4000 (+ l 1)) 1461001)))
  (setq l  (- l (fix (/ (* 1461 i) 4)) -31))
  (setq j  (fix (/ (* 80 l) 2447)))
  (setq dia  (- l (fix (/ (* 2447 j) 80))))
  (setq l    (fix (/ j 11)))
  (setq mes  (+ j 2 (* -12 l)))
  (setq anio (+ (* 100 (- n 49)) i l))
  (setq meses (list "Enero" "Febrero" "Marzo" "Abril" "Mayo" "Junio"
                    "Julio" "Agosto" "Septiembre" "Octubre" "Noviembre" "Diciembre"))
  (strcat (itoa dia) " de " (nth (1- mes) meses) " de " (itoa anio)))

; ---- CARATULA ANALOGICA -------------------------------------------

(defun dibuja-caratula (centro radio / ang i)
  (command "CIRCLE" centro radio)
  (command "CIRCLE" centro (* radio 0.95))
  (entmake (list
    (cons 0  "CIRCLE")
    (cons 8  "RELOJ-MARCO")
    (cons 10 (list (car centro)(cadr centro) 0.0))
    (cons 40 (* radio 0.03))))
  (setq ang 0.0)
  (repeat 12
    (command "LINE"
      (list (+ (car centro)  (* radio (cos ang)))
            (+ (cadr centro) (* radio (sin ang))))
      (list (+ (car centro)  (* 0.85 radio (cos ang)))
            (+ (cadr centro) (* 0.85 radio (sin ang))))
      "")
    (setq ang (+ ang (/ (* 2 pi) 12))))
  (setq ang 0.0  i 0)
  (repeat 60
    (if (/= (rem i 5) 0)
      (command "LINE"
        (list (+ (car centro)  (* radio (cos ang)))
              (+ (cadr centro) (* radio (sin ang))))
        (list (+ (car centro)  (* 0.93 radio (cos ang)))
              (+ (cadr centro) (* 0.93 radio (sin ang))))
        ""))
    (setq ang (+ ang (/ (* 2 pi) 60)))
    (setq i (1+ i))))

; ---- CARATULA DIGITAL ------------------------------------------

(defun dibuja-caratula-digital (px py aw ah / x1 x2 y1 y2)
  (setq x1 (- px (/ aw 2))  x2 (+ px (/ aw 2)))
  (setq y1 (- py (/ ah 2))  y2 (+ py (/ ah 2)))
  ; Marco exterior
  (entmake (list
    (cons 0   "LWPOLYLINE")
    (cons 8   "DIGITAL-MARCO")
    (cons 100 "AcDbEntity")
    (cons 100 "AcDbPolyline")
    (cons 90  4)
    (cons 70  1)
    (cons 10 (list x1 y1))
    (cons 10 (list x2 y1))
    (cons 10 (list x2 y2))
    (cons 10 (list x1 y2))))
  ; Marco interior bisel
  (entmake (list
    (cons 0   "LWPOLYLINE")
    (cons 8   "DIGITAL-MARCO")
    (cons 100 "AcDbEntity")
    (cons 100 "AcDbPolyline")
    (cons 90  4)
    (cons 70  1)
    (cons 10 (list (+ x1 2)(+ y1 2)))
    (cons 10 (list (- x2 2)(+ y1 2)))
    (cons 10 (list (- x2 2)(- y2 2)))
    (cons 10 (list (+ x1 2)(- y2 2)))))
  ; Etiqueta fija HORA
  (entmake (list
    (cons 0  "TEXT")
    (cons 8  "DIGITAL-ETIQUETA")
    (cons 62 8)
    (cons 10 (list px (+ y2 (* ah 0.25)) 0.0))
    (cons 40 (* ah 0.18))
    (cons 1  "-- HORA ACTUAL --")
    (cons 72 1)
    (cons 73 2)
    (cons 11 (list px (+ y2 (* ah 0.25)) 0.0)))))

; ---- MARCO FECHA -----------------------------------------------

(defun dibuja-marco-fecha (px py aw ah / x1 x2 y1 y2)
  (setq x1 (- px (/ aw 2))  x2 (+ px (/ aw 2)))
  (setq y1 (- py (/ ah 2))  y2 (+ py (/ ah 2)))
  (entmake (list
    (cons 0   "LWPOLYLINE")
    (cons 8   "FECHA-MARCO")
    (cons 100 "AcDbEntity")
    (cons 100 "AcDbPolyline")
    (cons 90  4)
    (cons 70  1)
    (cons 10 (list x1 y1))
    (cons 10 (list x2 y1))
    (cons 10 (list x2 y2))
    (cons 10 (list x1 y2))))
  ; Etiqueta fija FECHA
  (entmake (list
    (cons 0  "TEXT")
    (cons 8  "FECHA-ETIQUETA")
    (cons 62 8)
    (cons 10 (list px (+ y2 (* ah 0.25)) 0.0))
    (cons 40 (* ah 0.22))
    (cons 1  "-- FECHA ACTUAL --")
    (cons 72 1)
    (cons 73 2)
    (cons 11 (list px (+ y2 (* ah 0.25)) 0.0)))))

; ---- COMANDO PRINCIPAL -----------------------------------------

(defun c:RELOJ-VIVO ( / centro radio hms ang
                        ent-h ent-m ent-s
                        seg-ant seg-act)

  (setq centro (getpoint "\nCentro del reloj: "))
  (setq radio  (getdist centro "\nRadio <50>: "))
  (if (null radio)(setq radio 50.0))

  ; Caratula una sola vez
  (dibuja-caratula centro radio)

  ; Manecillas iniciales
  (setq hms (get-hora-actual))
  (setq ang (calc-angulos (car hms)(cadr hms)(caddr hms)))
  (setq ent-h (dibuja-manecilla-ent centro 0.55 radio (car   ang) "HORARIO"   1))
  (setq ent-m (dibuja-manecilla-ent centro 0.78 radio (cadr  ang) "MINUTERO"  2))
  (setq ent-s (dibuja-manecilla-ent centro 0.90 radio (caddr ang) "SEGUNDERO" 1))
  (redraw)

  ; Guardar segundo inicial
  (setq seg-ant (caddr (get-hora-actual)))

  (princ "\n  Reloj activo (liviano). ESC o cierra AutoCAD para detener.")

  ; ---- Bucle: solo actua cuando cambia el segundo --------------
  (while T

    ; Espera liviana de 0.5 seg para no saturar el CPU
    (espera-seg 0.5)

    ; Leer segundo actual
    (setq seg-act (caddr (get-hora-actual)))

    ; Solo redibujar si cambio el segundo
    (if (/= seg-act seg-ant)
      (progn
        ; Borrar manecillas viejas
        (borra-si-existe ent-h)
        (borra-si-existe ent-m)
        (borra-si-existe ent-s)

        ; Nueva hora y angulos
        (setq hms (get-hora-actual))
        (setq ang (calc-angulos (car hms)(cadr hms)(caddr hms)))

        ; Redibujar solo las 3 lineas (sin REGEN)
        (setq ent-h (dibuja-manecilla-ent centro 0.55 radio (car   ang) "HORARIO"   1))
        (setq ent-m (dibuja-manecilla-ent centro 0.78 radio (cadr  ang) "MINUTERO"  2))
        (setq ent-s (dibuja-manecilla-ent centro 0.90 radio (caddr ang) "SEGUNDERO" 1))

        ; redraw es 100x mas liviano que REGEN
        (redraw)

        ; Actualizar segundo guardado
        (setq seg-ant seg-act)

        ; Mostrar hora en consola
        (princ (strcat "\r  "
          (itoa (car hms)) ":"
          (if (< (cadr  hms) 10)(strcat "0"(itoa (cadr  hms)))(itoa (cadr  hms))) ":"
          (if (< seg-act 10)(strcat "0"(itoa seg-act))(itoa seg-act))
          "   ")))))  )

; ---- CARGA -----------------------------------------------------
(princ "\n+------------------------------------------+")
(princ "\n|  RELOJ-VIVO  -> inicia el reloj liviano  |")
(princ "\n|  ESC / cerrar AutoCAD para detener       |")
(princ "\n+------------------------------------------+")
(princ)