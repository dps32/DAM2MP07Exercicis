const tools = [
  {
    "type": "function",
    "function": {
      "name": "draw_line",
      "description":
          "Dibuixa una linia. Pots usar coordenades absolutes o percentatges de la mida del canvas.",
      "parameters": {
        "type": "object",
        "properties": {
          "startX": {"type": "number"},
          "startY": {"type": "number"},
          "endX": {"type": "number"},
          "endY": {"type": "number"},
          "startPercentX": {"type": "number"},
          "startPercentY": {"type": "number"},
          "endPercentX": {"type": "number"},
          "endPercentY": {"type": "number"},
          "color": {"type": "string"},
          "strokeWidth": {"type": "number"}
        }
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "draw_circle",
      "description":
          "Dibuixa un cercle amb contorn, emplenat opcional i gradient opcional.",
      "parameters": {
        "type": "object",
        "properties": {
          "x": {"type": "number"},
          "y": {"type": "number"},
          "percentX": {"type": "number"},
          "percentY": {"type": "number"},
          "radius": {"type": "number"},
          "strokeColor": {"type": "string"},
          "fillColor": {"type": "string"},
          "gradientTo": {"type": "string"},
          "gradient": {
            "type": "string",
            "enum": ["none", "linear", "radial"]
          },
          "strokeWidth": {"type": "number"}
        }
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "draw_rectangle",
      "description":
          "Dibuixa un quadre o rectangle amb contorn, emplenat opcional i gradient opcional.",
      "parameters": {
        "type": "object",
        "properties": {
          "topLeftX": {"type": "number"},
          "topLeftY": {"type": "number"},
          "bottomRightX": {"type": "number"},
          "bottomRightY": {"type": "number"},
          "topLeftPercentX": {"type": "number"},
          "topLeftPercentY": {"type": "number"},
          "bottomRightPercentX": {"type": "number"},
          "bottomRightPercentY": {"type": "number"},
          "strokeColor": {"type": "string"},
          "fillColor": {"type": "string"},
          "gradientTo": {"type": "string"},
          "gradient": {
            "type": "string",
            "enum": ["none", "linear", "radial"]
          },
          "strokeWidth": {"type": "number"}
        }
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "draw_text",
      "description":
          "Escriu text al canvas amb tipografia, mida, color, negreta i cursiva.",
      "parameters": {
        "type": "object",
        "properties": {
          "text": {"type": "string"},
          "x": {"type": "number"},
          "y": {"type": "number"},
          "percentX": {"type": "number"},
          "percentY": {"type": "number"},
          "color": {"type": "string"},
          "fontSize": {"type": "number"},
          "fontFamily": {"type": "string"},
          "bold": {"type": "boolean"},
          "italic": {"type": "boolean"}
        },
        "required": ["text"]
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "select_shape",
      "description":
          "Selecciona una figura pel seu id o per una posicio del canvas.",
      "parameters": {
        "type": "object",
        "properties": {
          "id": {"type": "integer"},
          "x": {"type": "number"},
          "y": {"type": "number"},
          "percentX": {"type": "number"},
          "percentY": {"type": "number"}
        }
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "delete_shape",
      "description":
          "Esborra una figura pel seu id. Si no hi ha id, esborra la seleccionada.",
      "parameters": {
        "type": "object",
        "properties": {
          "id": {"type": "integer"}
        }
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "update_shape",
      "description":
          "Canvia propietats d'una figura. Si no hi ha id, modifica la seleccionada o l'ultima creada.",
      "parameters": {
        "type": "object",
        "properties": {
          "id": {"type": "integer"},
          "x": {"type": "number"},
          "y": {"type": "number"},
          "percentX": {"type": "number"},
          "percentY": {"type": "number"},
          "endX": {"type": "number"},
          "endY": {"type": "number"},
          "width": {"type": "number"},
          "height": {"type": "number"},
          "radius": {"type": "number"},
          "strokeColor": {"type": "string"},
          "fillColor": {"type": "string"},
          "color": {"type": "string"},
          "gradientTo": {"type": "string"},
          "gradient": {
            "type": "string",
            "enum": ["none", "linear", "radial"]
          },
          "strokeWidth": {"type": "number"},
          "text": {"type": "string"},
          "fontSize": {"type": "number"},
          "fontFamily": {"type": "string"},
          "bold": {"type": "boolean"},
          "italic": {"type": "boolean"}
        }
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "clear_canvas",
      "description": "Esborra totes les figures del canvas.",
      "parameters": {"type": "object", "properties": {}}
    }
  }
];
