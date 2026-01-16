package com.project;

import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.text.Text;

public class Controller2 {

    @FXML
    private Text resultText;

    @FXML
    private Button returnButton;

    public void setData(String name, String age) {
        resultText.setText("Hola " + name + ", tens " + age + " anys!");
    }

    @FXML
    private void returnButtonPressed() {
        UtilsViews.setView("View1"); // tornem a la vista 1
    }

}
