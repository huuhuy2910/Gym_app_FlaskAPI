from flask import Blueprint, request, jsonify
from extensions import mysql  # Import mysql from extensions
import MySQLdb  # Import MySQLdb for error handling

review_routes = Blueprint('review_routes', __name__)

@review_routes.route('/reviews', methods=['POST'])
def add_review():
    data = request.json
    print(f"Received review data: {data}")  # Log incoming data
    user_id = data.get('user_id')  # Accept user_id from the request body
    gym_id, rating, comment = data.get('gym_id'), data.get('rating'), data.get('comment')

    if not user_id or not gym_id or not rating or not comment:
        return jsonify({"message": "All fields are required!"}), 422

    try:
        conn = mysql.connection  # Use the connection from extensions
        with conn.cursor() as cursor:  # Use context manager for cursor
            cursor.execute(
                "INSERT INTO reviews (user_id, gym_id, rating, comment) VALUES (%s, %s, %s, %s)",
                (user_id, gym_id, rating, comment),
            )
            conn.commit()
        return jsonify({"message": "Đã đánh giá phòng gym thành công!"}), 201
    except MySQLdb.OperationalError as e:
        print(f"MySQL OperationalError: {e}")
        return jsonify({"message": "Database connection error!"}), 500
    except Exception as e:
        print(f"Error adding review: {e}")
        return jsonify({"message": "Đã xảy ra lỗi khi thêm đánh giá!"}), 500

@review_routes.route('/reviews/<int:gym_id>', methods=['GET'])
def get_reviews(gym_id):
    try:
        conn = mysql.connection  # Use the connection from extensions
        with conn.cursor() as cursor:  # Use context manager for cursor
            cursor.execute(
                "SELECT r.id, r.rating, r.comment, u.username, r.created_at FROM reviews r JOIN users u ON r.user_id = u.id WHERE r.gym_id = %s",
                (gym_id,),
            )
            reviews = cursor.fetchall()

        review_list = [
            {
                "id": review[0],  # Include comment ID
                "rating": review[1],
                "comment": review[2],
                "user": review[3],
                "created_at": review[4].strftime('%Y-%m-%d %H:%M:%S'),
            }
            for review in reviews
        ]
        return jsonify(review_list)
    except MySQLdb.OperationalError as e:
        print(f"MySQL OperationalError: {e}")
        return jsonify({"message": "Database connection error!"}), 500
    except Exception as e:
        print(f"Error fetching reviews: {e}")
        return jsonify({"message": "Đã xảy ra lỗi khi lấy danh sách đánh giá!"}), 500

@review_routes.route('/reviews/<int:comment_id>', methods=['DELETE'])
def delete_review(comment_id):
    try:
        conn = mysql.connection
        with conn.cursor() as cursor:
            cursor.execute("DELETE FROM reviews WHERE id = %s", (comment_id,))
            conn.commit()
        return jsonify({"message": "Đã xóa bình luận thành công!"}), 200
    except MySQLdb.OperationalError as e:
        print(f"MySQL OperationalError: {e}")
        return jsonify({"message": "Database connection error!"}), 500
    except Exception as e:
        print(f"Error deleting review: {e}")
        return jsonify({"message": "Đã xảy ra lỗi khi xóa đánh giá!"}), 500

