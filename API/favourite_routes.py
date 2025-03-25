from flask import Blueprint, request, jsonify
from extensions import mysql  # Import mysql from extensions

favourite_routes = Blueprint('favourite_routes', __name__)

@favourite_routes.route('/favorites', methods=['GET'])
def get_favorites():
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({"message": "User ID is required"}), 400

    conn = mysql.connection
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT gym_id FROM favourite WHERE user_id = %s", (user_id,))
        favorites = [row[0] for row in cursor.fetchall()]
        return jsonify(favorites)
    except Exception as e:
        print(f"Error fetching favorites: {e}")
        return jsonify({"message": "Failed to fetch favorites"}), 500
    finally:
        cursor.close()

@favourite_routes.route('/favorites', methods=['POST'])
def add_or_remove_favorite():
    data = request.json
    user_id = data.get('user_id')
    gym_id = data.get('gym_id')
    action = data.get('action')  # 'add' or 'remove'

    if not user_id or not gym_id or action not in ['add', 'remove']:
        print(f"Invalid input: {data}")  # Debug log
        return jsonify({"message": "Invalid input"}), 400

    print(f"Received payload: {data}")  # Debug log

    conn = mysql.connection
    cursor = conn.cursor()
    try:
        if action == 'add':
            # Check if the favorite already exists
            cursor.execute("SELECT id FROM favourite WHERE user_id = %s AND gym_id = %s", (user_id, gym_id))
            if cursor.fetchone():
                print(f"Gym {gym_id} is already in favorites for user {user_id}")  # Debug log
                return jsonify({"message": "Gym is already in favorites"}), 400

            cursor.execute("INSERT INTO favourite (user_id, gym_id) VALUES (%s, %s)", (user_id, gym_id))
            conn.commit()
            return jsonify({"message": "Gym added to favorites"}), 201
        elif action == 'remove':
            cursor.execute("DELETE FROM favourite WHERE user_id = %s AND gym_id = %s", (user_id, gym_id))
            conn.commit()
            return jsonify({"message": "Gym removed from favorites"}), 200
    except Exception as e:
        print(f"Error updating favorites: {e}")  # Debug log
        return jsonify({"message": "Failed to update favorites"}), 500
    finally:
        cursor.close()
