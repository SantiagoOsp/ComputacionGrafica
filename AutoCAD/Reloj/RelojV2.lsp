; ================================================================
; RELOJ ANALOGICO + DIGITAL  –  v7
; ================================================================

(setq *reloj-on*    nil)
(setq *reloj-c*     nil)
(setq *reloj-r*     nil)
(setq *ent-h*       nil)
(setq *ent-m*       nil)
(setq *ent-s*       nil)
(setq *digital-ent* nil)
(setq *fecha-ent*   nil)

(defun espera-seg (seg / t0 intervalo)
  (setq t0        (getvar "TDUSRTIMER"))
  (setq intervalo (/ seg 86400.0))
  (while (< (- (getvar "TDUSRTIMER") t0) intervalo)
    (grread T 4 0)))

; ================================================================
; HORA Y FECHA
; ================================================================

(defun get-hms ( / h m s)
  (setq h (atoi (menucmd "M=$(edtime,$(getvar,date),HH)")))
  (setq m (atoi (menucmd "M=$(edtime,$(getvar,date),MM)")))
  (setq s (atoi (menucmd "M=$(edtime,$(getvar,date),SS)")))
  (list h m s))

(defun fmt2 (n)
  (if (< n 10) (strcat "0" (itoa n)) (itoa n)))

(setq *meses*
  '("Enero" "Febrero" "Marzo" "Abril" "Mayo" "Junio"
    "Julio" "Agosto" "Septiembre" "Octubre" "Noviembre" "Diciembre"))

(defun get-fecha ( / d mo y)
  (setq d  (atoi (menucmd "M=$(edtime,$(getvar,date),DD)")))
  (setq mo (atoi (menucmd "M=$(edtime,$(getvar,date),M)")))
  (setq y        (menucmd "M=$(edtime,$(getvar,date),YYYY)"))
  (strcat (fmt2 d) " de " (nth (1- mo) *meses*) " de " y))

; ================================================================
; GEOMETRÍA DE MANECILLAS
; ================================================================

(defun ang-h (h m)  (* 2 pi (/ (+ (* (rem h 12) 60.0) m) 720.0)))
(defun ang-m (m s)  (* 2 pi (/ (+ (* m 60.0) s) 3600.0)))
(defun ang-s (s)    (* 2 pi (/ s 60.0)))

(defun extremo (cx cy len ar / aa)
  (setq aa (- (/ pi 2.0) ar))
  (list (+ cx (* len (cos aa)))
        (+ cy (* len (sin aa)))
        0.0))

; ================================================================
; CREAR / MOVER ENTIDADES
; ================================================================

(defun crear-manecilla (cx cy len ar capa color lw)
  (entmakex
    (list '(0 . "LINE")
          (cons 8   capa)
          (cons 62  color)
          (cons 370 lw)
          (cons 10  (list cx cy 0.0))
          (cons 11  (extremo cx cy len ar)))))

(defun mover-manecilla (ent cx cy len ar / data)
  (if (and ent (entget ent))
    (progn
      (setq data (entget ent))
      (setq data (subst (cons 11 (extremo cx cy len ar))
                        (assoc 11 data) data))
      (entmod data)
      (redraw ent 4))))

(defun crear-texto (pt h txt)
  (entmakex
    (list '(0 . "TEXT") '(8 . "0")
          (cons 10 pt) (cons 40 h) (cons 1 txt)
          '(72 . 1) (cons 11 pt))))

(defun set-texto (ent str / data)
  (if (and ent (entget ent))
    (progn
      (setq data (entget ent))
      (setq data (subst (cons 1 str) (assoc 1 data) data))
      (entmod data)
      (redraw ent 4))))

; ================================================================
; CARÁTULA
; ================================================================

(defun dibuja-caratula (c r / ang i)
  (command "_.CIRCLE" c r)
  (command "_.CIRCLE" c (* r 0.96))
  (setq ang 0)
  (repeat 12
    (command "_.LINE" (polar c ang r) (polar c ang (* r 0.84)) "")
    (setq ang (+ ang (/ (* 2 pi) 12))))
  (setq ang 0  i 0)
  (repeat 60
    (if (/= (rem i 5) 0)
      (command "_.LINE" (polar c ang r) (polar c ang (* r 0.92)) ""))
    (setq ang (+ ang (/ (* 2 pi) 60)))
    (setq i (1+ i)))
  (command "_.CIRCLE" c (* r 0.03)))

(defun dibuja-marco (px py w h)
  (entmake
    (list '(0 . "LWPOLYLINE") '(100 . "AcDbPolyline") '(90 . 4) '(70 . 1)
          (cons 10 (list (- px (/ w 2)) (- py (/ h 2))))
          (cons 10 (list (+ px (/ w 2)) (- py (/ h 2))))
          (cons 10 (list (+ px (/ w 2)) (+ py (/ h 2))))
          (cons 10 (list (- px (/ w 2)) (+ py (/ h 2)))))))

; ================================================================
; TICK
; ================================================================

(defun tick-update ( / hms h m s cx cy)
  (setq hms (get-hms))
  (setq h (car hms)  m (cadr hms)  s (caddr hms))
  (setq cx (car *reloj-c*)  cy (cadr *reloj-c*))
  (mover-manecilla *ent-h* cx cy (* *reloj-r* 0.55) (ang-h h m))
  (mover-manecilla *ent-m* cx cy (* *reloj-r* 0.80) (ang-m m s))
  (mover-manecilla *ent-s* cx cy (* *reloj-r* 0.90) (ang-s s))
  (set-texto *digital-ent* (strcat (fmt2 h) ":" (fmt2 m) ":" (fmt2 s)))
  (set-texto *fecha-ent*   (get-fecha))
  (redraw))

; ================================================================
; COMANDO PRINCIPAL
; ================================================================

(defun c:RELOJ-VIVO ( / hms h m s cx cy)

  (if (null *reloj-c*)
    (progn
      (setq *reloj-c* (getpoint "\nCentro del reloj: "))
      (setq *reloj-r* (getdist *reloj-c* "\nRadio <50>: "))
      (if (null *reloj-r*) (setq *reloj-r* 50.0))
      (setq cx (car *reloj-c*)  cy (cadr *reloj-c*))

      (dibuja-caratula *reloj-c* *reloj-r*)

      (setq *px-dig* (+ cx (* *reloj-r* 3.0)))
      (setq *py-dig* cy)
      (setq *px-fec* *px-dig*)
      (setq *py-fec* (- cy (* *reloj-r* 0.7)))
      (dibuja-marco *px-dig* *py-dig* (* *reloj-r* 2.2) (* *reloj-r* 0.9))
      (dibuja-marco *px-fec* *py-fec* (* *reloj-r* 2.6) (* *reloj-r* 0.6))

      (setq hms (get-hms))
      (setq h (car hms)  m (cadr hms)  s (caddr hms))

      (setq *ent-h* (crear-manecilla cx cy (* *reloj-r* 0.55)
                      (ang-h h m) "RELOJ_H" 30 80))
      (setq *ent-m* (crear-manecilla cx cy (* *reloj-r* 0.80)
                      (ang-m m s) "RELOJ_M"  3 50))
      (setq *ent-s* (crear-manecilla cx cy (* *reloj-r* 0.90)
                      (ang-s s)   "RELOJ_S"  1 25))

      (if (or (null *ent-h*) (null *ent-m*) (null *ent-s*))
        (progn (princ "\n[ERROR] Manecillas no creadas.") (exit)))

      (setq *digital-ent*
        (crear-texto (list *px-dig* *py-dig*) (* *reloj-r* 0.30) "00:00:00"))
      (setq *fecha-ent*
        (crear-texto (list *px-fec* *py-fec*) (* *reloj-r* 0.18) ""))

      (if (or (null *digital-ent*) (null *fecha-ent*))
        (progn (princ "\n[ERROR] Textos no creados.") (exit)))))

  (tick-update)

  (setq *reloj-on* T)
  (princ "\n[RELOJ] Corriendo. RELOJ-PAUSA para detener.")

  (while *reloj-on*
    (espera-seg 1)
    (if *reloj-on* (tick-update)))

  (princ "\n[RELOJ] Detenido."))

; ================================================================
; AUXILIARES
; ================================================================

(defun c:RELOJ-PAUSA ()
  (setq *reloj-on* nil)
  (princ "\n[RELOJ] Pausado. RELOJ-VIVO para continuar."))

(defun c:RELOJ-RESET ()
  (setq *reloj-on* nil *reloj-c* nil *reloj-r* nil
        *ent-h* nil *ent-m* nil *ent-s* nil
        *digital-ent* nil *fecha-ent* nil)
  (princ "\n[RELOJ] Reset. RELOJ-VIVO para reiniciar."))

(princ "\nRELOJ-VIVO para iniciar.")
(princ)
; ============================================================= FIN