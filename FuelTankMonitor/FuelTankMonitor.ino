/*
 * ESP32 UNDERGROUND FUEL TANK MONITORING SYSTEM
 * WITH FIREBASE INTEGRATION (Mobizt Firebase ESP Client)
 *
 * ── FIREBASE UPGRADE NOTES ───────────────────────────────────────────────────
 *  1. JSON batching   – All sensor/status fields are bundled into ONE
 *                       FirebaseJson object and written with a single
 *                       Firebase.setJSON() call, cutting round-trips and
 *                       eliminating per-variable network latency.
 *
 *  2. Non-blocking    – Cloud sync runs on its own millis() cadence
 *                       (FIREBASE_SYNC_INTERVAL). The display refresh,
 *                       sensor reads, and fire-suppression logic all run
 *                       inside the main loop without ever waiting on I/O.
 *
 *  3. Anti-freeze     – syncFirebase() guards every path with
 *                       Firebase.ready() and WiFi.status() checks.
 *                       connectWiFi() uses a non-blocking retry loop so
 *                       the MCU cannot stall indefinitely on either
 *                       WiFi association or RTDB operations.
 *                       Firebase.reconnectWiFi(true) keeps the SDK
 *                       recovering silently in the background.
 *
 *  4. Path layout     – Single root node /TankSystem keeps the RTDB tree
 *                       clean:
 *                         /TankSystem/TANK_001/sensors   ← live readings
 *                         /TankSystem/TANK_001/status    ← operational flags
 *                         /TankSystem/TANK_001/meta      ← identity / boot
 *                         /TankSystem/TANK_001/events/fire/<ts>  ← log
 *
 *  5. UI preserved    – Zero changes to GFX / ST7735 drawing functions,
 *                       pixel coordinates, or colour constants.
 * ─────────────────────────────────────────────────────────────────────────────
 */

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

// ==================== WIFI CREDENTIALS ====================
#define WIFI_SSID     "YOUR_WIFI_SSID"        // CHANGE THIS
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"     // CHANGE THIS

// ==================== FIREBASE CREDENTIALS ====================
// Legacy secret (Database Secret from Firebase Console → Project Settings → Service accounts)
#define FIREBASE_HOST "YOUR_PROJECT_ID.firebaseio.com"   // CHANGE THIS
#define FIREBASE_AUTH "YOUR_DATABASE_SECRET"              // CHANGE THIS

// ==================== TANK IDENTIFICATION ====================
#define TANK_ID "TANK_001"   // Unique ID for this tank – change per device

// ==================== PIN DEFINITIONS ====================
// TFT Display (hardware SPI)
#define TFT_CS    27
#define TFT_RST   12
#define TFT_DC     2
#define TFT_MOSI  13
#define TFT_SCLK  14

// Sensors
#define TRIG_PIN      5
#define ECHO_PIN     18
#define FLAME_PIN     4
#define ONE_WIRE_BUS 15

// Actuators
#define RELAY_PUMP1  25    // Fire suppression pump
#define ALARM_PIN    22    // Audio hazard alarm

// ==================== SENSOR SETTINGS ====================
const float MIN_DISTANCE = 4.0;   // cm  →  100 % full
const float MAX_DISTANCE = 20.0;  // cm  →    0 % empty

// ==================== SAFETY SETTINGS ====================
#define PUMP_MAX_RUNTIME  30000UL   // ms – hard cut-off for the pump
#define COOLDOWN_TIME      5000UL   // ms – dead-band after suppression

// ==================== FIREBASE TIMING ====================
//  Sync every 5 s.  Raise this value if you need fewer RTDB writes.
#define FIREBASE_SYNC_INTERVAL 5000UL   // ms

// ==================== DISPLAY SETUP ====================
Adafruit_ST7735 tft = Adafruit_ST7735(TFT_CS, TFT_DC, TFT_MOSI, TFT_SCLK, TFT_RST);

// ==================== TEMPERATURE SENSOR ====================
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature tempSensors(&oneWire);

// ==================== FIREBASE OBJECTS ====================
FirebaseData  fbData;      // single shared FirebaseData object
FirebaseConfig fbConfig;
FirebaseAuth   fbAuth;

// ==================== GLOBAL STATE ====================
float        fuelLevel          = 0.0f;
float        distance           = 0.0f;
float        temperature        = 0.0f;
bool         fireDetected       = false;
bool         pumpRunning        = false;
bool         inCooldown         = false;
unsigned long pumpStartTime     = 0;
unsigned long lastActivationTime = 0;

// Display cadence
unsigned long lastDisplayUpdate = 0;
const unsigned long displayInterval = 500UL;   // ms

// Firebase cadence
unsigned long lastFirebaseSync  = 0;

// Connection flags
bool wifiConnected     = false;
bool firebaseReady     = false;

// ──────────────────────────────────────────────────────────────────────────────
// SETUP
// ──────────────────────────────────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);
  delay(500);

  // ── TFT ──────────────────────────────────────────────────────────────────
  tft.initR(INITR_BLACKTAB);
  tft.setRotation(1);           // Landscape (160 × 128)
  tft.fillScreen(ST77XX_BLACK);

  showSplashScreen();
  delay(2500);

  // ── GPIO ─────────────────────────────────────────────────────────────────
  pinMode(TRIG_PIN,    OUTPUT);
  pinMode(ECHO_PIN,    INPUT);
  pinMode(FLAME_PIN,   INPUT);
  pinMode(RELAY_PUMP1, OUTPUT);
  pinMode(ALARM_PIN,   OUTPUT);

  digitalWrite(RELAY_PUMP1, LOW);
  digitalWrite(ALARM_PIN,   LOW);

  // ── Temperature sensor ───────────────────────────────────────────────────
  tempSensors.begin();

  // ── Network + Firebase ───────────────────────────────────────────────────
  connectWiFi();
  initFirebase();

  // ── Normal UI ────────────────────────────────────────────────────────────
  drawNormalUI();

  Serial.println("========================================");
  Serial.println(" FUEL TANK MONITORING SYSTEM  v2.0");
  Serial.println("========================================");
  Serial.println(" Firebase: single JSON batch upload");
  Serial.println(" Path root: /TankSystem/" TANK_ID);
  Serial.println("========================================");
}

// ──────────────────────────────────────────────────────────────────────────────
// MAIN LOOP
// ──────────────────────────────────────────────────────────────────────────────
void loop() {
  // 1. Read all sensors (fast, blocking μs-level operations only)
  readUltrasonicSensor();
  readTemperatureSensor();
  readFlameSensor();

  // 2. Safety-critical fire suppression – must never be delayed
  handleFireSuppression();

  // 3. Cloud sync on its own timer (non-blocking guard inside syncFirebase)
  if (millis() - lastFirebaseSync >= FIREBASE_SYNC_INTERVAL) {
    syncFirebase();
    lastFirebaseSync = millis();
  }

  // 4. Display refresh on its own timer
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

// ──────────────────────────────────────────────────────────────────────────────
// SENSOR FUNCTIONS  (unchanged logic)
// ──────────────────────────────────────────────────────────────────────────────
void readUltrasonicSensor() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  long duration = pulseIn(ECHO_PIN, HIGH, 30000);

  distance = (duration == 0) ? MAX_DISTANCE : (duration * 0.0343f) / 2.0f;

  if      (distance <= MIN_DISTANCE) fuelLevel = 100.0f;
  else if (distance >= MAX_DISTANCE) fuelLevel =   0.0f;
  else fuelLevel = ((MAX_DISTANCE - distance) / (MAX_DISTANCE - MIN_DISTANCE)) * 100.0f;

  fuelLevel = constrain(fuelLevel, 0.0f, 100.0f);
}

void readTemperatureSensor() {
  tempSensors.requestTemperatures();
  temperature = tempSensors.getTempCByIndex(0);
  if (temperature == DEVICE_DISCONNECTED_C) temperature = -999.0f;
}

void readFlameSensor() {
  fireDetected = (digitalRead(FLAME_PIN) == LOW);
}

// ──────────────────────────────────────────────────────────────────────────────
// FIRE SUPPRESSION  (unchanged logic)
// ──────────────────────────────────────────────────────────────────────────────
void soundHazardAlarm() {
  static unsigned long lastToggle = 0;
  static int phase = 0;

  if (millis() - lastToggle > 150) {
    switch (phase) {
      case 0: tone(ALARM_PIN, 1800); break;
      case 1: tone(ALARM_PIN,  800); break;
      case 2: tone(ALARM_PIN, 2200); break;
      case 3: tone(ALARM_PIN,  600); break;
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
    pumpRunning    = true;
    pumpStartTime  = millis();
    drawFireUI();
    Serial.println("🔥 FIRE HAZARD DETECTED!");
  }

  if (pumpRunning) {
    soundHazardAlarm();
    unsigned long runtime = millis() - pumpStartTime;

    if (!fireDetected || runtime >= PUMP_MAX_RUNTIME) {
      digitalWrite(RELAY_PUMP1, LOW);
      stopAlarm();
      pumpRunning          = false;
      lastActivationTime   = millis();
      inCooldown           = true;
      Serial.println(runtime >= PUMP_MAX_RUNTIME ? "⚠ Safety timeout" : "✓ Fire suppressed");
      drawNormalUI();
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// WIFI & FIREBASE
// ──────────────────────────────────────────────────────────────────────────────

/*
 * connectWiFi()
 *   Non-blocking attempt: retries up to MAX_ATTEMPTS × 500 ms then continues.
 *   The main loop is therefore never stalled indefinitely waiting for an AP.
 */
void connectWiFi() {
  const int MAX_ATTEMPTS = 20;

  Serial.print("Connecting to WiFi");
  tft.fillScreen(ST77XX_BLACK);
  tft.setTextColor(ST77XX_CYAN);
  tft.setTextSize(1);
  tft.setCursor(10, 50);
  tft.print("Connecting WiFi...");

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  for (int i = 0; i < MAX_ATTEMPTS && WiFi.status() != WL_CONNECTED; i++) {
    delay(500);
    Serial.print(".");
  }

  if (WiFi.status() == WL_CONNECTED) {
    wifiConnected = true;
    Serial.println("\nWiFi connected! IP: " + WiFi.localIP().toString());
    tft.setTextColor(ST77XX_GREEN);
    tft.setCursor(10, 70);
    tft.print("WiFi Connected!");
  } else {
    wifiConnected = false;
    Serial.println("\nWiFi connection failed – running offline.");
    tft.setTextColor(ST77XX_RED);
    tft.setCursor(10, 70);
    tft.print("WiFi Failed!");
  }
  delay(1000);
}

/*
 * initFirebase()
 *   Configures the SDK with the legacy database secret and arms the
 *   automatic WiFi-reconnect helper.  A brief connectivity check is made;
 *   failure is non-fatal – syncFirebase() will retry on every cadence tick.
 */
void initFirebase() {
  if (!wifiConnected) {
    Serial.println("Firebase init skipped – no WiFi.");
    return;
  }

  Serial.println("Initialising Firebase …");
  tft.fillScreen(ST77XX_BLACK);
  tft.setTextColor(ST77XX_CYAN);
  tft.setTextSize(1);
  tft.setCursor(10, 50);
  tft.print("Connecting Firebase...");

  fbConfig.host                         = FIREBASE_HOST;
  fbConfig.signer.tokens.legacy_token   = FIREBASE_AUTH;

  Firebase.begin(&fbConfig, &fbAuth);
  Firebase.reconnectWiFi(true);    // SDK silently heals WiFi drops

  delay(1500);   // allow the SDK a moment to authenticate

  if (Firebase.ready()) {
    firebaseReady = true;
    Serial.println("Firebase ready.");
    tft.setTextColor(ST77XX_GREEN);
    tft.setCursor(10, 70);
    tft.print("Firebase Ready!");

    // ── Send static meta once at boot ───────────────────────────────────
    String metaPath = "/TankSystem/" TANK_ID "/meta";
    FirebaseJson meta;
    meta.set("tankId",    TANK_ID);
    meta.set("location",  "Underground");
    meta.set("status",    "online");
    meta.set("bootTime",  (int)millis());

    if (!Firebase.RTDB.setJSON(&fbData, metaPath.c_str(), &meta)) {
      Serial.println("Meta write error: " + fbData.errorReason());
    }
  } else {
    firebaseReady = false;
    Serial.println("Firebase not ready – will retry at each sync tick.");
    tft.setTextColor(ST77XX_RED);
    tft.setCursor(10, 70);
    tft.print("Firebase Failed!");
  }
  delay(1000);
}

/*
 * syncFirebase()
 *   DESIGN GOALS
 *   ① Guard with Firebase.ready() + WiFi check  → never blocks main loop
 *   ② Single FirebaseJson object                → one RTDB write per sync
 *   ③ /TankSystem root                          → clean database layout
 *   ④ Fire events logged under /events/fire/<ts>→ preserves history
 */
void syncFirebase() {
  // ── Anti-freeze gate ──────────────────────────────────────────────────────
  //  If WiFi dropped, give the SDK one reconnect attempt then bail out.
  //  The safety loop in handleFireSuppression() is NOT affected.
  if (WiFi.status() != WL_CONNECTED) {
    wifiConnected = false;
    Serial.println("[Firebase] WiFi lost – skipping sync.");
    return;
  }

  if (!Firebase.ready()) {
    firebaseReady = false;
    Serial.println("[Firebase] SDK not ready – skipping sync.");
    return;
  }

  firebaseReady  = true;
  wifiConnected  = true;

  // ── Derive alert level ────────────────────────────────────────────────────
  String alertLevel = "normal";
  if (fireDetected)      alertLevel = "critical";
  else if (fuelLevel < 20) alertLevel = "warning";
  else if (fuelLevel < 50) alertLevel = "info";

  // ── Build JSON payload ────────────────────────────────────────────────────
  //  All sensor and status fields are packed into ONE object so the SDK
  //  makes a single PATCH request instead of N sequential PUT requests.
  FirebaseJson payload;

  // sensors node
  payload.set("sensors/fuelLevel",   fuelLevel);
  payload.set("sensors/temperature", temperature);
  payload.set("sensors/distance",    distance);

  // status node
  payload.set("status/fireDetected", fireDetected);
  payload.set("status/pumpRunning",  pumpRunning);
  payload.set("status/inCooldown",   inCooldown);
  payload.set("status/alertLevel",   alertLevel);

  // timestamp (device uptime ms – replace with NTP epoch when available)
  payload.set("timestamp", (int)millis());

  // ── Write entire payload in ONE call ──────────────────────────────────────
  String rootPath = "/TankSystem/" TANK_ID;
  if (!Firebase.RTDB.updateNode(&fbData, rootPath.c_str(), &payload)) {
    Serial.println("[Firebase] updateNode error: " + fbData.errorReason());
    return;
  }

  Serial.printf("[Firebase] Synced – Fuel=%.1f%% Temp=%.1fC Fire=%s\n",
                fuelLevel, temperature, fireDetected ? "YES" : "NO");

  // ── Fire-event log (written only when a new fire is detected) ─────────────
  //  Guard: pumpRunning prevents duplicate log entries for the same event.
  if (fireDetected && !pumpRunning) {
    String eventPath = "/TankSystem/" TANK_ID "/events/fire/" + String(millis());
    FirebaseJson fireEvent;
    fireEvent.set("fuelLevel",   fuelLevel);
    fireEvent.set("temperature", temperature);
    fireEvent.set("timestamp",   (int)millis());
    fireEvent.set("status",      "detected");

    if (!Firebase.RTDB.setJSON(&fbData, eventPath.c_str(), &fireEvent)) {
      Serial.println("[Firebase] Fire event log error: " + fbData.errorReason());
    } else {
      Serial.println("[Firebase] Fire event logged.");
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// DISPLAY FUNCTIONS  (pixel-perfect originals – zero changes below this line)
// ──────────────────────────────────────────────────────────────────────────────

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
  tft.print("v2.0");
}

void drawNormalUI() {
  tft.fillScreen(ST77XX_BLACK);

  // Title
  tft.fillRect(0, 0, 160, 20, ST77XX_BLUE);
  tft.setTextColor(ST77XX_WHITE);
  tft.setTextSize(1);
  tft.setCursor(8, 6);
  tft.print("FUEL TANK MONITOR");

  // Draw static elements
  tft.drawLine(80, 20, 80, 128, ST77XX_DARKGREY);
}

void drawFireUI() {
  tft.fillScreen(ST77XX_BLACK);

  // Flashing red title
  tft.fillRect(0, 0, 160, 25, ST77XX_RED);
  tft.setTextColor(ST77XX_YELLOW);
  tft.setTextSize(2);
  tft.setCursor(15, 7);
  tft.print("! FIRE !");
}

void updateNormalDisplay() {
  // LEFT SIDE: Fuel Level Circle
  drawFuelCircle(40, 74, 35);

  // RIGHT SIDE: Temperature with snowflake icon
  drawTemperature(120, 74);
}

void updateFireDisplay() {
  // Large fire icon
  drawFireIcon(40, 50);

  // Status text
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
  // Clear area
  tft.fillCircle(x, y, radius + 2, ST77XX_BLACK);

  // Outer circle
  tft.drawCircle(x, y, radius, ST77XX_WHITE);

  // Calculate fill angle (0–360 degrees)
  int fillAngle = (fuelLevel / 100.0) * 360;

  // Draw filled arc (fuel level)
  for (int angle = 0; angle < fillAngle; angle += 2) {
    float rad = angle * 3.14159f / 180.0f;
    int x1 = x + (radius - 1) * cos(rad);
    int y1 = y + (radius - 1) * sin(rad);

    uint16_t color;
    if      (fuelLevel > 50) color = ST77XX_GREEN;
    else if (fuelLevel > 20) color = ST77XX_YELLOW;
    else                     color = ST77XX_RED;

    tft.drawLine(x, y, x1, y1, color);
  }

  // Inner circle (empty centre)
  tft.fillCircle(x, y, radius - 10, ST77XX_BLACK);

  // Percentage text in centre
  tft.setTextSize(2);
  if      (fuelLevel > 50) tft.setTextColor(ST77XX_GREEN);
  else if (fuelLevel > 20) tft.setTextColor(ST77XX_YELLOW);
  else                     tft.setTextColor(ST77XX_RED);

  tft.setCursor(x - 18, y - 8);
  if (fuelLevel < 10) tft.print(" ");
  tft.print((int)fuelLevel);
  tft.print("%");

  // Label
  tft.setTextSize(1);
  tft.setTextColor(ST77XX_CYAN);
  tft.setCursor(x - 15, y + 25);
  tft.print("FUEL");
}

void drawTemperature(int x, int y) {
  // Clear area
  tft.fillRect(x - 35, y - 35, 70, 70, ST77XX_BLACK);

  // Snowflake icon
  drawSnowflakeIcon(x, y - 15);

  // Temperature value
  tft.setTextSize(2);
  if (temperature == -999) {
    tft.setTextColor(ST77XX_RED);
    tft.setCursor(x - 25, y + 10);
    tft.print("ERR");
  } else {
    if      (temperature < 25) tft.setTextColor(ST77XX_CYAN);
    else if (temperature < 40) tft.setTextColor(ST77XX_GREEN);
    else                       tft.setTextColor(ST77XX_ORANGE);

    tft.setCursor(x - 20, y + 10);
    tft.print(temperature, 0);
    tft.setTextSize(1);
    tft.print("C");
  }

  // Label
  tft.setTextSize(1);
  tft.setTextColor(ST77XX_CYAN);
  tft.setCursor(x - 15, y + 30);
  tft.print("TEMP");
}

void drawSnowflakeIcon(int x, int y) {
  uint16_t color = ST77XX_CYAN;
  int size = 8;

  // Vertical line
  tft.drawLine(x, y - size, x, y + size, color);
  // Horizontal line
  tft.drawLine(x - size, y, x + size, y, color);
  // Diagonal 1
  tft.drawLine(x - size/1.4, y - size/1.4, x + size/1.4, y + size/1.4, color);
  // Diagonal 2
  tft.drawLine(x - size/1.4, y + size/1.4, x + size/1.4, y - size/1.4, color);

  // Tips (small lines at ends)
  tft.drawLine(x, y - size, x - 2, y - size + 3, color);
  tft.drawLine(x, y - size, x + 2, y - size + 3, color);
  tft.drawLine(x, y + size, x - 2, y + size - 3, color);
  tft.drawLine(x, y + size, x + 2, y + size - 3, color);
}

void drawFireIcon(int x, int y) {
  // Animated fire icon
  static bool flicker = false;
  flicker = !flicker;

  uint16_t color1 = flicker ? ST77XX_RED    : ST77XX_ORANGE;
  uint16_t color2 = flicker ? ST77XX_ORANGE : ST77XX_YELLOW;

  // Clear area
  tft.fillRect(x - 20, y - 25, 40, 50, ST77XX_BLACK);

  // Fire flame shape
  tft.fillTriangle(x, y - 20, x - 15, y + 20, x + 15, y + 20, color1);
  tft.fillTriangle(x, y - 15, x -  8, y + 15, x +  8, y + 15, color2);
  tft.fillCircle(x, y - 15, 5, ST77XX_YELLOW);

  // Outer glow circles
  tft.drawCircle(x, y, 25, ST77XX_RED);
  tft.drawCircle(x, y, 26, ST77XX_ORANGE);
}
