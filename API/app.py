import os
from flask import Flask, send_from_directory
from flask_cors import CORS
from extensions import mysql  # Import mysql from extensions
from image_routes import image_routes  # Import image_routes

app = Flask(__name__)
CORS(app)

# Cấu hình database
app.config['MYSQL_HOST'] = 'localhost'
app.config['MYSQL_USER'] = 'root'
app.config['MYSQL_PASSWORD'] = '1234'
app.config['MYSQL_DB'] = 'gym_app'

# Định nghĩa thư mục chứa file upload
app.config['UPLOAD_FOLDER'] = os.path.join(os.getcwd(), 'uploads')  # Thư mục 'uploads' trong thư mục hiện tại

mysql.init_app(app)  # Initialize mysql with the app

# Import blueprints
import user_routes
import gym_routes
import favourite_routes
import review_routes

# Register blueprints
app.register_blueprint(user_routes.user_routes)
app.register_blueprint(gym_routes.gym_routes)
app.register_blueprint(favourite_routes.favourite_routes)
app.register_blueprint(review_routes.review_routes)
app.register_blueprint(image_routes)  # Register image_routes

if __name__ == '__main__':
    app.run(debug=True)