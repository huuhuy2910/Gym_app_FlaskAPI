import os
from flask import Blueprint, send_from_directory, current_app

image_routes = Blueprint('image_routes', __name__)

@image_routes.route('/uploads/gyms/<filename>', methods=['GET'])
def get_gym_image(filename):
    return send_from_directory(
        os.path.join(current_app.config['UPLOAD_FOLDER'], 'gyms'),  # Subdirectory 'gyms'
        filename
    )

@image_routes.route('/uploads/gallery/<filename>', methods=['GET'])
def get_gallery_image(filename):
    return send_from_directory(
        os.path.join(current_app.config['UPLOAD_FOLDER'], 'gallery'),
        filename
    )