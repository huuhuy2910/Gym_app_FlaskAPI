from flask import Blueprint, request, jsonify
from extensions import mysql  # Import mysql from extensions

gym_routes = Blueprint('gym_routes', __name__)

@gym_routes.route('/gyms', methods=['GET'])
def get_gyms():
    try:
        conn = mysql.connection
        cursor = conn.cursor()
        cursor.execute("""
            SELECT g.id, g.name, g.address, g.image_url, 
                   COALESCE(g.price_per_day, 0) AS price_per_day, 
                   COALESCE(g.price_per_week, 0) AS price_per_week, 
                   COALESCE(g.price_per_month, 0) AS price_per_month, 
                   COALESCE(AVG(r.rating), 0) AS avg_rating,
                   COUNT(r.id) AS total_reviews  -- Add total reviews
            FROM gyms g
            LEFT JOIN reviews r ON g.id = r.gym_id
            GROUP BY g.id
        """)
        gyms = cursor.fetchall()
        cursor.close()

        return jsonify([{
            "id": g[0],
            "name": g[1],
            "address": g[2],
            "image_url": g[3],
            "price_range": f"{float(g[4])}₫ / ngày - {float(g[6])}₫ / tháng",  # Updated price range
            "rating": float(g[7]),  # Ensure numeric value
            "total_reviews": g[8]  # Include total reviews
        } for g in gyms])
    except Exception as e:
        print(f"Error fetching gyms: {e}")
        return jsonify({"message": "Failed to fetch gyms"}), 500

@gym_routes.route('/gyms/search', methods=['GET'])
def search_gyms():
    keyword = request.args.get('q', '')

    conn = mysql.connection
    cursor = conn.cursor()
    cursor.execute("""
        SELECT g.id, g.name, g.address, g.image_url, 
               COALESCE(g.price_per_day, 0) AS price_per_day, 
               COALESCE(g.price_per_week, 0) AS price_per_week, 
               COALESCE(g.price_per_month, 0) AS price_per_month, 
               COALESCE(AVG(r.rating), 0) AS avg_rating,
               COUNT(r.id) AS total_reviews
        FROM gyms g
        LEFT JOIN reviews r ON g.id = r.gym_id
        WHERE g.name LIKE %s
        GROUP BY g.id
    """, ('%' + keyword + '%',))
    gyms = cursor.fetchall()
    cursor.close()

    return jsonify([{
        "id": g[0],
        "name": g[1],
        "address": g[2],
        "image_url": g[3],
        "price_range": f"{float(g[4])}₫ / ngày - {float(g[6])}₫ / tháng",
        "rating": float(g[7]),
        "total_reviews": g[8]
    } for g in gyms])

@gym_routes.route('/gyms/filter', methods=['GET'])
def filter_gyms():
    min_rating = request.args.get('min_rating', 0, type=float)  # Lọc theo đánh giá tối thiểu
    location = request.args.get('location', '')  # Lọc theo địa điểm
    min_price = request.args.get('min_price', 0, type=float)  # Giá tối thiểu
    max_price = request.args.get('max_price', None, type=float)  # Giá tối đa (nếu có)

    conn = mysql.connection
    cursor = conn.cursor()

    # Truy vấn SQL động dựa trên các tiêu chí lọc
    query = """
        SELECT g.id, g.name, g.address, g.image_url, g.price, 
               COALESCE(AVG(r.rating), 0) AS avg_rating
        FROM gyms g
        LEFT JOIN reviews r ON g.id = r.gym_id
    """
    conditions = []
    params = []

    # Lọc theo địa điểm
    if location:
        conditions.append("g.address LIKE %s")
        params.append(f"%{location}%")

    # Lọc theo giá tiền
    if min_price:
        conditions.append("g.price >= %s")
        params.append(min_price)
    if max_price is not None:
        conditions.append("g.price <= %s")
        params.append(max_price)

    query += " GROUP BY g.id"

    # Lọc theo tổng đánh giá (HAVING chỉ dùng được sau GROUP BY)
    if min_rating > 0:
        conditions.append("AVG(r.rating) >= %s")
        params.append(min_rating)

    # Nếu có điều kiện lọc, thêm vào SQL
    if conditions:
        query += " HAVING " + " AND ".join(conditions)

    cursor.execute(query, params)
    gyms = cursor.fetchall()
    cursor.close()

    return jsonify([{
        "id": g[0], "name": g[1], "address": g[2], "image_url": g[3], "price": g[4], "rating": g[5]
    } for g in gyms])

@gym_routes.route('/gyms/<int:gym_id>', methods=['GET'])
def get_gym_details(gym_id):
    try:
        conn = mysql.connection
        cursor = conn.cursor()
        
        # Fetch gym details
        cursor.execute("""
            SELECT g.id, g.name, g.address, g.description, g.image_url, 
                   COALESCE(g.price_per_day, 0) AS price_per_day, 
                   COALESCE(g.price_per_week, 0) AS price_per_week, 
                   COALESCE(g.price_per_month, 0) AS price_per_month, 
                   COALESCE(AVG(r.rating), 0) AS avg_rating,
                   COUNT(r.id) AS total_reviews  -- Add total reviews
            FROM gyms g
            LEFT JOIN reviews r ON g.id = r.gym_id
            WHERE g.id = %s
            GROUP BY g.id
        """, (gym_id,))
        gym = cursor.fetchone()
        
        if not gym:
            cursor.close()
            return jsonify({"message": "Phòng gym không tồn tại!"}), 404
        
        # Fetch gallery images
        cursor.execute("SELECT image_url FROM gallery WHERE gym_id = %s", (gym_id,))
        gallery_images = [img[0] for img in cursor.fetchall()]
        cursor.close()
        
        return jsonify({
            "id": gym[0],
            "name": gym[1],
            "address": gym[2],
            "description": gym[3],
            "image_url": gym[4],
            "price_per_day": float(gym[5] or 0),
            "price_per_week": float(gym[6] or 0),
            "price_per_month": float(gym[7] or 0),
            "price_range": f"{float(gym[5] or 0)}₫ / ngày - {float(gym[7] or 0)}₫ / tháng",
            "rating": float(gym[8] or 0),  # Include average rating
            "total_reviews": gym[9],  # Include total reviews
            "gallery": gallery_images  # Include gallery images
        })
    except Exception as e:
        print(f"Error fetching gym details: {e}")
        return jsonify({"message": "Failed to fetch gym details"}), 500

@gym_routes.route('/gyms/<int:gym_id>/comments', methods=['GET'])
def get_gym_comments(gym_id):
    try:
        print(f"Fetching comments for gym_id: {gym_id}")
        conn = mysql.connection
        cursor = conn.cursor()
        cursor.execute("""
            SELECT u.username, r.comment, r.rating, r.created_at
            FROM reviews r
            JOIN users u ON r.user_id = u.id
            WHERE r.gym_id = %s
            ORDER BY r.created_at DESC
        """, (gym_id,))
        comments = cursor.fetchall()
        cursor.close()

        if not comments:
            return jsonify({"message": "No comments found"}), 200  # Return message if no comments

        # Ensure the data is properly formatted
        result = [{
            "user": comment[0],
            "content": comment[1],
            "rating": int(comment[2]),  # Ensure rating is an integer
            "created_at": comment[3].strftime('%Y-%m-%d %H:%M:%S')  # Format timestamp
        } for comment in comments]
        print(f"Formatted comments: {result}")  # Debug log
        return jsonify(result)  # Ensure correct JSON response
    except Exception as e:
        print(f"Error fetching gym comments: {e}")
        return jsonify({"message": "Failed to fetch gym comments"}), 500

@gym_routes.route('/gyms/search_and_filter', methods=['GET'])
def search_and_filter_gyms():
    try:
        name = request.args.get('name', '').strip()
        location = request.args.get('location', '').strip()
        min_price = request.args.get('min_price', 0, type=float)
        max_price = request.args.get('max_price', None, type=float)
        price_type = request.args.get('price_type', 'day')  # Default to day

        conn = mysql.connection
        cursor = conn.cursor()

        # Map price type to the corresponding column alias
        price_column = {
            'day': 'price_per_day',
            'week': 'price_per_week',
            'month': 'price_per_month'
        }.get(price_type, 'price_per_day')

        query = f"""
            SELECT g.id, g.name, g.address, g.image_url, 
                   COALESCE(g.price_per_day, 0) AS price_per_day, 
                   COALESCE(g.price_per_week, 0) AS price_per_week, 
                   COALESCE(g.price_per_month, 0) AS price_per_month, 
                   COALESCE(AVG(r.rating), 0) AS avg_rating,
                   COUNT(r.id) AS total_reviews
            FROM gyms g
            LEFT JOIN reviews r ON g.id = r.gym_id
        """
        conditions = []
        params = []

        if name:
            conditions.append("g.name LIKE %s")
            params.append(f"%{name}%")
        if location:
            conditions.append("g.address LIKE %s")
            params.append(f"%{location}%")
        if min_price:
            conditions.append(f"{price_column} >= %s")
            params.append(min_price)
        if max_price is not None:
            conditions.append(f"{price_column} <= %s")
            params.append(max_price)

        query += " GROUP BY g.id"

        if conditions:
            query += " HAVING " + " AND ".join(conditions)

        print(f"Executing query: {query} with params: {params}")  # Debug log
        cursor.execute(query, params)
        gyms = cursor.fetchall()
        cursor.close()

        return jsonify([{
            "id": g[0],
            "name": g[1],
            "address": g[2],
            "image_url": g[3],
            "price_range": f"{float(g[4])}₫ / ngày - {float(g[6])}₫ / tháng",
            "rating": float(g[7]),
            "total_reviews": g[8]
        } for g in gyms])
    except Exception as e:
        print(f"Error in search_and_filter_gyms: {e}")  # Log the error
        return jsonify({"message": f"Failed to fetch gyms with filters: {str(e)}"}), 500