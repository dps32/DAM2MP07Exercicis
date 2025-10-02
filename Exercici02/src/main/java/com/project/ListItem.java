package com.project;

import javafx.fxml.FXML;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;

public class ListItem {

    @FXML private ImageView itemImage;
    @FXML private Label itemName;
    @FXML private Label itemExtra;

    public void setTitle(String title) {
        itemName.setText(title);
    }

    public void setImage(String path) {
        try {
            itemImage.setImage(new Image(getClass().getResourceAsStream(path)));
        } catch(Exception e) {
            e.printStackTrace();
        }
    }
}
