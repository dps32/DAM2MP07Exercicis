package com.project;

import javafx.fxml.FXML;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import org.json.JSONObject;

public class MobileDetailController {

    @FXML private ImageView detailImage;
    @FXML private Label detailTitle, detailDescription;
    private static JSONObject currentItem;
    private static String currentCategory;
    private static MobileDetailController instance;

    // Mostrar detalles del item seleccionado
    public static void setItem(JSONObject item, String category) {
        currentItem = item;
        currentCategory = category;
        if (instance != null) {
            instance.updateView();
        }
    }

    @FXML
    private void initialize() {
        instance = this;
        if (currentItem != null) {
            updateView();
        }
    }

    // actualizar info
    private void updateView() {
        if (currentItem == null) return;
        
        detailTitle.setText(currentItem.getString("name"));
        switch (currentCategory) {
            case "Games" -> detailDescription.setText(currentItem.getString("plot"));
            case "Characters" -> detailDescription.setText("Game: " + currentItem.getString("game") +
                                                           "\nColor: " + currentItem.getString("color"));
            case "Consoles" -> detailDescription.setText("Processor: " + currentItem.getString("procesador") +
                                                          "\nUnits sold: " + currentItem.getInt("units_sold"));
        }
        detailImage.setImage(new Image(MobileDetailController.class.getResourceAsStream("/assets/images/" + currentItem.getString("image"))));
    }

    @FXML
    private void goBack() {
        UtilsViews.setViewAnimating("MobileList");
    }
}
