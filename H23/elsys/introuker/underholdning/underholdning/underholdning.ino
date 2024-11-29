#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64

const int chr_width = 12;
int current_offset = 0;

// Declare SSD1306 over I2C
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);
void setup() {
    Serial.begin(115200);

    if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
        Serial.println(F("SSD1306 allocation failed"));
        for(;;);
    }
    delay(200);

    // Display setup
    display.setTextWrap(false);
    display.setRotation(0);
}

void loop() {
    display.clearDisplay();
    display.setTextSize(2);
    display.setTextColor(WHITE);
    display.setCursor(0, 8);

    String name = "Morten Sorensen  ";
    String wraped_name = "";
    current_offset = (current_offset + 1) % name.length();
    for (int i = 0; i < chr_width; i++) {
        wraped_name += name.charAt((current_offset + i) % name.length());
    }

    display.println(wraped_name);
    display.setTextSize(1);
    display.println("Hoyde: 186");
    display.println("Fav. Rus: Viagra");
    display.println("Fritid: Bloons TD");
    display.println("");
    display.println("F1-lag: Idk Revolve");
    display.display();

    delay(500);
}