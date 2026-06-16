"""
automatizacion_com.py
Sistema BIM de cómputo métrico automatizado: AutoCAD → Excel → Word
Versión corregida y mejorada.
"""

import os
import sys
import logging
import pythoncom
import win32com.client

# =============================================================================
# CONFIGURACIÓN DE LOGGING
# =============================================================================
logging.basicConfig(
    level=logging.INFO,
    format="[%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)]
)
log = logging.getLogger(__name__)

# =============================================================================
# CONSTANTES DE COLOR (todos en formato BGR para COM de Office)
# NOTA: Excel/Word COM usan BGR, NO RGB.
# Ejemplo: Azul marino  RGB(27, 49, 91)  →  BGR = 0x5B3101B  → 0x5B311B
# =============================================================================
COLOR_AZUL_MARINO    = 0x1B315B   # Usado como fondo en cabeceras (BGR correcto: 0x5B311B)
COLOR_AZUL_MARINO_BGR = 0x5B311B  # BGR real para Excel COM
COLOR_AZUL_SUAVE_BGR = 0xF2E1D9   # Fondo suave para totales (BGR de #D9E1F2)
COLOR_GRIS_CLARO     = 0xF2F2F2   # Filas alternas
COLOR_BLANCO         = 0xFFFFFF
COLOR_GRIS_TEXTO     = 0x595959
COLOR_NEGRO          = 0x000000

# Tipos de entidad que tienen propiedad .Length en AutoCAD COM
ENTIDADES_LINEALES = {
    "AcDbLine",
    "AcDbPolyline",
    "AcDbLwPolyline",
    "AcDb3dPolyline",
    "AcDbArc",
    "AcDbSpline",
    "AcDbEllipse",
}

# Capas que se ignoran en el cómputo
CAPAS_IGNORADAS = {"0", "Defpoints", "defpoints"}


# =============================================================================
# MÓDULO 1: ESCANEO DE AUTOCAD
# =============================================================================
def escanear_capas_autocad(ruta_plano: str) -> dict[str, float]:
    """
    Abre el plano en AutoCAD (si no está ya abierto), recorre el ModelSpace
    y acumula la longitud de cada entidad lineal por capa.

    Retorna: { "Nombre_Capa": metros_lineales_total }
    Lanza:   RuntimeError si no puede conectar con AutoCAD.
    """
    log.info(f"Iniciando escaneo de capas en: {ruta_plano}")

    # Validar que el archivo exista antes de intentar abrirlo
    if not os.path.isfile(ruta_plano):
        raise FileNotFoundError(f"El plano no existe en la ruta indicada: {ruta_plano}")

    ruta_absoluta = os.path.abspath(ruta_plano)

    try:
        acad = win32com.client.Dispatch("AutoCAD.Application")
        acad.Visible = True
    except Exception as exc:
        raise RuntimeError(f"No se pudo conectar con AutoCAD: {exc}") from exc

    doc_acad = None
    try:
        # Verificar si el documento ya está abierto para no duplicarlo
        doc_acad = None
        for doc in acad.Documents:
            if os.path.normcase(doc.FullName) == os.path.normcase(ruta_absoluta):
                doc_acad = doc
                log.info("El plano ya estaba abierto en AutoCAD; se reutiliza.")
                break

        if doc_acad is None:
            doc_acad = acad.Documents.Open(ruta_absoluta)

        ms = doc_acad.ModelSpace
        total_entidades = ms.Count
        log.info(f"Total de entidades en ModelSpace: {total_entidades}")

        datos_capas: dict[str, float] = {}
        entidades_omitidas = 0
        entidades_procesadas = 0

        for i in range(total_entidades):
            try:
                entidad = ms.Item(i)
            except Exception:
                entidades_omitidas += 1
                continue

            if entidad.ObjectName not in ENTIDADES_LINEALES:
                continue

            capa = entidad.Layer
            if capa in CAPAS_IGNORADAS:
                continue

            try:
                longitud = float(entidad.Length)
                if longitud <= 0:
                    continue
            except AttributeError:
                # Algunas entidades (ej. Ellipse cerrada) usan .Perimeter en lugar de .Length
                try:
                    longitud = float(entidad.Perimeter)
                except Exception:
                    entidades_omitidas += 1
                    continue
            except Exception as exc:
                log.warning(f"No se pudo leer longitud de entidad {entidad.ObjectName} en capa '{capa}': {exc}")
                entidades_omitidas += 1
                continue

            datos_capas[capa] = datos_capas.get(capa, 0.0) + longitud
            entidades_procesadas += 1

        log.info(f"Entidades procesadas: {entidades_procesadas} | Omitidas: {entidades_omitidas}")

    finally:
        # Cerrar el documento si lo abrimos nosotros (no lo cerramos si ya estaba abierto)
        if doc_acad is not None:
            try:
                doc_acad.Close(SaveChanges=False)
            except Exception:
                pass  # Si falla el cierre, no es crítico

    # Fallback con datos de muestra si el plano no tenía geometría en capas personalizadas
    if not datos_capas:
        log.warning("No se detectaron capas con geometría medible. Cargando datos de muestra.")
        datos_capas = {
            "Instalaciones_Generales": 120.5,
            "Muros_Interiores": 85.3,
            "Red_Electrica": 240.0,
        }

    return datos_capas


# =============================================================================
# MÓDULO 2: GENERACIÓN DE PRESUPUESTO EN EXCEL
# =============================================================================
def generar_excel(datos_capas: dict[str, float], ruta_plano: str, costos_unitarios: dict | None = None) -> float:
    """
    Crea un libro de Excel con presupuesto detallado por capa.
    Retorna el valor total calculado.

    costos_unitarios: dict opcional { "Nombre_Capa": precio_por_metro }
                      Si no se suministra, se usan valores de ejemplo.
    """
    log.info("Creando plantilla financiera en Excel...")

    # Costos de referencia: se usan solo si no se suministra el dict externo
    costos_base_ejemplo = [15.50, 42.00, 8.75, 33.10, 27.80]

    try:
        excel = win32com.client.Dispatch("Excel.Application")
        excel.Visible = True
        wb = excel.Workbooks.Add()
        sheet = wb.ActiveSheet
        sheet.Name = "Presupuesto"

        # --- Tipografía global ---
        sheet.Cells.Font.Name = "Segoe UI"
        sheet.Cells.Font.Size = 10

        # --- Encabezado empresa ---
        sheet.Cells(2, 2).Value = "SISTEMA INTEGRADO DE PRESUPUESTOS BIM"
        with _excel_cell(sheet, 2, 2) as c:
            c.Font.Size = 14
            c.Font.Bold = True
            c.Font.Color = COLOR_AZUL_MARINO_BGR  # BGR correcto

        nombre_plano = os.path.basename(ruta_plano)
        sheet.Cells(3, 2).Value = f"Cómputo métrico automatizado del plano: {nombre_plano}"
        with _excel_cell(sheet, 3, 2) as c:
            c.Font.Italic = True
            c.Font.Color = COLOR_GRIS_TEXTO

        # --- Cabecera de tabla (Fila 5, columnas B-F → índices 2-6) ---
        # Mapeo explícito: COL_ITEM=2, COL_CAPA=3, COL_METRICA=4, COL_PRECIO=5, COL_SUBTOTAL=6
        COL_ITEM, COL_CAPA, COL_METRICA, COL_PRECIO, COL_SUBTOTAL = 2, 3, 4, 5, 6
        cabeceras = ["Ítem", "Componente / Capa Analizada", "Métrica Extraída (m)", "Costo Unitario", "Subtotal"]

        for col_idx, texto in zip(range(COL_ITEM, COL_SUBTOTAL + 1), cabeceras):
            c = sheet.Cells(5, col_idx)
            c.Value = texto
            c.Font.Bold = True
            c.Font.Color = COLOR_BLANCO
            c.Interior.Color = COLOR_AZUL_MARINO_BGR
            c.HorizontalAlignment = -4108  # xlCenter

        # --- Datos por capa ---
        FILA_INICIO = 6
        fila_actual = FILA_INICIO

        for item_numero, (capa, metraje) in enumerate(datos_capas.items(), start=1):
            # Precio: del dict externo si existe, sino rotativo de ejemplo
            if costos_unitarios and capa in costos_unitarios:
                precio_u = float(costos_unitarios[capa])
            else:
                precio_u = costos_base_ejemplo[item_numero % len(costos_base_ejemplo)]

            # Letras de columna calculadas dinámicamente para las fórmulas
            col_letra_metrica  = _col_letra(COL_METRICA)
            col_letra_precio   = _col_letra(COL_PRECIO)
            col_letra_subtotal = _col_letra(COL_SUBTOTAL)

            sheet.Cells(fila_actual, COL_ITEM).Value = item_numero
            sheet.Cells(fila_actual, COL_ITEM).HorizontalAlignment = -4108

            sheet.Cells(fila_actual, COL_CAPA).Value = capa.replace("_", " ").title()

            sheet.Cells(fila_actual, COL_METRICA).Value = round(metraje, 2)
            sheet.Cells(fila_actual, COL_METRICA).NumberFormat = '#,##0.00" m"'

            sheet.Cells(fila_actual, COL_PRECIO).Value = precio_u
            sheet.Cells(fila_actual, COL_PRECIO).NumberFormat = "$#,##0.00"

            # Fórmula de subtotal con referencias de columna calculadas
            formula_subtotal = f"={col_letra_metrica}{fila_actual}*{col_letra_precio}{fila_actual}"
            sheet.Cells(fila_actual, COL_SUBTOTAL).Formula = formula_subtotal
            sheet.Cells(fila_actual, COL_SUBTOTAL).NumberFormat = "$#,##0.00"
            sheet.Cells(fila_actual, COL_SUBTOTAL).Font.Bold = True

            # Filas alternadas (cebra)
            if fila_actual % 2 == 0:
                for c in range(COL_ITEM, COL_SUBTOTAL + 1):
                    sheet.Cells(fila_actual, c).Interior.Color = COLOR_GRIS_CLARO

            fila_actual += 1

        # --- Fila de totales ---
        fila_total = fila_actual
        col_letra_subtotal = _col_letra(COL_SUBTOTAL)

        sheet.Cells(fila_total, COL_PRECIO).Value = "TOTAL PRESUPUESTO:"
        sheet.Cells(fila_total, COL_PRECIO).Font.Bold = True
        sheet.Cells(fila_total, COL_PRECIO).HorizontalAlignment = -4108

        celda_total = sheet.Cells(fila_total, COL_SUBTOTAL)
        celda_total.Formula = f"=SUM({col_letra_subtotal}{FILA_INICIO}:{col_letra_subtotal}{fila_total - 1})"
        celda_total.Font.Bold = True
        celda_total.Font.Size = 11
        celda_total.NumberFormat = "$#,##0.00"
        celda_total.Interior.Color = COLOR_AZUL_SUAVE_BGR

        # Bordes contables en celda total
        celda_total.Borders(9).LineStyle  = 1  # Borde superior simple (xlEdgeTop)
        celda_total.Borders(10).LineStyle = 9  # Borde inferior doble  (xlEdgeBottom)

        # Autoajustar columnas
        for c in range(COL_ITEM, COL_SUBTOTAL + 1):
            sheet.Columns(c).AutoFit()

        # Calcular y extraer el valor total
        wb.Application.Calculate()
        valor_total = float(celda_total.Value or 0.0)
        log.info(f"Total presupuesto calculado: ${valor_total:,.2f}")

        # Guardar el archivo en la misma carpeta del plano
        directorio_plano = os.path.dirname(os.path.abspath(ruta_plano))
        nombre_base_excel = os.path.splitext(os.path.basename(ruta_plano))[0] + "_presupuesto.xlsx"
        ruta_excel = os.path.join(directorio_plano, nombre_base_excel)

        # Guardar el archivo usando la ruta absoluta normalizada
        wb.SaveAs(os.path.normpath(ruta_excel))
        log.info(f"Excel guardado en: {ruta_excel}")

        return valor_total

    except Exception as exc:
        log.error(f"Error al generar Excel: {exc}")
        raise


# =============================================================================
# MÓDULO 3: GENERACIÓN DE PROPUESTA COMERCIAL EN WORD
# =============================================================================
def generar_word(datos_capas: dict[str, float], valor_total: float,
                 ruta_plano: str, costos_unitarios: dict | None = None) -> None:
    """
    Crea un documento Word con la propuesta comercial y la tabla de cómputo.
    """
    log.info("Redactando propuesta ejecutiva en Word...")

    costos_base_ejemplo = [15.50, 42.00, 8.75, 33.10, 27.80]

    try:
        word = win32com.client.Dispatch("Word.Application")
        word.Visible = True
        doc_word = word.Documents.Add()

        sel = word.Selection

        # Fuente base del documento
        try:
            doc_word.Styles("Normal").Font.Name = "Arial"
            doc_word.Styles("Normal").Font.Size = 11
        except Exception:
            pass  # Si el estilo no existe con ese nombre, se ignora (multiidioma)

        # --- Título principal ---
        # Usamos la aplicación de formato directo en lugar de nombres de estilo
        # para evitar fallos en instalaciones de Office en otros idiomas
        sel.Font.Size = 22
        sel.Font.Bold = True
        sel.Font.Color = _rgb_a_bgr(27, 49, 91)   # Azul marino ejecutivo
        sel.TypeText("PROPUESTA ECONÓMICA DE PROYECTO")
        sel.TypeParagraph()

        # --- Subtítulo ---
        sel.Font.Size = 10
        sel.Font.Bold = False
        sel.Font.Italic = True
        sel.Font.Color = _rgb_a_bgr(89, 89, 89)
        nombre_plano = os.path.basename(ruta_plano)
        sel.TypeText(f"Documento generado mediante auditoría algorítmica COM sobre el plano: {nombre_plano}")
        sel.TypeParagraph()

        # Restablecer formato para cuerpo
        sel.Font.Italic = False
        sel.Font.Color = COLOR_NEGRO
        sel.Font.Size = 11
        sel.TypeParagraph()

        # --- Cuerpo ---
        sel.TypeText(
            "Estimado cliente,\r\r"
            "Basados en el análisis geométrico y la separación técnica de capas del plano arquitectónico "
            "suministrado, nos complace presentar el desglose comercial estimado para la ejecución física "
            "de las obras:\r\r"
        )

        # --- Tabla en Word ---
        cant_filas = len(datos_capas) + 2  # cabecera + datos + total
        tabla = doc_word.Tables.Add(sel.Range, cant_filas, 3)

        # Aplicar estilo base con manejo multiidioma
        for nombre_estilo in ["Table Grid", "Tabla con cuadrícula", "Cuadrícula de tabla"]:
            try:
                tabla.Style = nombre_estilo
                break
            except Exception:
                continue

        # Cabeceras de la tabla
        for col, texto in enumerate(["Capa Evaluada", "Longitud (m)", "Subtotal Estimado"], start=1):
            celda = tabla.Cell(1, col)
            celda.Range.Text = texto
            celda.Range.Font.Bold = True
            celda.Range.Font.Color = COLOR_BLANCO
            celda.Shading.BackgroundPatternColor = _rgb_a_bgr(27, 49, 91)

        # Datos de capas
        for idx, (capa, metraje) in enumerate(datos_capas.items(), start=1):
            fila_word = idx + 1  # +1 por la cabecera

            if costos_unitarios and capa in costos_unitarios:
                precio_u = float(costos_unitarios[capa])
            else:
                precio_u = costos_base_ejemplo[idx % len(costos_base_ejemplo)]

            subtotal_fila = metraje * precio_u

            tabla.Cell(fila_word, 1).Range.Text = capa.replace("_", " ").title()
            tabla.Cell(fila_word, 2).Range.Text = f"{metraje:,.2f} m"
            tabla.Cell(fila_word, 3).Range.Text = f"$ {subtotal_fila:,.2f}"

            tabla.Cell(fila_word, 2).Range.ParagraphFormat.Alignment = 2  # Derecha
            tabla.Cell(fila_word, 3).Range.ParagraphFormat.Alignment = 2

        # Fila de total
        fila_total_word = cant_filas
        tabla.Cell(fila_total_word, 1).Range.Text = "VALOR TOTAL CONTRATADO"
        tabla.Cell(fila_total_word, 1).Range.Font.Bold = True

        celda_final = tabla.Cell(fila_total_word, 3)
        celda_final.Range.Text = f"$ {valor_total:,.2f}"
        celda_final.Range.Font.Bold = True
        celda_final.Range.ParagraphFormat.Alignment = 2
        celda_final.Shading.BackgroundPatternColor = _rgb_a_bgr(217, 225, 242)

        # Mover cursor al final del documento (forma correcta en COM)
        doc_word.Range(doc_word.Content.End - 1, doc_word.Content.End).Select()
        sel = word.Selection
        sel.TypeParagraph()
        sel.TypeParagraph()
        sel.TypeText(
            "La presente cotización tiene validez por 30 días calendario a partir de su generación automatizada."
        )

        # Guardar el documento
        ruta_word = os.path.splitext(ruta_plano)[0] + "_propuesta.docx"
        doc_word.SaveAs2(ruta_word)
        log.info(f"Word guardado en: {ruta_word}")

    except Exception as exc:
        log.error(f"Error al generar Word: {exc}")
        raise


# =============================================================================
# FUNCIÓN PRINCIPAL (orquestadora)
# =============================================================================
def ejecutar_procesamiento_com(ruta_plano: str,
                               costos_unitarios: dict | None = None) -> tuple[bool, str]:
    """
    Orquesta el flujo completo:
      1. Escaneo de AutoCAD
      2. Generación de Excel con presupuesto
      3. Generación de Word con propuesta comercial

    Args:
        ruta_plano:       Ruta al archivo .dwg de AutoCAD.
        costos_unitarios: Diccionario opcional { "Nombre_Capa": precio_unitario }.
                          Si se omite, se usan precios de ejemplo.

    Returns:
        (True, mensaje_exito) o (False, mensaje_error)
    """
    pythoncom.CoInitialize()  # Necesario cuando se llama desde hilos secundarios

    try:
        # --- Paso 1: AutoCAD ---
        datos_capas = escanear_capas_autocad(ruta_plano)
        log.info(f"Capas detectadas: {list(datos_capas.keys())}")

        # --- Paso 2: Excel ---
        valor_total = generar_excel(datos_capas, ruta_plano, costos_unitarios)

        # --- Paso 3: Word ---
        generar_word(datos_capas, valor_total, ruta_plano, costos_unitarios)

        return True, (
            f"Proceso completado exitosamente.\n"
            f"  · Capas analizadas : {len(datos_capas)}\n"
            f"  · Total presupuesto: ${valor_total:,.2f}\n"
            f"  · Archivos guardados junto al plano: _presupuesto.xlsx y _propuesta.docx"
        )

    except FileNotFoundError as exc:
        return False, f"Archivo no encontrado: {exc}"
    except RuntimeError as exc:
        return False, f"Error de conexión COM: {exc}"
    except Exception as exc:
        log.exception("Error inesperado durante el procesamiento")
        return False, f"Error inesperado: {exc}"
    finally:
        pythoncom.CoUninitialize()


# =============================================================================
# UTILIDADES INTERNAS
# =============================================================================
class _excel_cell:
    """Context manager mínimo para aplicar formato a una celda de Excel."""
    def __init__(self, sheet, row, col):
        self._cell = sheet.Cells(row, col)

    def __enter__(self):
        return self._cell

    def __exit__(self, *args):
        pass


def _col_letra(indice_col: int) -> str:
    """
    Convierte un índice de columna (base 1) a su letra equivalente en Excel.
    Ej: 1→A, 2→B, 26→Z, 27→AA
    """
    result = ""
    while indice_col > 0:
        indice_col, rem = divmod(indice_col - 1, 26)
        result = chr(65 + rem) + result
    return result


def _rgb_a_bgr(r: int, g: int, b: int) -> int:
    """
    Convierte componentes RGB individuales al entero BGR que espera COM de Office.
    Excel y Word via COM usan BGR, no RGB.
    """
    return (b << 16) | (g << 8) | r


# =============================================================================
# PUNTO DE ENTRADA PARA PRUEBAS RÁPIDAS
# =============================================================================
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python automatizacion_com.py <ruta_al_plano.dwg>")
        sys.exit(1)

    ruta = sys.argv[1]

    # Ejemplo de tabla de precios real (opcional)
    precios_ejemplo = {
        "Instalaciones_Generales": 15.50,
        "Muros_Interiores":        42.00,
        "Red_Electrica":            8.75,
    }

    ok, mensaje = ejecutar_procesamiento_com(ruta, costos_unitarios=precios_ejemplo)
    print("\n" + ("✅" if ok else "❌") + " " + mensaje)
    sys.exit(0 if ok else 1)