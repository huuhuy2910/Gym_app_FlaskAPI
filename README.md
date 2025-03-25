# Gym App Flask API

This project is a Gym Management System built using Flask for the backend and Flutter for the frontend. It allows users to browse gyms, view details, add gyms to their favorites, and leave reviews.

## Features
- User authentication and management.
- Gym details with pricing and gallery.
- Add gyms to favorites.
- Leave reviews and ratings for gyms.
- Responsive Flutter frontend.

---

## Prerequisites
1. **Python**: Ensure Python 3.8+ is installed.
2. **Flutter**: Install Flutter SDK for the frontend.
3. **MySQL**: Install MySQL for the database.

---

## Database Setup
1. Open your MySQL client and execute the following SQL commands to create the database and tables:

```sql
CREATE DATABASE gym_app;
USE gym_app;

-- Bảng users (người dùng)
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(15),
    address VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bảng gyms (phòng tập gym)
CREATE TABLE gyms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL,
    description TEXT,
    image_url VARCHAR(255),
    price_per_day DECIMAL(10,2) DEFAULT NULL,
    price_per_week DECIMAL(10,2) DEFAULT NULL,
    price_per_month DECIMAL(10,2) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bảng favourite (danh sách yêu thích)
CREATE TABLE favourite (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    gym_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE CASCADE
);

-- Bảng reviews (đánh giá)
CREATE TABLE reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    gym_id INT NOT NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE CASCADE
);

-- Bảng gallery (kho ảnh phòng gym)
CREATE TABLE gallery (
    id INT AUTO_INCREMENT PRIMARY KEY,
    gym_id INT NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE CASCADE
);
```

2. Verify the tables:
```sql
SELECT * FROM users;
SELECT * FROM gyms;
SELECT * FROM gallery;
SELECT * FROM favourite;
SELECT * FROM reviews;
```

---

## Backend Setup (Flask API)
1. Navigate to the backend directory:
   ```bash
   cd d:\Gym_app_FlaskAPI\API
   ```

2. Create a virtual environment and activate it:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Run the Flask server:
   ```bash
   flask run
   ```

   The API will be available at `http://127.0.0.1:5000`.

---

## Frontend Setup (Flutter App)
1. Navigate to the Flutter app directory:
   ```bash
   cd d:\Gym_app_FlaskAPI\flutter_gym_app
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

   The app will launch on the connected device or emulator.

---

## API Endpoints
### Users
- **POST** `/api/register`: Register a new user.
- **POST** `/api/login`: Authenticate a user.

### Gyms
- **GET** `/api/gyms`: Fetch all gyms.
- **GET** `/api/gyms/<id>`: Fetch details of a specific gym.

### Favorites
- **POST** `/api/favorites`: Add a gym to favorites.
- **DELETE** `/api/favorites/<id>`: Remove a gym from favorites.

### Reviews
- **POST** `/api/reviews`: Submit a review for a gym.
- **GET** `/api/reviews/<gym_id>`: Fetch reviews for a gym.

---

## Project Structure
```
Gym_app_FlaskAPI/
├── backend/                # Flask API code
├── flutter_gym_app/        # Flutter frontend code
├── database.sql            # SQL script for database setup
├── README.md               # Project documentation
```

---

## Contributing
1. Fork the repository.
2. Create a new branch: `git checkout -b feature-name`.
3. Commit your changes: `git commit -m 'Add feature'`.
4. Push to the branch: `git push origin feature-name`.
5. Open a pull request.

---

## License
This project is licensed under the MIT License.