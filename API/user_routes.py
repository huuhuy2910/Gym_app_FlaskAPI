from flask import Blueprint, request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
from extensions import mysql  # Import mysql from extensions
from flask_cors import CORS

user_routes = Blueprint('user_routes', __name__)

# Enable CORS for the Blueprint
CORS(user_routes)

# 1️⃣ Đăng ký tài khoản
@user_routes.route('/register', methods=['POST'])
def register():
    data = request.json
    username = data.get('username')
    email = data.get('email')
    password = data.get('password')
    phone = data.get('phone', '')  # Optional field
    address = data.get('address', '')  # Optional field

    if not username or not email or not password:
        return jsonify({"message": "Username, email, and password are required!"}), 422

    hashed_password = generate_password_hash(password)  # Hash the password

    conn = mysql.connection
    cursor = conn.cursor()
    try:
        # Check if username or email already exists
        cursor.execute("SELECT id FROM users WHERE username = %s OR email = %s", (username, email))
        existing_user = cursor.fetchone()
        if existing_user:
            return jsonify({"message": "Tên đăng nhập hoặc email đã tồn tại!"}), 400

        # Insert new user with hashed password, phone, and address
        cursor.execute(
            "INSERT INTO users (username, email, password_hash, phone, address) VALUES (%s, %s, %s, %s, %s)",
            (username, email, hashed_password, phone, address)
        )
        conn.commit()
        return jsonify({"message": "Đăng ký thành công!"}), 201
    except Exception as e:
        print(f"Error during registration: {e}")
        return jsonify({"message": "Đã xảy ra lỗi trong quá trình đăng ký!"}), 500
    finally:
        cursor.close()

# 2️⃣ Đăng nhập
@user_routes.route('/login', methods=['POST'])
def login():
    data = request.json
    username, password = data['username'], data['password']

    conn = mysql.connection
    cursor = conn.cursor()
    cursor.execute("SELECT id, username, email, password_hash FROM users WHERE username = %s", (username,))
    user = cursor.fetchone()

    if user:
        print(f"User found: {user}")  # Debug: Log user details
        if check_password_hash(user[3], password):  # Compare hashed password
            return jsonify({
                "message": "Đăng nhập thành công!",
                "id": user[0],  # Include user_id in the response
                "username": user[1],
                "email": user[2]
            })
        else:
            print("Password mismatch")  # Debug: Log password mismatch
            return jsonify({"message": "Sai tên đăng nhập hoặc mật khẩu!"}), 401
    else:
        print("User not found")  # Debug: Log user not found
        return jsonify({"message": "Sai tên đăng nhập hoặc mật khẩu!"}), 401

# 3️⃣ Lấy thông tin cá nhân
@user_routes.route('/profile', methods=['GET'])
def get_profile():
    user_id = request.args.get('user_id')  # Pass user_id as a query parameter

    conn = mysql.connection
    cursor = conn.cursor()
    cursor.execute("SELECT username, email, phone, address FROM users WHERE id = %s", (user_id,))
    user = cursor.fetchone()
    cursor.close()

    if user:
        return jsonify({
            "username": user[0],
            "email": user[1],
            "phone": user[2] if user[2] else "No phone provided",
            "address": user[3] if user[3] else "No address provided",
        })
    return jsonify({"message": "Người dùng không tồn tại!"}), 404

# 4️⃣ Đăng xuất
@user_routes.route('/logout', methods=['POST'])
def logout():
    return jsonify({"message": "Đăng xuất thành công!"})

# 5️⃣ Thêm phòng gym vào danh sách yêu thích
@user_routes.route('/favourite', methods=['POST'])
def add_to_favourite():
    user_id = request.json.get('user_id')
    gym_id = request.json.get('gym_id')

    if not user_id or not gym_id:
        return jsonify({"message": "User ID and Gym ID are required!"}), 422

    conn = mysql.connection
    cursor = conn.cursor()
    try:
        cursor.execute(
            "INSERT INTO favourite (user_id, gym_id) VALUES (%s, %s)",
            (user_id, gym_id)
        )
        conn.commit()
        return jsonify({"message": "Phòng gym đã được thêm vào danh sách yêu thích!"}), 201
    except Exception as e:
        print(f"Error adding to favourite: {e}")
        return jsonify({"message": "Đã xảy ra lỗi khi thêm vào danh sách yêu thích!"}), 500
    finally:
        cursor.close()

# 6️⃣ Lấy danh sách yêu thích
@user_routes.route('/favourite', methods=['GET'])
def get_favourite():
    user_id = request.args.get('user_id')

    if not user_id:
        return jsonify({"message": "User ID is required!"}), 422

    conn = mysql.connection
    cursor = conn.cursor()
    cursor.execute(
        "SELECT gym_id FROM favourite WHERE user_id = %s", (user_id,)
    )
    favourite = cursor.fetchall()
    cursor.close()

    return jsonify([fav[0] for fav in favourite])  # Return list of gym IDs

# 7️⃣ Xóa phòng gym khỏi danh sách yêu thích
@user_routes.route('/favourite', methods=['DELETE'])
def remove_from_favourite():
    user_id = request.json.get('user_id')
    gym_id = request.json.get('gym_id')

    if not user_id or not gym_id:
        return jsonify({"message": "User ID and Gym ID are required!"}), 422

    conn = mysql.connection
    cursor = conn.cursor()
    try:
        cursor.execute(
            "DELETE FROM favourite WHERE user_id = %s AND gym_id = %s",
            (user_id, gym_id)
        )
        conn.commit()
        return jsonify({"message": "Phòng gym đã được xóa khỏi danh sách yêu thích!"})
    except Exception as e:
        print(f"Error removing from favourite: {e}")
        return jsonify({"message": "Đã xảy ra lỗi khi xóa khỏi danh sách yêu thích!"}), 500
    finally:
        cursor.close()

# 8️⃣ Cập nhật thông tin cá nhân
@user_routes.route('/profile', methods=['PUT'])
def update_profile():
    user_id = request.json.get('user_id')  # Pass user_id in the request body
    data = request.json

    # Validate required fields
    username = data.get('username')
    email = data.get('email')
    if not username or not email:
        return jsonify({"message": "Username and email are required!"}), 422

    # Optional fields
    phone = data.get('phone', None)
    address = data.get('address', None)

    conn = mysql.connection
    cursor = conn.cursor()
    try:
        # Check if the user exists
        cursor.execute("SELECT id FROM users WHERE id = %s", (user_id,))
        existing_user = cursor.fetchone()
        if not existing_user:
            print(f"User with ID {user_id} not found")  # Debug log
            return jsonify({"message": "User not found!"}), 404

        # Update user information in the database
        cursor.execute(
            """
            UPDATE users
            SET username = %s, email = %s, phone = %s, address = %s
            WHERE id = %s
            """,
            (username, email, phone, address, user_id)
        )
        conn.commit()

        # Verify that the update was successful
        cursor.execute("SELECT username, email, phone, address FROM users WHERE id = %s", (user_id,))
        updated_user = cursor.fetchone()
        if updated_user:
            print(f"User updated successfully: {updated_user}")  # Debug log
            return jsonify({
                "username": updated_user[0],
                "email": updated_user[1],
                "phone": updated_user[2],
                "address": updated_user[3],
            })
        else:
            print(f"User not found after update for ID {user_id}")  # Debug log
            return jsonify({"message": "User not found after update!"}), 404
    except Exception as e:
        print(f"Error updating profile: {e}")  # Debug log
        return jsonify({"message": "An error occurred while updating the profile!"}), 500
    finally:
        cursor.close()

# 9️⃣ Thay đổi mật khẩu
@user_routes.route('/change_password', methods=['PUT'])
def change_password():
    data = request.json
    user_id = data.get('user_id')
    current_password = data.get('current_password')
    new_password = data.get('new_password')
    confirm_password = data.get('confirm_password')

    if not user_id or not current_password or not new_password or not confirm_password:
        return jsonify({"message": "All fields are required!"}), 422

    if new_password != confirm_password:
        return jsonify({"message": "New password and confirmation do not match!"}), 400

    conn = mysql.connection
    cursor = conn.cursor()
    try:
        # Verify current password
        cursor.execute("SELECT password_hash FROM users WHERE id = %s", (user_id,))
        user = cursor.fetchone()
        if not user or not check_password_hash(user[0], current_password):
            return jsonify({"message": "Current password is incorrect!"}), 401

        # Update to the new password
        hashed_password = generate_password_hash(new_password)
        cursor.execute(
            "UPDATE users SET password_hash = %s WHERE id = %s",
            (hashed_password, user_id)
        )
        conn.commit()
        return jsonify({"message": "Password changed successfully!"}), 200
    except Exception as e:
        print(f"Error changing password: {e}")
        return jsonify({"message": "An error occurred while changing the password!"}), 500
    finally:
        cursor.close()