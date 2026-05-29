gestion_datos : dialog {
  label = "Control de Activos - Datos Extendidos";

  : boxed_column {
    label = "Informacion del Objeto";

    : edit_box {
      label = "Application Name:";
      key = "app_name";
      edit_width = 20;
    }

    : edit_box {
      label = "ID Equipo:";
      key = "id_equipo";
      edit_width = 20;
    }

    : edit_box {
      label = "Potencia (W):";
      key = "potencia";
      edit_width = 20;
    }
  }

  : row {
    alignment = centered;
    : button {
      label = "Guardar";
      key = "accept";
      is_default = true;
    }
    : button {
      label = "Cancelar";
      key = "cancel";
      is_cancel = true;
    }
  }
}

resumen_consumo : dialog {
  label = "Resumen de Consumo Electrico";
  width = 40;

  : boxed_column {
    label = "Potencia";

    : text { key = "txt_apps";       label = "Apps revisadas :"; }
    : text { key = "txt_total_w";    label = "Potencia total  :"; }
    : text { key = "txt_kwh";        label = "Energia mensual :"; }
  }

  : boxed_column {
    label = "Costo estimado";

    : text { key = "txt_tarifa";     label = "Tarifa (kWh)    :"; }
    : text { key = "txt_horas";      label = "Horas al mes    :"; }
    : text { key = "txt_costo";      label = "COSTO ESTIMADO  :"; }
  }

  spacer;

  : row {
    alignment = centered;
    : button {
      label = "Cerrar";
      key = "accept";
      is_default = true;
      is_cancel  = true;
    }
  }
}