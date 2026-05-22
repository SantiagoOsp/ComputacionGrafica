(defun c:EditarDatos (/ ent obj data dialogID)
  ; 1. Seleccionar el objeto (bloque)
  (setq ent (car (entsel "\nSelecciona un bloque: ")))
  (if ent
    (progn
      ; 2. Cargar el DCL
      (setq dialogID (load_dialog "GestionDatos.dcl"))
      (if (new_dialog "gestion_datos" dialogID)
        (progn
          ; 3. Intentar leer XData existentes (si los hay)
          (setq data (cdr (assoc -3 (entget ent '("GESTION_ACTIVOS")))))
          
          ; Si hay datos, los cargamos en el diálogo
          (if data
            (progn
              (set_tile "id_equipo" (cdr (nth 1 (car data))))
              (set_tile "potencia" (cdr (nth 2 (car data))))
            )
          )

          ; 4. Acción del botón Guardar
          (action_tile "accept" "(setq id (get_tile \"id_equipo\")) (setq pot (get_tile \"potencia\")) (done_dialog 1)")
          
          (if (= (start_dialog) 1)
            (progn
              ; 5. Guardar/Modificar XData
              (setq xdata (list -3 (list "GESTION_ACTIVOS" (cons 1000 id) (cons 1000 pot))))
              (entmod (append (entget ent) (list xdata)))
              (princ "\nDatos guardados correctamente.")
            )
          )
        )
      )
      (unload_dialog dialogID)
    )
  )
  (princ)
)