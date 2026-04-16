const express = require("express");
const cors = require("cors");
const path = require("path");
const db = require("./data/paintings_data");

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

// esto hace que las imágenes estén disponibles al hacer /images/nombre.jpg
app.use("/images", express.static(path.join(__dirname, "images")));

app.get("/", (req, res) => {
    res.json({
        name: "Classic Paintings DB API",
        status: "ok",
        endpoints: ["POST /categories", "POST /items", "POST /detail", "POST /search", "GET /images/:file"]
    });
});

// endpoint para obtener categorías
app.post("/categories", (req, res) => {
    res.json({ ok: true, data: db.getCategories() });
});


// obtener las pinturas de una categoría
app.post("/items", (req, res) => {
    const categoryId = req.body.categoryId;

    if (!categoryId) {
        return res.status(400).json({ ok: false, error: "categoryId is required" });
    }

    const items = db.getItemsByCategory(categoryId);
    return res.json({ ok: true, data: items });
});

// obtener el detalle de una pintura
app.post("/detail", (req, res) => {
    const itemId = req.body.itemId;

    if (!itemId) {
        return res.status(400).json({ ok: false, error: "itemId is required" });
    }

    const detail = db.getItemDetail(itemId);

    if (!detail) {
        return res.status(404).json({ ok: false, error: "Item not found" });
    }

    return res.json({ ok: true, data: detail });
});

// buscar una pintura por datos de la pintura
app.post("/search", (req, res) => {
    const query = req.body.query;
    const result = db.searchItems(query);

    return res.json({ ok: true, data: result });
});

app.listen(port, () => {
    console.log(`Classic Paintings DB server running on http://localhost:${port}`);
});
