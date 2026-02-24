import pickle
import pandas as pd
from datetime import datetime, timedelta

# ==================================================
# LOAD THE TRAINED MODEL PACKAGE
# ==================================================

MODEL_PATH = "ftms_ml_models.pkl"

with open(MODEL_PATH, "rb") as f:
    model_package = pickle.load(f)

consumption_models = model_package["consumption_models"]
consumption_scalers = model_package["consumption_scalers"]
consumption_metrics = model_package["consumption_metrics"]
tank_capacities = model_package["tank_capacities"]
feature_columns = model_package["feature_columns"]

# ==================================================
# TANK INFORMATION
# ==================================================

TANK_INFO = {
    "1P": {"name": "Tank 1P", "fuel_type": "92 Petrol", "capacity": 14490},
    "2P": {"name": "Tank 2P", "fuel_type": "92 Petrol", "capacity": 9000},
    "3P": {"name": "Tank 3P", "fuel_type": "95 Petrol", "capacity": 9000},
    "1AD": {"name": "Tank 1AD", "fuel_type": "Auto Diesel", "capacity": 25000},
    "1SD": {"name": "Tank 1SD", "fuel_type": "Super Diesel", "capacity": 9000},
}


# ==================================================
# PREDICTION FUNCTION
# ==================================================

def predict_days_until_empty(tank_id, current_fuel_level, prediction_date=None):

    if tank_id not in consumption_models:
        return {"success": False, "error": f"Invalid tank ID: {tank_id}"}

    capacity = tank_capacities[tank_id]

    if current_fuel_level < 0 or current_fuel_level > capacity:
        return {
            "success": False,
            "error": f"Fuel level must be between 0 and {capacity:,}L",
        }

    if prediction_date is None:
        prediction_date = datetime.now()

    features = {
        "Month": prediction_date.month,
        "DayOfWeek": prediction_date.weekday(),
        "IsWeekend": 1 if prediction_date.weekday() >= 5 else 0,
        "Quarter": (prediction_date.month - 1) // 3 + 1,
        "Capacity": capacity,
    }

    X_input = pd.DataFrame([features], columns=feature_columns)

    scaler = consumption_scalers[tank_id]
    X_scaled = scaler.transform(X_input)

    model = consumption_models[tank_id]
    predicted_consumption_rate = float(model.predict(X_scaled)[0])

    days_until_empty = (
        current_fuel_level / predicted_consumption_rate
        if predicted_consumption_rate > 0 else 999.0
    )

    empty_date = prediction_date + timedelta(days=int(days_until_empty))

    if days_until_empty < 2:
        status = "critical"
        status_message = "CRITICAL - Refill immediately!"
    elif days_until_empty < 5:
        status = "warning"
        status_message = "WARNING - Refill soon"
    else:
        status = "good"
        status_message = "Good - Normal operation"

    return {
        "success": True,
        "tank_id": tank_id,
        "tank_name": TANK_INFO[tank_id]["name"],
        "fuel_type": TANK_INFO[tank_id]["fuel_type"],
        "current_level": float(current_fuel_level),
        "capacity": int(capacity),
        "utilization": round((current_fuel_level / capacity) * 100, 1),
        "predicted_daily_consumption": round(predicted_consumption_rate, 2),
        "days_until_empty": round(days_until_empty, 2),
        "estimated_empty_date": empty_date.strftime("%Y-%m-%d"),
        "status": status,
        "status_message": status_message,
        "model_accuracy_mae": round(consumption_metrics[tank_id]["mae"], 2),
    }