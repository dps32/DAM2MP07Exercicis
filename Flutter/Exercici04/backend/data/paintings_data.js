const categories = [
  { id: "renaissance", name: "Renacimiento", description: "Obras clave del Renacimiento europeo" },
  { id: "baroque", name: "Barroco", description: "Pintura dramática del Barroco" },
  { id: "modern", name: "Moderno y contemporáneo", description: "Obras icónicas de los siglos XIX y XX" }
];

const items = [
  {
    id: "mona_lisa",
    categoryId: "renaissance",
    title: "Mona Lisa",
    subtitle: "Leonardo da Vinci",
    year: "c.1503",
    image: "mona_lisa.jpg",
    description: "Retrato de referencia del Renacimiento, famoso por su técnica de sfumato y su expresión enigmática."
  },
  {
    id: "last_supper",
    categoryId: "renaissance",
    title: "La última cena",
    subtitle: "Leonardo da Vinci",
    year: "1495-1498",
    image: "last_supper.jpg",
    description: "Mural ubicado en Santa María delle Grazie. Destaca por su composición narrativa y uso de perspectiva."
  },
  {
    id: "school_athens",
    categoryId: "renaissance",
    title: "La escuela de Atenas",
    subtitle: "Rafael",
    year: "1509-1511",
    image: "school_athens.jpg",
    description: "Fresco que representa filósofos clásicos en un espacio arquitectónico idealizado, símbolo del humanismo."
  },
  {
    id: "creation_adam",
    categoryId: "renaissance",
    title: "La creación de Adán",
    subtitle: "Miguel Ángel",
    year: "c.1512",
    image: "creation_adam.jpg",
    description: "Detalle de la Capilla Sixtina reconocido por el gesto de las manos, ícono visual de la cultura popular."
  },
  {
    id: "night_watch",
    categoryId: "baroque",
    title: "La ronda de noche",
    subtitle: "Rembrandt",
    year: "1642",
    image: "night_watch.jpg",
    description: "Retrato colectivo con gran dinamismo y tratamiento de la luz, una de las obras maestras del barroco holandés."
  },
  {
    id: "girl_pearl",
    categoryId: "baroque",
    title: "La joven de la perla",
    subtitle: "Johannes Vermeer",
    year: "c.1665",
    image: "girl_pearl.jpg",
    description: "Tronie célebre por la mirada de la figura y el contraste entre sombra y luz sobre el pendiente de perla."
  },
  {
    id: "las_meninas",
    categoryId: "baroque",
    title: "Las Meninas",
    subtitle: "Diego Velázquez",
    year: "1656",
    image: "las_meninas.jpg",
    description: "Composición compleja sobre la representación y el punto de vista, pieza central del Museo del Prado."
  },
  {
    id: "birth_venus",
    categoryId: "renaissance",
    title: "El nacimiento de Venus",
    subtitle: "Sandro Botticelli",
    year: "c.1485",
    image: "birth_venus.jpg",
    description: "Ícono del Renacimiento florentino, reconocido por su composición mitológica y elegancia lineal."
  },
  {
    id: "scream",
    categoryId: "modern",
    title: "El grito",
    subtitle: "Edvard Munch",
    year: "1893",
    image: "scream.jpg",
    description: "Imagen símbolo del expresionismo que transmite ansiedad y tensión psicológica mediante forma y color."
  },
  {
    id: "persistence_memory",
    categoryId: "modern",
    title: "La persistencia de la memoria",
    subtitle: "Salvador Dalí",
    year: "1931",
    image: "persistence_memory.jpg",
    description: "Obra surrealista de relojes blandos que cuestiona la percepción del tiempo y la realidad."
  },
  {
    id: "guernica",
    categoryId: "modern",
    title: "Guernica",
    subtitle: "Pablo Picasso",
    year: "1937",
    image: "guernica.jpg",
    description: "Lienzo monumental contra la guerra, con lenguaje cubista y fuerte carga política y emocional."
  },
  {
    id: "dogs_playing_poker",
    categoryId: "modern",
    title: "Perros jugando al poker",
    subtitle: "Cassius Marcellus Coolidge",
    year: "1903",
    image: "dogs_playing_poker.jpg",
    description: "Serie popular de ilustraciones de perros jugando cartas. Se convirtió en ícono cultural y decorativo."
  }
];

function getCategoryName(categoryId) {
  for (let i = 0; i < categories.length; i += 1) {
    if (categories[i].id === categoryId) {
      return categories[i].name;
    }
  }

  return "Desconocido";
}

function getCategories() {
  return categories;
}

function getItemsByCategory(categoryId) {
  const result = [];

  for (let i = 0; i < items.length; i += 1) {
    if (items[i].categoryId === categoryId) {
      result.push({
        id: items[i].id,
        title: items[i].title,
        subtitle: items[i].subtitle,
        year: items[i].year,
        image: items[i].image,
        categoryId: items[i].categoryId
      });
    }
  }

  return result;
}

function getItemDetail(itemId) {
  for (let i = 0; i < items.length; i += 1) {
    if (items[i].id === itemId) {
      return {
        id: items[i].id,
        title: items[i].title,
        subtitle: items[i].subtitle,
        year: items[i].year,
        image: items[i].image,
        description: items[i].description,
        categoryId: items[i].categoryId,
        categoryName: getCategoryName(items[i].categoryId)
      };
    }
  }

  return null;
}

// buscar la pintura por título, subtítulo, descripción o categoría
function searchItems(query) {
  const cleanQuery = String(query || "").trim().toLowerCase();
  const result = [];

  if (!cleanQuery) {
    return result;
  }

  for (let i = 0; i < items.length; i += 1) {
    const item = items[i];
    const categoryName = getCategoryName(item.categoryId).toLowerCase();

    const inTitle = item.title.toLowerCase().includes(cleanQuery);
    const inSubtitle = item.subtitle.toLowerCase().includes(cleanQuery);
    const inDescription = item.description.toLowerCase().includes(cleanQuery);
    const inCategory = categoryName.includes(cleanQuery);

    if (inTitle || inSubtitle || inDescription || inCategory) {
      result.push({
        id: item.id,
        title: item.title,
        subtitle: item.subtitle,
        year: item.year,
        image: item.image,
        categoryId: item.categoryId,
        categoryName: getCategoryName(item.categoryId)
      });
    }
  }

  return result;
}

module.exports = {
  getCategories,
  getItemsByCategory,
  getItemDetail,
  searchItems
};
