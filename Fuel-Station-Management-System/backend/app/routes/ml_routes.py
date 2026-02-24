from flask import Blueprint, render_template, request, jsonify
from ..ml_service import predict_days_until_empty, TANK_INFO

ml_bp = Blueprint("ml", __name__, url_prefix="/ml")


@ml_bp.route("/")
def ml_home():
    return render_template("tankPrediction.html", tanks=TANK_INFO)


@ml_bp.route("/predict", methods=["POST"])
def predict():

    try:
        data = request.get_json(force=True)

        tank_id = data.get("tank_id")
        fuel_level_raw = data.get("fuel_level")

        if fuel_level_raw is None or fuel_level_raw == "":
            raise ValueError("Fuel level missing")

        fuel_level = float(fuel_level_raw)

        result = predict_days_until_empty(tank_id, fuel_level)

        return jsonify(result)

    except ValueError as e:
        return jsonify({"success": False, "error": str(e)}), 400

    except Exception as e:
        return jsonify({"success": False, "error": f"Prediction error: {str(e)}"}), 500


@ml_bp.route("/health")
def health():
    return jsonify({
        "status": "healthy",
        "tanks_available": list(TANK_INFO.keys()),
    })