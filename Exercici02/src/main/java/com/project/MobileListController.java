package com.project;

import javafx.fxml.FXML;
import javafx.scene.layout.VBox;
import javafx.scene.layout.HBox;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

public class MobileListController {

    @FXML private VBox listContainer;
    @FXML private Label categoryTitle;
    private static String category;
    private static JSONArray jsonInfo;
    private static MobileListController instance;

    // establecer categoria a mostrar
    public static void setCategory(String cat) {
        category = cat;
        loadData();
        if (instance != null) {
            instance.categoryTitle.setText(cat);
            instance.renderList();
        }
    }

    @FXML // boton ir paar atras
    private void goBack() {
        UtilsViews.setViewAnimating("MobileMenu");
    }

    // cargar los datos del json
    private static void loadData() {
        try {
            String jsonFile = switch (category) {
                case "Games" -> "/assets/games.json";
                case "Characters" -> "/assets/characters.json";
                case "Consoles" -> "/assets/consoles.json";
                default -> "";
            };
            InputStream is = MobileListController.class.getResourceAsStream(jsonFile);
            String content = new String(is.readAllBytes(), StandardCharsets.UTF_8);
            jsonInfo = new JSONArray(content);
        } catch(Exception e) { e.printStackTrace(); }
    }

    @FXML
    private void initialize() {
        instance = this;
        if (jsonInfo != null) {
            renderList();
        }
    }

    // renderizamos la lista
    private void renderList() {
        listContainer.getChildren().clear();
        if (jsonInfo == null) return;
        
        // por cada item del json creamos una box horizontal
        for (int i = 0; i < jsonInfo.length(); i++) {
            JSONObject item = jsonInfo.getJSONObject(i);

            HBox itemBox = new HBox(5);
            itemBox.alignmentProperty().set(javafx.geometry.Pos.CENTER_LEFT);

            // foto
            ImageView img = new ImageView(new Image(getClass().getResourceAsStream("/assets/images/" + item.getString("image"))));
            img.setFitWidth(100);
            img.setFitHeight(60);
            img.setPreserveRatio(true);

            // nombre
            Label lbl = new Label(item.getString("name"));
            lbl.setStyle("-fx-font-size: 18px; -fx-font-weight: bold;");

            // añadir imagen y textoa la box
            itemBox.getChildren().addAll(img, lbl);
            itemBox.setOnMouseClicked(e -> {
                MobileDetailController.setItem(item, category);
                UtilsViews.setViewAnimating("MobileDetail");
            });

            listContainer.getChildren().add(itemBox);
        }
    }
}
