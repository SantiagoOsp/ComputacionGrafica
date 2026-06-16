# interfaz.py
import os
import tkinter as tk
from tkinter import filedialog, messagebox, ttk

# Importamos la lógica COM
from main import ejecutar_procesamiento_com

class AplicacionPresupuesto:
    def __init__(self, ventana):
        self.ventana = ventana
        self.ventana.title("Generador de presupuesto AutoCAD")
        self.ventana.geometry("550x380")
        self.ventana.configure(bg="#1e1e24")
        self.ventana.resizable(False, False)
        
        self.ruta_archivo = ""

        # --- CONTENEDOR PRINCIPAL (Para dar margen interno) ---
        contenedor = tk.Frame(ventana, bg="#1e1e24")
        contenedor.pack(padx=30, pady=25, fill=tk.BOTH, expand=True)

        # --- LOGO O ICONO SIMULADO / ENCABEZADO ---
        lbl_logo = tk.Label(
            contenedor, 
            text="📊 SISTEMA GENERADOR EN BASE A PRESUPUESTO", 
            font=("Segoe UI", 10, "bold"), 
            fg="#4f46e5", 
            bg="#1e1e24",
            anchor="w"
        )
        lbl_logo.pack(fill=tk.X)

        # Título Principal
        lbl_titulo = tk.Label(
            contenedor, 
            text="Extractor Automatizado de Presupuestos", 
            font=("Segoe UI", 16, "bold"), 
            fg="#f3f4f6", # Blanco suave
            bg="#1e1e24",
            anchor="w"
        )
        lbl_titulo.pack(fill=tk.X, pady=(0, 5))

        # Descripción corta
        lbl_desc = tk.Label(
            contenedor, 
            text="Audita la base de datos geométrica de cualquier plano .dwg mediante interoperabilidad COM y genera reportes ejecutivos en Office.", 
            font=("Segoe UI", 9), 
            fg="#9ca3af", # Gris claro descriptivo
            bg="#1e1e24",
            wraplength=480,
            justify="left",
            anchor="w"
        )
        lbl_desc.pack(fill=tk.X, pady=(0, 20))

        # --- SECCIÓN DE SELECCIÓN DE ARCHIVO ---
        frame_archivo = tk.Frame(contenedor, bg="#2a2b36", bd=1, relief=tk.SOLID)
        frame_archivo.pack(fill=tk.X, pady=10, ipady=8, ipadx=8)

        # Botón estilizado para buscar
        self.btn_buscar = tk.Button(
            frame_archivo, 
            text="📂 Seleccionar Plano", 
            command=self.seleccionar_plano, 
            bg="#3b82f6", # Azul moderno
            fg="white",
            font=("Segoe UI", 9, "bold"),
            relief=tk.FLAT,
            activebackground="#2563eb",
            activeforeground="white",
            cursor="hand2",
            padx=10
        )
        self.btn_buscar.pack(side=tk.LEFT, padx=(10, 5))

        # Texto interno que muestra la ruta o estado
        self.lbl_archivo = tk.Label(
            frame_archivo, 
            text="Por favor, cargue un archivo de AutoCAD...", 
            fg="#9ca3af", 
            bg="#2a2b36",
            font=("Segoe UI", 9, "italic"),
            anchor="w"
        )
        self.lbl_archivo.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=10)

        # --- SECCIÓN DE ESTADO / PROGRESO SIMULADO ---
        self.lbl_estado = tk.Label(
            contenedor,
            text="Estado: Esperando interacción del usuario.",
            font=("Segoe UI", 8),
            fg="#6b7280",
            bg="#1e1e24",
            anchor="w"
        )
        self.lbl_estado.pack(fill=tk.X, pady=(15, 0))

        # --- BOTÓN DE ACCIÓN PRINCIPAL ---
        # Usamos una apariencia deshabilitada imponente al inicio
        self.btn_procesar = tk.Button(
            contenedor, 
            text="🚀 INICIAR PROCESAMIENTO", 
            command=self.procesar_sistema, 
            bg="#374151", # Gris oscuro bloqueado
            fg="#9ca3af",
            font=("Segoe UI", 11, "bold"), 
            relief=tk.FLAT,
            state=tk.DISABLED, 
            cursor="arrow",
            pady=10
        )
        self.btn_procesar.pack(fill=tk.X, side=tk.BOTTOM, pady=(10, 0))

    def seleccionar_plano(self):
        archivo = filedialog.askopenfilename(
            title="Seleccionar plano de AutoCAD para auditoría",
            filetypes=[("Planos de AutoCAD", "*.dwg")]
        )
        
        if archivo:
            self.ruta_archivo = archivo
            nombre_corto = os.path.basename(archivo)
            
            # Actualizar diseño al cargar archivo exitosamente
            self.lbl_archivo.config(text=nombre_corto, fg="#34d399", font=("Segoe UI", 10, "bold")) # Verde esmeralda
            self.lbl_estado.config(text="Estado: Listo para escanear y presupuestar.", fg="#34d399")
            
            # Activar el botón de procesamiento con un color verde brillante muy vivo
            self.btn_procesar.config(
                state=tk.NORMAL, 
                bg="#10b981", # Verde corporativo
                fg="white",
                activebackground="#059669",
                activeforeground="white",
                cursor="hand2"
            )

    def procesar_sistema(self):
        # Bloquear controles visualmente durante el proceso COM
        self.btn_procesar.config(state=tk.DISABLED, bg="#374151", text="⚡ EJECUTANDO MACROS COM EN OFFICE...")
        self.btn_buscar.config(state=tk.DISABLED, bg="#4b5563")
        self.lbl_estado.config(text="Estado: Extrayendo capas de AutoCAD y formateando documentos...", fg="#f59e0b") # Naranja alerta
        self.ventana.update()

        # EJECUCIÓN DEL BACKEND (VBA/COM)
        exito, mensaje = ejecutar_procesamiento_com(self.ruta_archivo)

        # Restaurar controles e interfaz al terminar
        self.btn_buscar.config(state=tk.NORMAL, bg="#3b82f6")
        self.btn_procesar.config(
            state=tk.NORMAL, 
            bg="#10b981", 
            text="🚀 INICIAR PROCESAMIENTO"
        )
        self.lbl_estado.config(text="Estado: Procesamiento finalizado con éxito.", fg="#34d399")

        # Alertas del Sistema Operativo nativas
        if exito:
            messagebox.showinfo("¡Éxito del Sistema!", "La auditoría COM finalizó:\n\n1. Capas leídas de AutoCAD.\n2. Cuadro de costos formateado en Excel.\n3. Propuesta comercial redactada en Word.")
        else:
            self.lbl_estado.config(text="Estado: Error crítico en la ejecución.", fg="#ef4444")
            messagebox.showerror("Error de Interoperabilidad", f"El motor COM reportó un fallo:\n\n{mensaje}")

if __name__ == "__main__":
    root = tk.Tk()
    app = AplicacionPresupuesto(root)
    root.mainloop()