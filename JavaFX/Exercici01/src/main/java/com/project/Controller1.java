package com.project;

import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.TextField;

public class Controller1 {

    @FXML
    private Button enterButton;

    @FXML
    private TextField nameField;

    @FXML
    private TextField ageField;


    @FXML
    private void enterButtonPressed() {
        String name = nameField.getText();
        String age = ageField.getText();

        Main.name = name;
        Main.age = age;

        Controller2 ctrl2 = (Controller2) UtilsViews.getController("View2");
        ctrl2.setData(name, age);

        UtilsViews.setView("View2"); // anem a la vista 2
    }
}
