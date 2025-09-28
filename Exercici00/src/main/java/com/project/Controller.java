package com.project;

import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.text.Text;
import javafx.event.ActionEvent;

public class Controller {

    
    @FXML private Button button1;
    @FXML private Button button2;
    @FXML private Button button3;
    @FXML private Button button4;
    @FXML private Button button5;
    @FXML private Button button6;
    @FXML private Button button7;
    @FXML private Button button8;
    @FXML private Button button9;
    @FXML private Button button0;

    @FXML private Button buttonAdd;
    @FXML private Button buttonSubtract;
    @FXML private Button buttonMultiply;
    @FXML private Button buttonDivide;
    @FXML private Button buttonClear;
    @FXML private Button buttonResult;

    @FXML
    private Text resultText;


    // ADD - 1
    // SUBTRACT - 2
    // MULTIPLY - 3
    // DIVIDE - 4
    private int nextAction = 0;


    // Click a un botó de número
    @FXML
    private void numberButtonClicked(ActionEvent event) {
        Button clickedButton = (Button) event.getSource(); // el numero clicat

        String prevString = resultText.getText(); // el text que hi havia abans al resultat
        String clickedString = clickedButton.getText(); // el text del número clicat

        String textResult = ""; // iniciem el text resultat
        float result = 0; // iniciem el valor resultat

        // si hi ha una acció pendent
        if (nextAction != 0) {
            float prevInt = !prevString.isEmpty() ? Float.parseFloat(prevString) : 0; // el valor del resultat previ
            float clickedInt = !clickedString.isEmpty() ? Float.parseFloat(clickedString) : 0; // el valor del numero clicat

            switch (nextAction) {
                case 1: // suma
                    result = prevInt + clickedInt;
                    break;
                case 2: // resta
                    result = prevInt - clickedInt;
                    break;
                case 3: // multiplicació
                    result = prevInt * clickedInt;
                    break;
                case 4: // divisió
                    result = prevInt / clickedInt;
                    break;
                default:
                    break;
            }

            // convertim el resultat a text i resetejem la acció
            textResult = String.valueOf(result);
            nextAction = 0;
        }
        else {
            textResult = prevString + clickedString; // afegim el numero clicat al text si no hi ha acció
        }

        resultText.setText(textResult); // actualitzem el text del resltat
    }

    // Click a un botó d'acció
    @FXML
    private void actionButtonClicked(ActionEvent event) {
        Button clickedButton = (Button) event.getSource();
        String clickedString = clickedButton.getText();

        switch (clickedString) {
            case "+": // suma
                nextAction = 1;
                break;
            case "-": // resta
                nextAction = 2;
                break;
            case "X": // multiplicació
                nextAction = 3;
                break;
            case "/": // divisió
                nextAction = 4;
                break;
            case "<-": // esborrar l'últim número
                String currentText = resultText.getText();
                if (currentText.length() > 0)
                    resultText.setText(currentText.substring(0, currentText.length() - 1));
                
                break;
            case "C": // esborrar tot
                resultText.setText(""); // treiem el resultat
                nextAction = 0; // resetejem l'acció
                break;
            default:
                break;
        }
    }
}
