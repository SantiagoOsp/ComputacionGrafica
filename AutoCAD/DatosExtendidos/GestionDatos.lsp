
;; Auxiliar: extrae el numero
(defun extraer-watts (str / pos)
  (setq pos (vl-string-search " " str))
  (if pos
    (atof (substr str 1 pos))
    (atof str)
  )
)

;; Auxiliar: guarda XData dado un appname, id y potencia
(defun guardar-xdata (ent appname id pot / xdata)
  (if (not (tblsearch "APPID" appname))
    (regapp appname)
  )
  (setq xdata
    (list -3
      (list appname
        (cons 1002 "{")
        (cons 1000 id)
        (cons 1000 (strcat pot " W"))
        (cons 1002 "}")
      )
    )
  )
  (entmod (append (entget ent) (list xdata)))
  (entupd ent)
)

;; Auxiliar: lee XData
(defun leer-xdata (ent appname / raw app-data)
  (setq raw (assoc -3 (entget ent (list appname))))
  (if raw
    (cdr (cadr raw))   ; ((1002 . "{") (1000 . "valor") ...)
    nil
  )
)

;; EDITARDATOS: agrega/modifica XData con app name elegido
(defun c:EditarDatos (/ ent dialogID xlist id pot appname dcl-path xdata-existente)

  (setq ent (car (entsel "\nSelecciona un bloque: ")))

  (if (null ent)
    (princ "\nNo se selecciono ningun objeto.")
    (progn
      (setq dcl-path (findfile "GestionDatos.dcl"))
      (if (null dcl-path)
        (setq dcl-path (strcat (getvar "DWGPREFIX") "GestionDatos.dcl"))
      )

      (setq dialogID (load_dialog dcl-path))

      (if (< dialogID 0)
        (princ (strcat "\nError: No se encontro el DCL en: " dcl-path))
        (progn
          (if (not (new_dialog "gestion_datos" dialogID))
            (princ "\nError: No se pudo abrir el dialogo.")
            (progn
              ;; Intentar leer datos existentes (primero ELECTRICAL, luego GESTION_ACTIVOS)
              ;; para precargar el dialogo si ya tiene datos
              (setq xdata-existente (leer-xdata ent "ELECTRICAL"))
              (if (null xdata-existente)
                (setq xdata-existente (leer-xdata ent "GESTION_ACTIVOS"))
              )

              (if xdata-existente
                (progn
                  ;; Precargar campos con datos existentes
                  ;; xdata-existente = ((1002 . "{") (1000 . "id") (1000 . "550 W") (1002 . "}"))
                  (set_tile "id_equipo" (cdr (nth 1 xdata-existente)))
                  (set_tile "potencia"
                    (car (str-extraer (cdr (nth 2 xdata-existente))))
                  )
                )
              )

              ;; Accion boton Guardar: captura los 3 campos
              (action_tile "accept"
                "(setq appname (get_tile \"app_name\"))
                 (setq id      (get_tile \"id_equipo\"))
                 (setq pot     (get_tile \"potencia\"))
                 (done_dialog 1)"
              )

              (if (= (start_dialog) 1)
                (progn
                  (cond
                    ((= appname "")
                     (princ "\nError: El Application Name no puede estar vacio."))
                    ((= id "")
                     (princ "\nError: El ID no puede estar vacio."))
                    ((= pot "")
                     (princ "\nError: La potencia no puede estar vacia."))
                    (T
                     (guardar-xdata ent appname id pot)
                     (princ (strcat "\nDatos guardados en [" appname "] -> ID: " id "  Potencia: " pot " W"))
                    )
                  )
                )
                (princ "\nOperacion cancelada.")
              )
            )
          )
          (unload_dialog dialogID)
        )
      )
    )
  )
  (princ)
)

;; Auxiliar: separa string por espacio
(defun str-extraer (str / pos)
  (setq pos (vl-string-search " " str))
  (if pos
    (list (substr str 1 pos))
    (list str)
  )
)

;; Cálculo de consumo con base en XDATA
(defun c:CalcularConsumo (/ ss i ent raw-xdata app-data xlist vatios total-w
                            horas tarifa costo kwh apps-buscar
                            dialogID dcl-path txt-apps)

  (setq horas       240.0) ;8 horas al d a por un mes
  (setq tarifa      850.0) ;precio aprox. kWh
  (setq total-w     0.0)
  (setq i           0)
  (setq apps-buscar (list "ELECTRICAL" "GESTION_ACTIVOS"))

  (setq ss (ssget "X"))

  (if (null ss)
    (princ "\nNo hay objetos en el dibujo.")
    (progn

      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (setq i   (1+ i))

        (foreach appname apps-buscar
          (setq raw-xdata (assoc -3 (entget ent (list appname))))

          (if raw-xdata
            (progn
              (setq app-data (cadr raw-xdata))
              (setq xlist    (cdr app-data))

              (foreach par xlist
                (if (= (car par) 1000)
                  (progn
                    (setq vatios (extraer-watts (cdr par)))
                    (if (> vatios 0)
                      (progn
                        (princ (strcat "\n  [" appname "] " (cdr par) " -> " (rtos vatios 2 1) " W"))
                        (setq total-w (+ total-w vatios))
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )

      (setq kwh   (/ (* total-w horas) 1000.0))
      (setq costo (* kwh tarifa))

      ;; --- Imprimir en consola (igual que antes) ---
      (princ "\n")
      (princ "\n  RESUMEN DE CONSUMO ELECTRICO")
      (princ "\n")
      (princ (strcat "\n  Apps revisadas    : " (vl-princ-to-string apps-buscar)))
      (princ (strcat "\n  Potencia total    : " (rtos total-w 2 1) " W"))
      (princ (strcat "\n  Energia mensual   : " (rtos kwh 2 2) " kWh"))
      (princ (strcat "\n  Tarifa aplicada   : $" (rtos tarifa 2 4) " / kWh"))
      (princ (strcat "\n  Horas calculadas  : " (rtos horas 2 0) " h/mes"))
      (princ "\n")
      (princ (strcat "\n  COSTO ESTIMADO    : $" (rtos costo 2 2)))
      (princ "\n\n")

      (setq dcl-path (findfile "GestionDatos.dcl"))
      (if (null dcl-path)
        (setq dcl-path (strcat (getvar "DWGPREFIX") "GestionDatos.dcl"))
      )

      (setq dialogID (load_dialog dcl-path))

      (if (< dialogID 0)
        (princ "\nError: No se pudo cargar el DCL para mostrar el resumen.")
        (progn
          (if (not (new_dialog "resumen_consumo" dialogID))
            (princ "\nError: No se pudo abrir el dialogo de resumen.")
            (progn
              (setq txt-apps "")
              (foreach a apps-buscar
                (setq txt-apps (strcat txt-apps a " "))
              )

              (set_tile "txt_apps"    (strcat "Apps revisadas : " txt-apps))
              (set_tile "txt_total_w" (strcat "Potencia total  : " (rtos total-w 2 1) " W"))
              (set_tile "txt_kwh"     (strcat "Energia mensual : " (rtos kwh 2 2) " kWh"))
              (set_tile "txt_tarifa"  (strcat "Tarifa (kWh)    : $" (rtos tarifa 2 4)))
              (set_tile "txt_horas"   (strcat "Horas al mes    : " (rtos horas 2 0) " h/mes"))
              (set_tile "txt_costo"   (strcat "COSTO ESTIMADO  : $" (rtos costo 2 2)))

              (start_dialog)
            )
          )
          (unload_dialog dialogID)
        )
      )
    )
  )
  (princ)
)

;; VERXDATA: diagnostico
(defun c:VerXData (/ ent xdata)
  (setq ent (car (entsel "\nSelecciona un elemento con XData: ")))
  (if ent
    (progn
      (princ "\n--- entget completo con ELECTRICAL ---")
      (princ (entget ent '("ELECTRICAL")))
      (princ "\n--- Solo XData ---")
      (setq xdata (assoc -3 (entget ent '("ELECTRICAL"))))
      (princ xdata)
    )
  )
  (princ)
)