#include <Adafruit_GFX.h>
#include <Adafruit_ST7735.h>
#include <SPI.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>

// Provide the token generation process info
#include <addons/TokenHelper.h>
// Provide the RTDB payload printing info and other helper functions
#include <addons/RTDBHelper.h>

#define WIFI_SSID     "Seni's iphone "
#define WIFI_PASSWORD "senith2005"
#define FIREBASE_HOST "https://fuelstationmanagement-c748c-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH "GAEd5kuRd6yLhOX2RaW1yETNOxCczweSWt8o7JaK"

// ==================== TANK IDENTIFICATION ====================
#define TANK_ID "TANK_001"

// ==================== PIN DEFINITIONS ====================
#define TFT_CS         27
#define TFT_RST        12
#define TFT_DC         2
#define TFT_MOSI       13
#define TFT_SCLK       14

#define TRIG_PIN       5
#define ECHO_PIN       18
#define FLAME_PIN      4
#define ONE_WIRE_BUS   15

#define RELAY_PUMP1    25
#define ALARM_PIN      22

// ==================== SENSOR SETTINGS ====================
const float MIN_DISTANCE = 4.0;
const float MAX_DISTANCE = 20.0;

// ==================== SAFETY SETTINGS ====================
#define PUMP_MAX_RUNTIME  30000
#define COOLDOWN_TIME     5000

// ==================== DISPLAY SETUP ====================
Adafruit_ST7735 tft = Adafruit_ST7735(TFT_CS, TFT_DC, TFT_MOSI, TFT_SCLK, TFT_RST);

// ==================== TEMPERATURE SENSOR ====================
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature tempSensors(&oneWire);

// ==================== FIREBASE ====================
FirebaseData firebaseData;
FirebaseAuth auth;
FirebaseConfig config;

// ==================== GLOBAL VARIABLES ====================
float fuelLevel = 0;
float distance = 0;
float temperature = 0;
bool fireDetected = false;
bool pumpRunning = false;
unsigned long pumpStartTime = 0;
unsigned long lastActivationTime = 0;
bool inCooldown = false;
unsigned long lastDisplayUpdate = 0;
const unsigned long displayInterval = 500;

unsigned long lastFirebaseSync = 0;
const unsigned long firebaseSyncInterval = 5000;
bool wifiConnected = false;
bool firebaseConnected = false;

// *** FIX: flag to prevent duplicate fire event logs ***
bool fireEventLogged = false;

// ==================== SETUP ====================
void setup() {
  Serial.begin(115200);
  delay(500);

  tft.initR(INITR_BLACKTAB);
  tft.setRotation(1);
  tft.fillScreen(ST77XX_BLACK);

  showSplashScreen();
  delay(2500);

  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(FLAME_PIN, INPUT);
  pinMode(RELAY_PUMP1, OUTPUT);
  pinMode(ALARM_PIN, OUTPUT);

  digitalWrite(RELAY_PUMP1, LOW);
  digitalWrite(ALARM_PIN, LOW);

  tempSensors.begin();

  connectWiFi();
  initFirebase();
  drawNormalUI();

  Serial.println("========================================");
  Serial.println("FUEL TANK MONITORING SYSTEM");
  Serial.println("========================================");
  Serial.println("System initialized!");
}

// ==================== MAIN LOOP ====================
void loop() {
  readUltrasonicSensor();
  readTemperatureSensor();
  readFlameSensor();
  handleFireSuppression();

  if (millis() - lastFirebaseSync >= firebaseSyncInterval) {
    sendDataToFirebase();
    lastFirebaseSync = millis();
  }

  if (millis() - lastDisplayUpdate >= displayInterval) {
    if (fireDetected || pumpRunning || inCooldown) {
      updateFireDisplay();
    } else {
      updateNormalDisplay();
    }
    lastDisplayUpdate = millis();
  }

  delay(50);
}

// ==================== SENSOR FUNCTIONS ====================

void readUltrasonicSensor() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  long duration = pulseIn(ECHO_PIN, HIGH, 30000);

  if (duration == 0) {
    distance = MAX_DISTANCE;
  } else {
    distance = (duration * 0.0343) / 2.0;
  }

  if (distance <= MIN_DISTANCE) {
    fuelLevel = 100.0;
  } else if (distance >= MAX_DISTANCE) {
    fuelLevel = 0.0;
  } else {
    fuelLevel = ((MAX_DISTANCE - distance) / (MAX_DISTANCE - MIN_DISTANCE)) * 100.0;
  }

  if (fuelLevel < 0) fuelLevel = 0;
  if (fuelLevel > 100) fuelLevel = 100;
}

void readTemperatureSensor() {
  tempSensors.requestTemperatures();
  temperature = tempSensors.getTempCByIndex(0);

  if (temperature == DEVICE_DISCONNECTED_C) {
    temperature = -999;
  }
}

void readFlameSensor() {
  int flameState = digitalRead(FLAME_PIN);
  fireDetected = (flameState == LOW);
}

// ==================== FIRE SUPPRESSION ====================

void soundHazardAlarm() {
  static unsigned long lastToggle = 0;
  static int phase = 0;

  if (millis() - lastToggle > 150) {
    switch(phase) {
      case 0: tone(ALARM_PIN, 1800); break;
      case 1: tone(ALARM_PIN, 800);  break;
      case 2: tone(ALARM_PIN, 2200); break;
      case 3: tone(ALARM_PIN, 600);  break;
    }
    phase = (phase + 1) % 4;
    lastToggle = millis();
  }
}

void stopAlarm() {
  noTone(ALARM_PIN);
  digitalWrite(ALARM_PIN, LOW);
}

void handleFireSuppression() {
  if (inCooldown) {
    if (millis() - lastActivationTime >= COOLDOWN_TIME) {
      inCooldown = false;
      drawNormalUI();
    }
    return;
  }

  if (fireDetected && !pumpRunning) {
    delay(100);
    digitalWrite(RELAY_PUMP1, HIGH);
    pumpRunning = true;
    pumpStartTime = millis();
    drawFireUI();
    Serial.println("FIRE HAZARD DETECTED!");
  }

  if (pumpRunning) {
    soundHazardAlarm();
    unsigned long runtime = millis() - pumpStartTime;

    if (!fireDetected) {
      digitalWrite(RELAY_PUMP1, LOW);
      stopAlarm();
      pumpRunning = false;
      lastActivationTime = millis();
      inCooldown = true;
      Serial.println("Fire suppressed");
      drawNormalUI();
    }

    if (runtime >= PUMP_MAX_RUNTIME) {
      digitalWrite(RELAY_PUMP1, LOW);
      stopAlarm();
      pumpRunning = false;
      lastActivationTime = millis();
      inCooldown = true;
      Serial.println("Safety timeout");
      drawNormalUI();
    }
  }
}

// ==================== WIFI & FIREBASE FUNCTIONS ====================

void connectWiFi() {
  Serial.println();
  Serial.print("Connecting to WiFi");

  tft.fillScreen(ST77XX_BLACK);
  tft.setTextColor(ST77XX_CYAN);
  tft.setTextSize(1);
  tft.setCursor(10, 50);
  tft.print("Connecting WiFi...");

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    wifiConnected = true;
    Serial.println();
    Serial.println("WiFi connected!");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());

    tft.setTextColor(ST77XX_GREEN);
    tft.setCursor(10, 70);
    tft.print("WiFi Connected!");
    delay(1000);
  } else {
    wifiConnected = false;
    Serial.println();
    Serial.println("WiFi connection failed!");

    tft.setTextColor(ST77XX_RED);
    tft.setCursor(10, 70);
    tft.print("WiFi Failed!");
    delay(2000);
  }
}

void initFirebase() {
  if (!wifiConnected) {
    Serial.println("Cannot init Firebase - No WiFi");
    return;
  }

  Serial.println("Initializing Firebase...");

  tft.fillScreen(ST77XX_BLACK);
  tft.setTextColor(ST77XX_CYAN);
  tft.setTextSize(1);
  tft.setCursor(10, 50);
  tft.print("Connecting Firebase...");

  config.database_url = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  if (Firebase.ready()) {
    firebaseConnected = true;
    Serial.println("Firebase connected!");

    tft.setTextColor(ST77XX_GREEN);
    tft.setCursor(10, 70);
    tft.print("Firebase Ready!");

    sendInitialData();
    delay(1000);
  } else {
    firebaseConnected = false;
    Serial.println("Firebase connection failed!");

    tft.setTextColor(ST77XX_RED);
    tft.setCursor(10, 70);
    tft.print("Firebase Failed!");
    delay(2000);
  }
}

void sendInitialData() {
  String path = "/tanks/" + String(TANK_ID);

  Firebase.RTDB.setString(&firebaseData, path + "/info/tankId",   TANK_ID);
  Firebase.RTDB.setString(&firebaseData, path + "/info/location", "Underground");
  Firebase.RTDB.setString(&firebaseData, path + "/info/status",   "online");
  Firebase.RTDB.setInt   (&firebaseData, path + "/info/lastBoot", millis());

  Serial.println("Initial data sent to Firebase");
}

void sendDataToFirebase() {
  if (!firebaseConnected || !wifiConnected) {
    return;
  }

  String path = "/tanks/" + String(TANK_ID);

  // Sensor data
  Firebase.RTDB.setFloat(&firebaseData, path + "/sensors/fuelLevel",   fuelLevel);
  Firebase.RTDB.setFloat(&firebaseData, path + "/sensors/temperature", temperature);
  Firebase.RTDB.setFloat(&firebaseData, path + "/sensors/distance",    distance);

  // Status data
  Firebase.RTDB.setBool(&firebaseData, path + "/status/fireDetected", fireDetected);
  Firebase.RTDB.setBool(&firebaseData, path + "/status/pumpRunning",  pumpRunning);
  Firebase.RTDB.setBool(&firebaseData, path + "/status/inCooldown",   inCooldown);

  // Timestamp
  Firebase.RTDB.setInt(&firebaseData, path + "/timestamp", millis());

  // Alert level
  String alertLevel = "normal";
  if (fireDetected) {
    alertLevel = "critical";
  } else if (fuelLevel < 20) {
    alertLevel = "warning";
  } else if (fuelLevel < 50) {
    alertLevel = "info";
  }
  Firebase.RTDB.setString(&firebaseData, path + "/alertLevel", alertLevel);

  // *** FIX: log fire event once per fire incident only ***
  if (fireDetected && !fireEventLogged) {
    logFireEvent();
    fireEventLogged = true;
  }

  // *** FIX: reset flag when fire clears so next fire gets logged ***
  if (!fireDetected) {
    fireEventLogged = false;
  }

  Serial.print("Firebase sync: Fuel=");
  Serial.print(fuelLevel, 1);
  Serial.print("% Temp=");
  Serial.print(temperature, 1);
  Serial.print("C Fire=");
  Serial.println(fireDetected ? "YES" : "NO");
}

void logFireEvent() {
  // *** FIX: use counter-based path so events never overwrite each other ***
  static int eventCount = 0;
  eventCount++;

  String eventPath = "/tanks/" + String(TANK_ID) + "/events/fire/event_" + String(eventCount);

  Firebase.RTDB.setFloat (&firebaseData, eventPath + "/fuelLevel",     fuelLevel);
  Firebase.RTDB.setFloat (&firebaseData, eventPath + "/temperature",   temperature);
  Firebase.RTDB.setInt   (&firebaseData, eventPath + "/timestamp",     millis());
  Firebase.RTDB.setString(&firebaseData, eventPath + "/status",        "detected");
  Firebase.RTDB.setBool  (&firebaseData, eventPath + "/pumpActivated", pumpRunning);

  Serial.print("Fire event logged: event_");
  Serial.println(eventCount);
}

// ==================== DISPLAY FUNCTIONS ====================

void showSplashScreen() {
  tft.fillScreen(ST77XX_BLACK);
  tft.setTextColor(ST77XX_ORANGE);
  tft.setTextSize(2);
  tft.setCursor(5, 25);
  tft.print("UNDERGROUND");
  tft.setCursor(20, 45);
  tft.print("FUEL TANK");
  tft.setTextSize(1);
  tft.setTextColor(ST77XX_YELLOW);
  tft.setCursor(15, 75);
  tft.print("Monitoring System");
  tft.setTextColor(ST77XX_CYAN);
  tft.setCursor(45, 95);
  tft.print("v1.0");
}

void drawNormalUI() {
  tft.fillScreen(ST77XX_BLACK);

  tft.fillRect(0, 0, 160, 20, ST77XX_BLUE);
  tft.setTextColor(ST77XX_WHITE);
  tft.setTextSize(1);
  tft.setCursor(8, 6);
  tft.print("FUEL TANK MONITOR");

  tft.drawLine(80, 20, 80, 128, ST77XX_ORANGE);
}

void drawFireUI() {
  tft.fillScreen(ST77XX_BLACK);

  tft.fillRect(0, 0, 160, 25, ST77XX_RED);
  tft.setTextColor(ST77XX_YELLOW);
  tft.setTextSize(2);
  tft.setCursor(15, 7);
  tft.print("! FIRE !");
}

void updateNormalDisplay() {
  drawFuelCircle(40, 74, 35);
  drawTemperature(120, 74);
}

void updateFireDisplay() {
  drawFireIcon(40, 50);

  tft.fillRect(0, 90, 160, 38, ST77XX_BLACK);
  tft.setTextSize(1);
  tft.setTextColor(ST77XX_YELLOW);
  tft.setCursor(10, 95);
  tft.print("SUPPRESSION ACTIVE");

  if (pumpRunning) {
    unsigned long runtime = (millis() - pumpStartTime) / 1000;
    tft.setCursor(35, 108);
    tft.setTextColor(ST77XX_WHITE);
    tft.print("Time: ");
    tft.print(runtime);
    tft.print("s");
  }

  if (inCooldown) {
    tft.setCursor(30, 108);
    tft.setTextColor(ST77XX_CYAN);
    tft.print("Cooldown...");
  }
}

void drawFuelCircle(int x, int y, int radius) {
  tft.fillCircle(x, y, radius + 2, ST77XX_BLACK);
  tft.drawCircle(x, y, radius, ST77XX_WHITE);

  int fillAngle = (fuelLevel / 100.0) * 360;

  for (int angle = 0; angle < fillAngle; angle += 2) {
    float rad = angle * 3.14159 / 180.0;
    int x1 = x + (radius - 1) * cos(rad);
    int y1 = y + (radius - 1) * sin(rad);

    uint16_t color;
    if (fuelLevel > 50) color = ST77XX_GREEN;
    else if (fuelLevel > 20) color = ST77XX_YELLOW;
    else color = ST77XX_RED;

    tft.drawLine(x, y, x1, y1, color);
  }

  tft.fillCircle(x, y, radius - 10, ST77XX_BLACK);

  tft.setTextSize(2);
  if (fuelLevel > 50) tft.setTextColor(ST77XX_GREEN);
  else if (fuelLevel > 20) tft.setTextColor(ST77XX_YELLOW);
  else tft.setTextColor(ST77XX_RED);

  tft.setCursor(x - 18, y - 8);
  if (fuelLevel < 10) {
    tft.print(" ");
  }
  tft.print((int)fuelLevel);
  tft.print("%");

  tft.setTextSize(1);
  tft.setTextColor(ST77XX_CYAN);
  tft.setCursor(x - 15, y + 25);
  tft.print("FUEL");
}

void drawTemperature(int x, int y) {
  tft.fillRect(x - 35, y - 35, 70, 70, ST77XX_BLACK);

  drawSnowflakeIcon(x, y - 15);

  tft.setTextSize(2);
  if (temperature == -999) {
    tft.setTextColor(ST77XX_RED);
    tft.setCursor(x - 25, y + 10);
    tft.print("ERR");
  } else {
    if (temperature < 25) tft.setTextColor(ST77XX_CYAN);
    else if (temperature < 40) tft.setTextColor(ST77XX_GREEN);
    else tft.setTextColor(ST77XX_ORANGE);

    tft.setCursor(x - 20, y + 10);
    tft.print(temperature, 0);
    tft.setTextSize(1);
    tft.print("C");
  }

  tft.setTextSize(1);
  tft.setTextColor(ST77XX_CYAN);
  tft.setCursor(x - 15, y + 30);
  tft.print("TEMP");
}

void drawSnowflakeIcon(int x, int y) {
  uint16_t color = ST77XX_CYAN;
  int size = 8;

  tft.drawLine(x, y - size, x, y + size, color);
  tft.drawLine(x - size, y, x + size, y, color);
  tft.drawLine(x - size/1.4, y - size/1.4, x + size/1.4, y + size/1.4, color);
  tft.drawLine(x - size/1.4, y + size/1.4, x + size/1.4, y - size/1.4, color);

  tft.drawLine(x, y - size, x - 2, y - size + 3, color);
  tft.drawLine(x, y - size, x + 2, y - size + 3, color);
  tft.drawLine(x, y + size, x - 2, y + size - 3, color);
  tft.drawLine(x, y + size, x + 2, y + size - 3, color);
}

void drawFireIcon(int x, int y) {
  static bool flicker = false;
  flicker = !flicker;

  uint16_t color1 = flicker ? ST77XX_RED : ST77XX_ORANGE;
  uint16_t color2 = flicker ? ST77XX_ORANGE : ST77XX_YELLOW;

  tft.fillRect(x - 20, y - 25, 40, 50, ST77XX_BLACK);

  tft.fillTriangle(x, y - 20, x - 15, y + 20, x + 15, y + 20, color1);
  tft.fillTriangle(x, y - 15, x - 8,  y + 15, x + 8,  y + 15, color2);
  tft.fillCircle(x, y - 15, 5, ST77XX_YELLOW);

  tft.drawCircle(x, y, 25, ST77XX_RED);
  tft.drawCircle(x, y, 26, ST77XX_ORANGE);
}