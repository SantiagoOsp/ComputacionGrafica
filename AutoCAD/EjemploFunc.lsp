; Prensaton, abreviatura para tonelaje de presion.
; Variables:
; perim -> longitud total del perimetro de impresion en pulgadas
; shear -> Esfuerzo cortante en psi
; espesor -> Espesor del material en pulgadas
; tons -> Fuerza de presion en toneladas

; 10==Programa
(defun c:prensaton (/ perim shear espesor tons)
; 20====Obtener espesor, PER+IMETRP Y ESFUERZO CORTANTE
    (initget 7)
    (setq espesor (getreal "\nEspesor del material: "))
    (initget 7)
    (setq perim (getreal "\nLongitud del perimetro de impresion: "))
    (initget 7)
    (setq shear (getreal "\nEsfuerzo cortante: "))

; 30====Calcular tonelaje y presentar informe
    (setq tons (* espesor perim shear 0.0005))
    (princ "\nFuerza de presion requerida = ")
    (princ (rtos tons 2 2))
    (princ " tons (plus 30% = ")
    (princ (rtos (* 1.3 tons) 2 2))
    (princ " tons)")
    (princ)
)