import re
from flask import Flask, request, jsonify,send_file
from flask_sqlalchemy import SQLAlchemy
from flask_bcrypt import Bcrypt  # Import Bcrypt for password hashing
from sqlalchemy.orm import class_mapper, ColumnProperty
from sqlalchemy.orm.attributes import InstrumentedAttribute
from sqlalchemy import func
from sqlalchemy import text
from sqlalchemy import Integer
import random

import base64
import os
import uuid
from flask_restful import Api
from datetime import datetime ,timedelta
from textblob import TextBlob
# from transformers import pipeline (lazy loaded below)


import pymysql
pymysql.install_as_MySQLdb()

app = Flask(__name__)
from flask_cors import CORS
CORS(app)

app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL', 'mysql+pymysql://root:@localhost:3306/ira')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = 'your_secret_key' 
bcrypt = Bcrypt(app)


db = SQLAlchemy(app)

# Robust Sentiment Analysis with TextBlob fallback
try:
    from transformers import pipeline
    sentiment_pipeline = pipeline("sentiment-analysis")
except Exception as e:
    print(f"Transformers warning: {e}. Using TextBlob fallback for sentiment analysis.")
    def sentiment_pipeline(text):
        polarity = TextBlob(text).sentiment.polarity
        label = 'POSITIVE' if polarity >= 0 else 'NEGATIVE'
        return [{'label': label, 'score': round(abs(polarity), 2)}]

class SignupDetails(db.Model):
    id = db.Column(db.Integer, primary_key=True) 
    Name = db.Column(db.String(100), nullable=False)
    Mobile_No = db.Column(db.String(15), nullable=False, unique=True)
    Email_ID = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(120), nullable=False)
    Age = db.Column(db.Float)
    Height = db.Column(db.Float) 
    Weight = db.Column(db.Float)
    Gender = db.Column(db.String(10))
    Occupation = db.Column(db.String(50))
    ProfileImage = db.Column(db.String(100))
    fcm_token = db.Column(db.String(255), nullable=True)  # New column

class Doctor(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    password = db.Column(db.String(200), nullable=False)
    profile_image = db.Column(db.String(200), nullable=True)
    age = db.Column(db.Integer, nullable=True, default=38)
    gender = db.Column(db.String(20), nullable=True, default='Male')
    experience = db.Column(db.String(50), nullable=True, default='10 Years')
    contact = db.Column(db.String(30), nullable=True, default='+91 98765 43210')
    status = db.Column(db.String(20), nullable=True, default='Active')  # 'Active' or 'Inactive'

class PatientNotification(db.Model):
    __tablename__ = 'patient_notifications'
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(100), nullable=False, index=True)
    title = db.Column(db.String(200), nullable=False)
    message = db.Column(db.Text, nullable=False)
    category = db.Column(db.String(50), default='Therapy')        # Therapy, Clinician, Mindfulness, Milestones
    action_type = db.Column(db.String(50), default='none')       # consult_clinic, start_session, write_diary, view_analytics
    priority = db.Column(db.String(20), default='normal')        # normal, severe, critical
    is_read = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.now)



#-----------------------------------------------doctor login-------------------------------------------




@app.route('/doctor_signup', methods=['POST'])
def doctor_signup():
    try:
        data = request.json
        name = data.get('name')
        email = data.get('email')
        password = data.get('password')
        base64_image = data.get('profile_image', '')

        if not name or not email or not password:
            return jsonify({'error': 'Missing required fields'}), 400

        if Doctor.query.filter_by(email=email).first():
            return jsonify({'error': 'Email already registered'}), 400

        hashed_password = bcrypt.generate_password_hash(password).decode('utf-8')

        # Create folder if not exists
        folder_path = 'doctor_profiles'
        if not os.path.exists(folder_path):
            os.makedirs(folder_path)

        # Save image if base64 data is provided
        image_path = None
        if base64_image:
            try:
                image_filename = f"{email.replace('@', '_').replace('.', '_')}.jpg"
                image_path = os.path.join(folder_path, image_filename)
                
                # Decode and save the image
                with open(image_path, 'wb') as img_file:
                    img_file.write(base64.b64decode(base64_image))

                # Store relative image path in the database
                db_image_path = os.path.abspath(image_path)
            except Exception as e:
                return jsonify({'error': 'Failed to decode and save image', 'details': str(e)}), 500
        else:
            db_image_path = None

        new_doctor = Doctor(name=name, email=email, password=hashed_password, profile_image=db_image_path)
        db.session.add(new_doctor)
        db.session.commit()

        return jsonify({'message': 'Doctor signup successful', 'image_path': db_image_path}), 201

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/doctor_login', methods=['POST'])
def doctor_login():
    try:
        data = request.json
        email = data.get('Email_ID')
        password = data.get('password')

        doctor = Doctor.query.filter_by(email=email).first()
        if not doctor or not bcrypt.check_password_hash(doctor.password, password):
            return jsonify({'error': 'Invalid credentials'}), 401

        return jsonify({'message': 'Login successful', 'name': doctor.name, 'profile_image': doctor.profile_image}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500



@app.route('/get_doctor_details', methods=['GET', 'POST'])
def get_doctor_details():
    try:
        data = request.get_json(silent=True) or {}
        email_id = data.get('Email_ID') or data.get('email') or request.args.get('email')
        doctor_details = None
        if email_id:
            doctor_details = Doctor.query.filter_by(email=email_id).first()
        if not doctor_details:
            doctor_details = Doctor.query.first()

        if doctor_details:
            columns = [prop.key for prop in class_mapper(Doctor).iterate_properties
                       if isinstance(prop, ColumnProperty)]
            doctor_data = {column: getattr(doctor_details, column) for column in columns}
            # Provide sensible defaults if fields are empty
            doctor_data['age'] = doctor_data.get('age') if doctor_data.get('age') is not None else 38
            doctor_data['gender'] = doctor_data.get('gender') or 'Male'
            doctor_data['experience'] = doctor_data.get('experience') or '10 Years'
            doctor_data['contact'] = doctor_data.get('contact') or '+91 98765 43210'
            doctor_data['status'] = doctor_data.get('status') or 'Active'
            return jsonify(doctor_data), 200
        else:
            return jsonify({
                'name': 'Dr. Dinesh',
                'email': email_id or 'doctor@hospital.com',
                'age': 38,
                'gender': 'Male',
                'experience': '10 Years',
                'contact': '+91 98765 43210',
                'status': 'Active',
                'message': 'Default doctor'
            }), 200
    except Exception as e:
        print(f"Error in get_doctor_details endpoint: {str(e)}")
        return jsonify({
            'name': 'Dr. Dinesh',
            'email': email_id or 'doctor@hospital.com',
            'age': 38,
            'gender': 'Male',
            'experience': '10 Years',
            'contact': '+91 98765 43210',
            'status': 'Active',
            'error': str(e)
        }), 200


@app.route('/update_doctor_profile', methods=['POST'])
@app.route('/update_doctor_details', methods=['POST'])
def update_doctor_profile():
    try:
        data = request.get_json(silent=True) or {}
        email = data.get('Email_ID') or data.get('email')
        if not email:
            return jsonify({'error': 'Email is required'}), 400

        doctor = Doctor.query.filter_by(email=email).first()
        if not doctor:
            # Create new doctor profile record if not exists
            doctor = Doctor(
                name=data.get('name') or data.get('Name') or 'Dr. Dinesh',
                email=email,
                password=bcrypt.generate_password_hash('doctor123').decode('utf-8'),
                age=38,
                gender='Male',
                experience='10 Years',
                contact='+91 98765 43210',
                status='Active'
            )
            db.session.add(doctor)

        if 'name' in data and data['name']:
            doctor.name = str(data['name']).strip()
        elif 'Name' in data and data['Name']:
            doctor.name = str(data['Name']).strip()

        if 'age' in data and data['age'] is not None:
            try:
                # Handle "38" or "38 Years"
                age_val = str(data['age']).split()[0]
                doctor.age = int(age_val)
            except (ValueError, TypeError):
                pass

        if 'gender' in data and data['gender']:
            doctor.gender = str(data['gender']).strip()

        if 'experience' in data and data['experience']:
            doctor.experience = str(data['experience']).strip()

        if 'contact' in data and data['contact']:
            doctor.contact = str(data['contact']).strip()

        if 'status' in data and data['status']:
            doctor.status = str(data['status']).strip()

        db.session.commit()

        return jsonify({
            'message': 'Doctor profile updated successfully',
            'doctor': {
                'name': doctor.name,
                'email': doctor.email,
                'age': doctor.age,
                'gender': doctor.gender,
                'experience': doctor.experience,
                'contact': doctor.contact,
                'status': doctor.status
            }
        }), 200

    except Exception as e:
        print(f"Error in update_doctor_profile: {str(e)}")
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

#----------------------------------------------get tokens---------------------------------------------

@app.route('/get_fcm_tokens', methods=['GET'])
def get_fcm_tokens():
    try:
        tokens = SignupDetails.query.with_entities(SignupDetails.fcm_token).all()
        fcm_tokens = [token.fcm_token for token in tokens if token.fcm_token]

        return jsonify({'fcm_tokens': fcm_tokens}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

#----------------------------------------------login activity--------------------------------------------


class Activity(db.Model):
    __tablename__ = 'activity'
    email = db.Column(db.String(50), primary_key=True)
    angerscale = db.Column(db.String(50))
    Day1_Activity_1 = db.Column(db.String(50))
    Day1_Activity_1_s = db.Column(db.Integer)
    Day1_Activity_2 = db.Column(db.String(50))
    Day1_Activity_2_s = db.Column(db.Integer)
    Day2_Activity_1 = db.Column(db.String(50))
    Day2_Activity_1_s = db.Column(db.Integer)
    Day2_Activity_2 = db.Column(db.String(50))
    Day2_Activity_2_s = db.Column(db.Integer)
    Day3_Activity_1 = db.Column(db.String(50))
    Day3_Activity_1_s = db.Column(db.Integer)
    Day3_Activity_2 = db.Column(db.String(50))
    Day3_Activity_2_s = db.Column(db.Integer)
    Day4_Activity_1 = db.Column(db.String(50))
    Day4_Activity_1_s = db.Column(db.Integer)
    Day4_Activity_2 = db.Column(db.String(50))
    Day4_Activity_2_s = db.Column(db.Integer)
    Day5_Activity_1 = db.Column(db.String(50))
    Day5_Activity_1_s = db.Column(db.Integer)
    Day5_Activity_2 = db.Column(db.String(50))
    Day5_Activity_2_s = db.Column(db.Integer)
    Day6_Activity_1 = db.Column(db.String(50))
    Day6_Activity_1_s = db.Column(db.Integer)
    Day6_Activity_2 = db.Column(db.String(50))
    Day6_Activity_2_s = db.Column(db.Integer)
    Day7_Activity_1 = db.Column(db.String(50))
    Day7_Activity_1_s = db.Column(db.Integer)
    Day7_Activity_2 = db.Column(db.String(50))
    Day7_Activity_2_s = db.Column(db.Integer)
    Day8_Activity_1 = db.Column(db.String(50))
    Day8_Activity_1_s = db.Column(db.Integer)
    Day8_Activity_2 = db.Column(db.String(50))
    Day8_Activity_2_s = db.Column(db.Integer)
    Day9_Activity_1 = db.Column(db.String(50))
    Day9_Activity_1_s = db.Column(db.Integer)
    Day9_Activity_2 = db.Column(db.String(50))
    Day9_Activity_2_s = db.Column(db.Integer)
    Day10_Activity_1 = db.Column(db.String(50))
    Day10_Activity_1_s = db.Column(db.Integer)
    Day10_Activity_2 = db.Column(db.String(50))
    Day10_Activity_2_s = db.Column(db.Integer)
    Day11_Activity_1 = db.Column(db.String(50))
    Day11_Activity_1_s = db.Column(db.Integer)
    Day11_Activity_2 = db.Column(db.String(50))
    Day11_Activity_2_s = db.Column(db.Integer)
    Day12_Activity_1 = db.Column(db.String(50))
    Day12_Activity_1_s = db.Column(db.Integer)
    Day12_Activity_2 = db.Column(db.String(50))
    Day12_Activity_2_s = db.Column(db.Integer)
    Day13_Activity_1 = db.Column(db.String(50))
    Day13_Activity_1_s = db.Column(db.Integer)
    Day13_Activity_2 = db.Column(db.String(50))
    Day13_Activity_2_s = db.Column(db.Integer)


class LoginSignoutActivity(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), nullable=False)
    login_time = db.Column(db.TIMESTAMP)
    signout_time = db.Column(db.TIMESTAMP)

@app.route('/log_activity', methods=['POST'])
def log_activity():
    data = request.get_json()

    email = data.get('email')
    activity_type = data.get('type')

    if email is None or activity_type is None:
        return jsonify({'error': 'Email and type are required'}), 400

    user_activity = LoginSignoutActivity.query.filter_by(email=email).first()

    if user_activity is None:
        user_activity = LoginSignoutActivity(email=email)

    if activity_type == 'l':
        user_activity.login_time = datetime.now()
    elif activity_type == 's':
        user_activity.signout_time = datetime.now()
    else:
        return jsonify({'error': 'Invalid activity type'}), 400

    db.session.add(user_activity)
    db.session.commit()

    return jsonify({'success': 'Activity logged successfully'}), 200
#-----------------------------------------------------------------------------------------------------------
class Chat(db.Model):
    _tablename_ = 'chat'
    
    id = db.Column(db.Integer, primary_key=True)
    text = db.Column(db.String(200), nullable=False)

# Route to add a new message
@app.route('/chat', methods=['GET'])
def manage_chat():
    # Check if this is a request to add a message (has message parameter)
    if 'message' in request.args:
        # Get the original message from URL parameter
        original_message = request.args.get('message')
        
        # Create new chat entry with original message
        new_chat = Chat(text=original_message)
        
        # Save to database
        db.session.add(new_chat)
        db.session.commit()
        
        # Return message data
        return jsonify({
            'id': new_chat.id,
            'message': original_message
        }), 201
    
    # If no message parameter, return all messages
    else:
        chats = Chat.query.all()
        result = []
        
        for chat in chats:
            result.append({
                'id': chat.id,
                'message': chat.text
            })
        
        return jsonify(result), 200

# Route to delete a message
@app.route('/chat/<int:id>', methods=['DELETE'])
def delete_message(id):
    chat = Chat.query.get(id)
    
    if not chat:
        return jsonify({'error': 'Message not found'}), 404
    
    db.session.delete(chat)
    db.session.commit()
    
    return jsonify({'message': 'Message deleted successfully'}), 200

# Route to get all messages
@app.route('/chat', methods=['GET'])
def get_all_messages():
    chats = Chat.query.all()
    result = []
    
    for chat in chats:
        result.append({
            'id': chat.id,
            'message': chat.text
        })
    
    return jsonify(result), 200
#----------------------------------------------------------------------------------------------------
@app.route('/get_all_names', methods=['GET'])
def get_all_names():
    try:
        all_names = SignupDetails.query.with_entities(SignupDetails.Name).all()
        names = [name[0] for name in all_names]
        return jsonify({'names': names}), 200
    except Exception as e:
        print(f"Error in get_all_names endpoint: {str(e)}")
        return jsonify({'error': str(e)}), 500

        
@app.route('/get_profile_image', methods=['POST'])
def get_profile_image():
    try:
        data = request.json
        email = data.get('Email_ID')

        if email is None:
            return jsonify({'error': 'Email_ID not provided'}), 400

        user = SignupDetails.query.filter_by(Email_ID=email).first()

        if user is None:
            return jsonify({'error': 'User not found'}), 404

        # Dynamically get the column names
        columns = [prop.key for prop in class_mapper(SignupDetails).iterate_properties if isinstance(prop, ColumnProperty)]

        # Create a dictionary with column names and values
        profile_data = {column: getattr(user, column) for column in columns}

        return jsonify(profile_data), 200

    except Exception as e:
        print(f"Error in get_profile_image endpoint: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/get_all_details', methods=['GET'])
def get_all_details():
    try:
        # Query all details from the SignupDetails table
        all_details = SignupDetails.query.all()

        # Convert details to a list of dictionaries
        details_list = []
        for detail in all_details:
            # Dynamically get the column names
            columns = [prop.key for prop in class_mapper(SignupDetails).iterate_properties
                       if isinstance(prop, ColumnProperty)]
            # Create a dictionary with column names and values
            detail_data = {column: getattr(detail, column) for column in columns}
            details_list.append(detail_data)

        return jsonify({'details': details_list}), 200

    except Exception as e:
        print(f"Error in get_all_details endpoint: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/get_user_details', methods=['GET', 'POST'])
def get_user_details():
    try:
        data = request.get_json(silent=True) or {}
        email_id = data.get('Email_ID') or data.get('email') or request.args.get('email')

        user_details = None
        if email_id:
            user_details = SignupDetails.query.filter_by(Email_ID=email_id).first()

        if user_details:
            columns = [prop.key for prop in class_mapper(SignupDetails).iterate_properties
                       if isinstance(prop, ColumnProperty)]
            user_data = {column: getattr(user_details, column) for column in columns}
            return jsonify(user_data), 200
        else:
            return jsonify({'Name': 'User', 'Email_ID': email_id or '', 'message': 'User not found'}), 200

    except Exception as e:
        print(f"Error in get_user_details endpoint: {str(e)}")
        return jsonify({'Name': 'User', 'error': str(e)}), 200

@app.route('/signup', methods=['POST'])
def signup():
    try:
        data = request.json or {}
        name = data.get('Name', '').strip()
        mobile_no = data.get('Mobile_No', '').strip()
        email = data.get('Email_ID', '').strip().lower()
        password = data.get('Password', '')
        confirm_password = data.get('Confirm_Password', '')

        if not name or not mobile_no or not email or not password:
            return jsonify({'error': 'All fields are required'}), 400

        existing_user = SignupDetails.query.filter(func.lower(SignupDetails.Email_ID) == email).first()
        if existing_user:
            return jsonify({'error': 'Email is already registered. Please sign in instead.'}), 402

        existing_mobile = SignupDetails.query.filter_by(Mobile_No=mobile_no).first()
        if existing_mobile:
            return jsonify({'error': 'Mobile number is already registered.'}), 409

        if password != confirm_password:
            return jsonify({'error': 'Passwords do not match'}), 400

        hashed_password = bcrypt.generate_password_hash(password).decode('utf-8')
        new_signup = SignupDetails(
            Name=name, Mobile_No=mobile_no, Email_ID=email, password_hash=hashed_password)
        db.session.add(new_signup)
        db.session.commit()

        return jsonify({'message': 'Signup successful'}), 200

    except Exception as e:
        db.session.rollback()
        print(f"Error in signup endpoint: {str(e)}")
        return jsonify({'error': str(e)}), 500
    



#----------------------------------------------delete pateints------------------------------------

@app.route('/delete_patient', methods=['DELETE'])
def delete_patient():
    try:
        data = request.json
        email = data.get('Email_ID')

        if not email:
            return jsonify({'error': 'Email is required'}), 400

        patient = SignupDetails.query.filter_by(Email_ID=email).first()

        if not patient:
            return jsonify({'error': 'Patient not found'}), 404

        db.session.delete(patient)
        db.session.commit()

        return jsonify({'message': 'Patient deleted successfully'}), 200

    except Exception as e:
        print(f"Error in delete_patient endpoint: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/login', methods=['POST'])
def login():
    try:
        data = request.json or {}
        email = data.get('Email_ID', '').strip().lower()
        password = data.get('Password', '')

        if not email or not password:
            return jsonify({'message': 'Email and password are required'}), 400

        user = SignupDetails.query.filter(func.lower(SignupDetails.Email_ID) == email).first()

        if not user:
            return jsonify({'message': 'Account not found. Please sign up first.'}), 404

        if bcrypt.check_password_hash(user.password_hash, password):
            db.session.commit()
            return jsonify({'message': 'Login successful'}), 200
        else:
            return jsonify({'message': 'Incorrect password'}), 401

    except Exception as e:
        print(f"Error in login endpoint: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/update_details', methods=['POST'])
def update_details():
    try:
        data = request.json

        email_id = data.get('Email_ID')
        age = data.get('Age')
        height = data.get('Height')
        weight = data.get('Weight')
        gender = data.get('Gender')
        occupation = data.get('Occupation')
        profile_image = data.get('ProfileImage')
        
        

        query = text(
            'UPDATE signup_details '
            'SET Age = :age, Height = :height, Weight = :weight, Gender = :gender, Occupation = :occupation, ProfileImage = :profile_image '
            'WHERE Email_ID = :email_id'
        )
        
        
        args = {
                'email_id': email_id,
                'age': age,
                'height': height,
                'weight': weight,
                'gender': gender,
                'occupation': occupation,
                'profile_image': profile_image,
                }

        with app.app_context():
            db.session.execute(query, args)
            db.session.commit()

        return jsonify({"message": "Details updated successfully"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

    

# @app.route('/upload', methods=["POST"])
# def upload():
#     try:
#         data = request.get_json()
        
#         base64_image = data.get('image', '')

#         if not base64_image:
#             return jsonify({"error": "No image provided"}), 400

#         # Decode base64 image data
#         image_data = base64.b64decode(base64_image)

#         # Generate a unique filename for the image
#         unique_filename = str(uuid.uuid4()) + '.jpg'
        
#         # Save the image to the 'uploadedimages' folder with the unique filename
#         image_path = os.path.join('uploadedimages', unique_filename)
#         with open(image_path, 'wb') as f:
#             f.write(image_data)

#         return jsonify({
#             "message": "Image Uploaded Successfully",
#             "image_path": image_path,
#         })

#     except Exception as e:
#         print(f"Error during upload: {str(e)}")
#         return jsonify({"error": str(e)}), 500

@app.route('/upload', methods=["POST"])
def upload():
    try:
        data = request.get_json()

        base64_image = data.get('image', '')
        email = data['Email_ID']

        if not base64_image:
            return jsonify({"error": "No image provided"}), 400

        # Decode base64 image data
        image_data = base64.b64decode(base64_image)

        # Generate a unique filename for the image
        unique_filename = email + '.jpg'

        # Save the image to the 'uploadedimages' folder with the unique filename


        
        image_path = os.path.join('uploadedimages', unique_filename)
        with open(image_path, 'wb') as f:
            f.write(image_data)

        return jsonify({
            "message": "Image Uploaded Successfully",
            "image_path": image_path,
        })

    except Exception as e:
        print(f"Error during upload: {str(e)}")
        return jsonify({"error": str(e)}), 500



@app.route('/fetch_all_images', methods=["GET"]) 
def fetch_all_images():
    images = []

    
    
    for filename in os.listdir('uploadedimages'):
        if filename.endswith('.jpg'):
            
            with open(os.path.join('uploadedimages', filename), 'rb') as f:
                # Read and base64 encode the image
                base64_image = base64.b64encode(f.read()).decode('utf-8')

                
                images.append({
                    "base64_image": base64_image,
                    "image_filename": filename
                })

    return jsonify(images)

#-----------------------------------------total users count-----------------------------------------------
@app.route('/total_users', methods=['GET'])
def total_users():
    try:
        # Use SQLAlchemy count() method to get the total count
        total_users_count = SignupDetails.query.count()

        return jsonify({'total_users_count': total_users_count}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


#-------------------------------------------------------------------------------------


@app.route('/fetch_image', methods=["GET", "POST"])
def fetch_image():
    try:
        data = request.get_json(silent=True) or {}
        email = data.get('Email_ID') or data.get('email') or request.args.get('email')

        if not email:
            return jsonify({"base64_image": None, "message": "No Email_ID provided"}), 200

        image_filename = f"{email}.jpg"
        image_path = os.path.join('uploadedimages', image_filename)

        if not os.path.exists(image_path):
            sanitized = f"{email.replace('@', '_').replace('.', '_')}.jpg"
            alt_path = os.path.join('uploadedimages', sanitized)
            if os.path.exists(alt_path):
                image_path = alt_path
                image_filename = sanitized

        if os.path.exists(image_path):
            with open(image_path, 'rb') as f:
                base64_image = base64.b64encode(f.read()).decode('utf-8')

            return jsonify({
                "base64_image": base64_image,
                "image_filename": image_filename
            }), 200
        else:
            return jsonify({"base64_image": None, "message": "Image not found"}), 200

    except Exception as e:
        print(f"Error in fetch_image endpoint: {str(e)}")
        return jsonify({"base64_image": None, 'error': str(e)}), 200

@app.route('/check_data_completion', methods=["POST"])
def check_data_completion():
    try:
        data = request.get_json()
        email = data.get('Email_ID')

        if not email:
            return jsonify({"error": "No Email_ID provided"}), 400

        user = SignupDetails.query.filter_by(Email_ID=email).first()

        if user is None:
            return jsonify({"error": "User not found"}), 404

        # Check whether all required data are filled
        if all(getattr(user, field) is not None for field in ['Age', 'Height', 'Weight', 'Gender', 'Occupation', 'ProfileImage']):
            return jsonify({"message": "All data filled"}), 200
        else:
            return jsonify({"error": "Incomplete data"}), 300

    except Exception as e:
        print(f"Error in check_data_completion endpoint: {str(e)}")
        return jsonify({'error': str(e)}), 500



class Thoughts(db.Model):
    __tablename__ = 'thoughts'

    id = db.Column(db.Integer, primary_key=True)
    Email_ID = db.Column(db.String(50), nullable=False)
    thoughts = db.Column(db.String(100), nullable=False)
    received_time = db.Column(db.DateTime, default=datetime.now)
    Output = db.Column(db.String(10), default='null') 



# Route to insert thoughts
@app.route('/insert_thoughts', methods=['POST'])
def insert_thoughts():
    try:
       
        email_id = request.json.get('Email_ID')
        thoughts = request.json.get('thoughts')

        
        if not email_id or not thoughts:
            return jsonify({'error': 'Email_ID and thoughts are required fields'}), 400

       
        result = sentiment_pipeline(thoughts)[0]
        sentiment_label = result['label']
        confidence = result['score']

        
        new_thought = Thoughts(
            Email_ID=email_id,
            thoughts=thoughts,
            received_time=datetime.now(),
            Output=sentiment_label,
            
        )

        
        db.session.add(new_thought)
        db.session.commit()

        return jsonify({'message': 'Thoughts inserted successfully', 'sentiment': sentiment_label, 'confidence': confidence}), 200

    except Exception as e:
        print(f"Error in insert_thoughts endpoint: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/fetch_thoughts', methods=['GET'])
def fetch_thoughts():
    try:
        # Query all thoughts from the Thoughts table
        all_thoughts = Thoughts.query.all()

        # Convert thoughts to a list of dictionaries
        thoughts_list = []
        for thought in all_thoughts:
            thought_data = {
                'Email_ID': thought.Email_ID,
                'thoughts': thought.thoughts,
                'received_time': thought.received_time.strftime("%Y-%m-%d %H:%M:%S"),
                'Output': thought.Output
            }
            thoughts_list.append(thought_data)

        return jsonify( thoughts_list), 200

    except Exception as e:
        print(f"Error in fetch_thoughts endpoint: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/get_details_with_images', methods=['GET'])
def get_details_with_images():
    try:
        # Query all details from the SignupDetails table
        all_details = SignupDetails.query.all()

        # Fetch all images from the /uploadedimages folder
        images = {}
        for filename in os.listdir('uploadedimages'):
            if filename.endswith('.jpg'):
                with open(os.path.join('uploadedimages', filename), 'rb') as f:
                    # Read and base64 encode the image
                    base64_image = base64.b64encode(f.read()).decode('utf-8')
                    images[filename] = base64_image

        # Convert details to a list of dictionaries
        details_list = []
        for detail in all_details:
            # Dynamically get the column names
            columns = [prop.key for prop in class_mapper(SignupDetails).iterate_properties
                       if isinstance(prop, ColumnProperty)]

            # Create a dictionary with column names and values
            detail_data = {column: getattr(detail, column) for column in columns}

            # Assign the corresponding base64 image to the ProfileImage field
            email_id = detail_data.get('Email_ID')
            if email_id and f'{email_id}.jpg' in images:
                detail_data['ProfileImage'] = images[f'{email_id}.jpg']
            else:
                detail_data['ProfileImage'] = ''

            details_list.append(detail_data)

        return jsonify({'details': details_list}), 200

    except Exception as e:
        print(f"Error in get_details_with_images endpoint: {str(e)}")
        return jsonify({'error': str(e)}), 500




@app.route('/get_details_with_image', methods=['GET', 'POST'])
def get_details_with_image():
    try:
        data = request.get_json(silent=True) or {}
        email = data.get('email') or data.get('Email_ID') or request.args.get('email')

        user_details = None
        if email:
            user_details = SignupDetails.query.filter_by(Email_ID=email).first()

        if not user_details:
            return jsonify({
                'user_details': {
                    'Name': 'Patient',
                    'Email_ID': email or '',
                    'Age': 25.0,
                    'Gender': 'Other',
                    'Occupation': 'Patient',
                    'Height': 'N/A',
                    'Weight': 'N/A',
                    'ProfileImage': ''
                }
            }), 200

        base64_image = ''
        image_filename = f"{email}.jpg"
        image_path = os.path.join('uploadedimages', image_filename)

        if not os.path.exists(image_path):
            sanitized = f"{email.replace('@', '_').replace('.', '_')}.jpg"
            alt_path = os.path.join('uploadedimages', sanitized)
            if os.path.exists(alt_path):
                image_path = alt_path

        if os.path.exists(image_path):
            try:
                with open(image_path, 'rb') as f:
                    base64_image = base64.b64encode(f.read()).decode('utf-8')
            except Exception:
                base64_image = ''

        columns = [prop.key for prop in class_mapper(SignupDetails).iterate_properties
                   if isinstance(prop, ColumnProperty)]
        user_data = {column: getattr(user_details, column) for column in columns}
        user_data['ProfileImage'] = base64_image

        return jsonify({'user_details': user_data}), 200

    except Exception as e:
        print(f"Error in get_details_with_image endpoint: {str(e)}")
        return jsonify({
            'user_details': {
                'Name': 'Patient',
                'Email_ID': '',
                'Age': 25.0,
                'Gender': 'Other',
                'Occupation': '',
                'Height': '',
                'Weight': '',
                'ProfileImage': ''
            }
        }), 200

@app.route('/upload_video', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return 'No file part'

    file = request.files['file']
    if file.filename == '':
        return 'No selected file'

    # Get the activity name from the request parameters
    activity_name = request.args.get('activity', 'default_activity')    
    AngerScale = request.args.get('scale', 'uploads') 
    # Set the filename as the activity name
    filename = f"{activity_name}.mp4"

    # Save the uploaded file to a directory (e.g., uploads folder)
    file.save(f"{AngerScale}/" + filename)

    return 'File uploaded successfully'


#-----------------------------------------------------------------------------------------

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

@app.route('/video_send', methods=['GET'])
def send_video():
    folder_name = request.args.get('foldername', '').strip()
    file_name = request.args.get('filename', '').strip()

    print(f"[/video_send] Requested folder: '{folder_name}', file: '{file_name}'")

    if folder_name and file_name:
        # 1. Exact match in requested folder
        video_path = os.path.join(BASE_DIR, folder_name, f"{file_name}.mp4")
        if os.path.exists(video_path):
            print(f"[/video_send] Found exact file: {video_path}")
            return send_file(video_path, as_attachment=False, mimetype='video/mp4')

        # 2. Case-insensitive match in requested folder
        folder_dir = os.path.join(BASE_DIR, folder_name)
        if os.path.isdir(folder_dir):
            for f in os.listdir(folder_dir):
                if f.lower() == f"{file_name.lower()}.mp4":
                    target = os.path.join(folder_dir, f)
                    print(f"[/video_send] Found case-insensitive in {folder_name}: {target}")
                    return send_file(target, as_attachment=False, mimetype='video/mp4')

        # 3. Check across other anger tier folders for the EXACT same day and activity
        for alt_folder in ['Minimal Anger', 'Moderate Anger', 'Mild Anger']:
            if alt_folder.lower() == folder_name.lower():
                continue
            alt_path = os.path.join(BASE_DIR, alt_folder, f"{file_name}.mp4")
            if os.path.exists(alt_path):
                print(f"[/video_send] Found session in alternate tier {alt_folder}: {alt_path}")
                return send_file(alt_path, as_attachment=False, mimetype='video/mp4')

        # 4. If that specific day is not recorded, match the same activity type (Activity 1 vs Activity 2)
        act_match = re.search(r'Activity\s*(\d+)', file_name, re.IGNORECASE)
        act_num = act_match.group(1) if act_match else '1'

        if os.path.isdir(folder_dir):
            matching_acts = [f for f in sorted(os.listdir(folder_dir)) if f'Activity {act_num}' in f and f.endswith('.mp4')]
            if matching_acts:
                chosen = os.path.join(folder_dir, matching_acts[0])
                print(f"[/video_send] Fallback to same activity type in {folder_name}: {chosen}")
                return send_file(chosen, as_attachment=False, mimetype='video/mp4')

        min_dir = os.path.join(BASE_DIR, 'Minimal Anger')
        if os.path.isdir(min_dir):
            matching_acts = [f for f in sorted(os.listdir(min_dir)) if f'Activity {act_num}' in f and f.endswith('.mp4')]
            if matching_acts:
                chosen = os.path.join(min_dir, matching_acts[0])
                print(f"[/video_send] Fallback to Minimal Anger Activity {act_num}: {chosen}")
                return send_file(chosen, as_attachment=False, mimetype='video/mp4')

    # Global safe fallback
    fallback = os.path.join(BASE_DIR, 'Minimal Anger', 'Day-1 Activity 1.mp4')
    if os.path.exists(fallback):
        return send_file(fallback, as_attachment=False, mimetype='video/mp4')

    return "No video found in the available folders.", 404


# @app.route('/video', methods=['GET'])
# def send_video():
#     video_path = 'C:/python_projects/flask/Moderate Anger/Day-1 Activity 1.mp4'
#     return send_file(video_path, as_attachment=False)




#-----------------------------------Score-Updation & tabele Score creation----------------------------------------

class Score(db.Model):
    _tablename_ = 'score'
    
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(50), unique=True, nullable=False)
    negativecount = db.Column(db.Integer, default=0)
    positivecount = db.Column(db.Integer, default=0)
    joyful = db.Column(db.Integer, default=0)
    happy = db.Column(db.Integer, default=0)
    amazed = db.Column(db.Integer, default=0)
    depression = db.Column(db.Integer, default=0)
    chill = db.Column(db.Integer, default=0)
    miserable = db.Column(db.Integer, default=0)
    furious = db.Column(db.Integer, default=0)
    irritated = db.Column(db.Integer, default=0)
    manic = db.Column(db.Integer, default=0)
    calm = db.Column(db.Integer, default=0)
    score_1 = db.Column(db.Integer)
    score_1_date = db.Column(db.Date)
    anger_scale_1 = db.Column(db.String(50))
    score_2 = db.Column(db.Integer)
    score_2_date = db.Column(db.Date)
    anger_scale_2 = db.Column(db.String(50))
    # New columns for PSS scale
    firstPssScale = db.Column(db.String(50))
    firstPssScaleDate = db.Column(db.Date)
    SecondPssScale = db.Column(db.String(50))
    SecondPssScaleDate = db.Column(db.Date)


@app.route('/update_pss_scale', methods=['POST'])
def update_pss_scale():
    data = request.json
    email = data.get("email")
    first_pss_scale = data.get("firstPssScale")
    second_pss_scale = data.get("SecondPssScale")

    if not email:
        return jsonify({"error": "Email is required"}), 400

    # Find the user by email
    user = Score.query.filter_by(email=email).first()

    if not user:
        return jsonify({"error": "Email not found in database"}), 404

    if first_pss_scale is not None:
        user.firstPssScale = first_pss_scale
        user.firstPssScaleDate = datetime.utcnow().date()  # Using date() to match Date column type
    elif second_pss_scale is not None:
        user.SecondPssScale = second_pss_scale
        user.SecondPssScaleDate = datetime.utcnow().date()  # Using date() to match Date column type
    else:
        return jsonify({"error": "No valid data to update"}), 400

    db.session.commit()
    return jsonify({"message": "PSS scale updated successfully"})



@app.route('/get_pss_scores', methods=['GET'])
def get_pss_scores():
    email = request.args.get('email')
    
    if not email:
        return jsonify({"error": "Email parameter is required"}), 400
    
    # Find the user by email
    user = Score.query.filter_by(email=email).first()
    
    if not user:
        return jsonify({"error": "Email not found in database"}), 404
    
    # Return the PSS scores and dates
    scores = {
        "firstPssScale": user.firstPssScale,
        "firstPssScaleDate": user.firstPssScaleDate.isoformat() if user.firstPssScaleDate else None,
        "SecondPssScale": user.SecondPssScale,
        "SecondPssScaleDate": user.SecondPssScaleDate.isoformat() if user.SecondPssScaleDate else None
    }
    
    return jsonify(scores)

@app.route('/update_score', methods=['POST'])
def update_score():
    try:
        data = request.get_json(silent=True) or {}
        email = data.get('email')
        score_1 = data.get('score_1')
        anger_scale_1 = data.get('anger_scale_1')
        score_2 = data.get('score_2')
        anger_scale_2 = data.get('anger_scale_2')

        if not email:
            return jsonify({'message': 'Email is required'}), 400

        existing_score = Score.query.filter_by(email=email).first()
        if not existing_score:
            existing_score = Score(email=email)
            db.session.add(existing_score)

        if score_1 is not None:
            existing_score.score_1 = int(score_1)
        if anger_scale_1:
            existing_score.anger_scale_1 = anger_scale_1
            # Also sync to Activity.angerscale
            act = Activity.query.filter_by(email=email).first()
            if not act:
                act = Activity(email=email, angerscale=anger_scale_1)
                db.session.add(act)
            else:
                act.angerscale = anger_scale_1

        if score_2 is not None:
            existing_score.score_2 = int(score_2)
            existing_score.score_2_date = datetime.now().date()
        if anger_scale_2:
            existing_score.anger_scale_2 = anger_scale_2

        db.session.commit()

        # Automated Critical Alert if severe
        try:
            score_val = int(score_1) if score_1 is not None else 0
            scale_str = str(anger_scale_1 or '')
            if score_val >= 29 or 'sever' in scale_str.lower() or 'critical' in scale_str.lower():
                crit_notif = PatientNotification(
                    email=email,
                    title='Clinical Advisory: Clinical Assist Recommended',
                    message=f'Your recent anger calibration assessment recorded a score of {score_val}/63 ({scale_str}). We strongly advise consulting with your doctor or reaching out to clinic assist.',
                    category='Clinician',
                    action_type='consult_clinic',
                    priority='critical',
                    is_read=False
                )
                db.session.add(crit_notif)
                db.session.commit()
        except Exception as ex:
            print(f"Error logging severe alert: {ex}")

        return jsonify({'message': 'Score updated successfully'}), 200
    except Exception as e:
        print(f"Error in update_score: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/get_score_1', methods=['GET', 'POST'])
def get_score_1():
    try:
        data = request.get_json(silent=True) or {}
        email = data.get('email') or request.args.get('email')
        if not email:
            return jsonify({'error': 'Email is required', 'score_1': None}), 400

        entry = Score.query.filter_by(email=email).first()
        if not entry:
            return jsonify({'error': 'No entry found for the email', 'score_1': None, 'score_2': None}), 200

        return jsonify({
            'id': entry.id,
            'email': entry.email,
            'score_1': entry.score_1,
            'score_1_date': str(entry.score_1_date) if entry.score_1_date else None,
            'anger_scale_1': entry.anger_scale_1,
            'score_2': entry.score_2,
            'score_2_date': str(entry.score_2_date) if entry.score_2_date else None,
            'anger_scale_2': entry.anger_scale_2,
            'status': 'success'
        }), 200
    except Exception as e:
        print(f"Error in get_score_1: {e}")
        return jsonify({'error': str(e), 'score_1': None}), 500


@app.route('/update_score2', methods=['POST'])
def update_score2():
    try:
        data = request.get_json(silent=True) or {}
        email = data.get('email')
        score_2 = data.get('score_2')
        anger_scale_2 = data.get('anger_scale_2')

        if not email:
            return jsonify({'message': 'Email is required'}), 400

        existing_score = Score.query.filter_by(email=email).first()
        if not existing_score:
            existing_score = Score(email=email)
            db.session.add(existing_score)

        if score_2 is not None:
            existing_score.score_2 = int(score_2)
            existing_score.score_2_date = datetime.now().date()
        if anger_scale_2:
            existing_score.anger_scale_2 = anger_scale_2

        db.session.commit()
        return jsonify({'message': 'Score 2 updated successfully'}), 200
    except Exception as e:
        print(f"Error in update_score2: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/check_score_2_date', methods=['GET', 'POST'])
def check_score_2_date():
    try:
        data = request.get_json(silent=True) or {}
        email = data.get('email') or request.args.get('email')
        if not email:
            return jsonify({'is_score_2_date_today': 'false', 'is_score_2_null': 'true'}), 200

        entry = Score.query.filter_by(email=email).first()
        if not entry or not entry.score_2_date:
            return jsonify({'is_score_2_date_today': 'false', 'is_score_2_null': 'true'}), 200

        is_today = (entry.score_2_date == datetime.now().date())
        is_null = (entry.score_2 is None)
        return jsonify({
            'is_score_2_date_today': str(is_today).lower(),
            'is_score_2_null': str(is_null).lower()
        }), 200
    except Exception as e:
        print(f"Error in check_score_2_date: {e}")
        return jsonify({'is_score_2_date_today': 'false', 'is_score_2_null': 'true'}), 500


@app.route('/update_activity', methods=['POST'])
def update_activity():
    try:
        data = request.get_json(silent=True) or {}
        email = data.get('email')
        day_activity = data.get('day_activity')
        angerscaletype = data.get('scale')
        feedbackscore = data.get('feedbackscore')

        if not email or not day_activity:
            return jsonify({'error': 'Invalid input'}), 400

        # Parse column names: e.g. 'Day-1 Activity 1' -> 'Day1_Activity_1'
        match = re.search(r'Day-?(\d+)[_\s]+Activity[_\s]+(\d+)', str(day_activity), re.IGNORECASE)
        if match:
            day_num = match.group(1)
            act_num = match.group(2)
            anns = f"Day{day_num}_Activity_{act_num}"
        else:
            ans = str(day_activity).split()
            days = ans[0].split('-')
            anns = (days[0] + days[1] if len(days) >= 2 else days[0]) + "_" + ans[1] + "_" + ans[2]

        fscore = f"{anns}_s"

        user = Activity.query.filter_by(email=email).first()
        if not user:
            user = Activity(email=email)
            db.session.add(user)

        setattr(user, anns, 'Done')
        if feedbackscore is not None:
            setattr(user, fscore, feedbackscore)
        if angerscaletype:
            user.angerscale = angerscaletype

        # Update emotion tally in Score
        mood_dict = {
            1: "joyful",
            2: "happy",
            3: "amazed",
            4: "depression",
            5: "chill",
            6: "miserable",
            7: "furious",
            8: "irritated",
            9: "manic",
            10: "calm",
        }
        col = mood_dict.get(feedbackscore)
        if col:
            existing_score = Score.query.filter_by(email=email).first()
            if not existing_score:
                existing_score = Score(email=email)
                db.session.add(existing_score)
            current_val = getattr(existing_score, col, 0) or 0
            setattr(existing_score, col, current_val + 1)

        db.session.commit()
        print(f"[/update_activity] {email}: {anns} marked Done, feedback: {feedbackscore}")
        return jsonify({'message': 'Data updated successfully'}), 200
    except Exception as e:
        db.session.rollback()
        print(f"Error in update_activity: {e}")
        return jsonify({'error': str(e)}), 500

#---------------------------------------------------------------------------------
@app.route('/get_angerscale', methods=['GET', 'POST'])
@app.route('/get_anger_scale', methods=['GET', 'POST'])
def get_angerscale():
    try:
        data = request.get_json(silent=True) or {}
        email = data.get('email') or data.get('Email_ID') or request.args.get('email')

        if not email:
            return jsonify({'angerscale': 'Minimal Anger', 'anger_scale_1': 'Minimal Anger', 'message': 'No email provided'}), 200

        activity_entry = Activity.query.filter_by(email=email).first()
        scale = (activity_entry.angerscale if activity_entry and activity_entry.angerscale else 'Minimal Anger')
        return jsonify({'angerscale': scale, 'anger_scale_1': scale, 'status': 'success'}), 200
    except Exception as e:
        return jsonify({'angerscale': 'Minimal Anger', 'anger_scale_1': 'Minimal Anger', 'error': str(e)}), 200

#--------------------------------------------------------------------------------------
@app.route('/get_activity_update', methods=['GET', 'POST'])
def get_activity_update():
    try:
        data = request.get_json(silent=True) or {}
        email = data.get('email') or data.get('Email_ID') or request.args.get('email')

        if not email:
            return jsonify([0] * 10), 200

        user_data = Activity.query.filter_by(email=email).order_by(Activity.email.desc()).first()
        if user_data:
            update_list = [
                1 if getattr(user_data, 'Day1_Activity_1', None) == 'Done' else 0,
                1 if getattr(user_data, 'Day1_Activity_2', None) == 'Done' else 0,
                1 if getattr(user_data, 'Day2_Activity_1', None) == 'Done' else 0,
                1 if getattr(user_data, 'Day2_Activity_2', None) == 'Done' else 0,
                1 if getattr(user_data, 'Day3_Activity_1', None) == 'Done' else 0,
                1 if getattr(user_data, 'Day3_Activity_2', None) == 'Done' else 0,
                1 if getattr(user_data, 'Day4_Activity_1', None) == 'Done' else 0,
                1 if getattr(user_data, 'Day4_Activity_2', None) == 'Done' else 0,
                1 if getattr(user_data, 'Day5_Activity_1', None) == 'Done' else 0,
                1 if getattr(user_data, 'Day5_Activity_2', None) == 'Done' else 0,
            ]
            return jsonify({'update_list': update_list}), 200
        else:
            return jsonify({'update_list': [0] * 10}), 200
    except Exception as e:
        return jsonify({'update_list': [0] * 10, 'error': str(e)}), 200

@app.route('/check_activity', methods=['GET', 'POST'])
def check_activity():
    try:
        data = request.get_json(silent=True) or {}
        email = data.get('email') or data.get('Email_ID') or request.args.get('email')
        day_activity = data.get('day_activity', '')

        if not email:
            return jsonify({'result': 'no'}), 200

        # Parse target day and activity number
        match = re.search(r'Day-?(\d+)[_\s]+Activity[_\s]+(\d+)', str(day_activity), re.IGNORECASE)
        if match:
            day_num = int(match.group(1))
            act_num = int(match.group(2))
        else:
            ans = str(day_activity).split()
            if len(ans) >= 3:
                day_num = int(re.sub(r'\D', '', ans[0]))
                act_num = int(re.sub(r'\D', '', ans[2]))
            else:
                day_num = 1
                act_num = 1

        # Day 1 Activity 1 is the starting session of the curriculum - ALWAYS unlocked for every patient!
        if day_num == 1 and act_num == 1:
            return jsonify({'result': 'yes'}), 200

        # Determine prerequisite column:
        # - Activity 2 requires Activity 1 of the same day to be 'Done'
        # - Activity 1 of Day X requires Activity 2 of Day X-1 to be 'Done'
        if act_num == 2:
            prereq_col = f"Day{day_num}_Activity_1"
        else:
            prereq_col = f"Day{day_num - 1}_Activity_2"

        user = Activity.query.filter_by(email=email).first()
        if not user:
            return jsonify({'result': 'no'}), 200

        prereq_val = getattr(user, prereq_col, None)
        if prereq_val == 'Done':
            return jsonify({'result': 'yes'}), 200
        else:
            return jsonify({'result': 'no'}), 200
    except Exception as e:
        print(f"Error in check_activity: {e}")
        return jsonify({'result': 'no', 'error': str(e)}), 200

#----------------------------------------Anger Scale Count------------------------------------------

@app.route('/anger_scale_counts', methods=['GET'])
def get_anger_scale_counts():
    try:
        # Minimal Anger count
        minimal_anger_count = db.session.query(func.count()).filter(Activity.angerscale == 'Minimal Anger').scalar()

        # Severe Anger count
        severe_anger_count = db.session.query(func.count()).filter(Activity.angerscale == 'Sever Anger').scalar()

        # Moderate Anger count
        moderate_anger_count = db.session.query(func.count()).filter(Activity.angerscale == 'Moderate Anger').scalar()

        # Mild Anger count
        mild_anger_count = db.session.query(func.count()).filter(Activity.angerscale == 'Mild Anger').scalar()

        # Critical Anger count
        critical_anger_count = db.session.query(func.count()).filter(Activity.angerscale == 'Critical Anger').scalar()

        # Return the counts in JSON format
        anger_counts = {
            'Minimal Anger': minimal_anger_count,
            'Severe Anger': severe_anger_count,
            'Moderate Anger': moderate_anger_count,
            'Mild Anger': mild_anger_count,
            'Critical Anger': critical_anger_count,
        }

        return jsonify(anger_counts)

    except Exception as e:
        # Handle exceptions or errors
        return jsonify({'error': str(e)}), 500

@app.route('/delete_account', methods=['POST'])
def delete_account():
    try:
        # Parse the request to get the email ID
        data = request.json
        email = data['Email_ID']
        
        # Check if the user exists in the database
        user = SignupDetails.query.filter_by(Email_ID=email).first()

        if user:
            # Delete the user if found
            db.session.delete(user)
            db.session.commit()
            return jsonify({'message': 'Account deleted successfully'}), 200
        else:
            return jsonify({'error': 'User not found'}), 404

    except Exception as e:
        print(f"Error in delete_account endpoint: {str(e)}")
        return jsonify({'error': str(e)}), 500

#-------------------------------------------------------------------------------------------------

#-------------------------------------------------------------------------------------------------



@app.route('/patient_forgot_password', methods=['POST'])
def patient_forgot_password():
    try:
        data = request.get_json(silent=True) or {}
        email = data.get('Email_ID') or data.get('email')
        new_password = data.get('New_Password') or data.get('new_password') or data.get('Password')

        if not email or not new_password:
            return jsonify({'message': 'Email and new password are required'}), 400

        user = SignupDetails.query.filter_by(Email_ID=email).first()
        if not user:
            return jsonify({'message': 'Patient account not found with this email'}), 404

        if len(new_password) < 6:
            return jsonify({'message': 'Password must be at least 6 characters'}), 400

        new_password_hash = bcrypt.generate_password_hash(new_password).decode('utf-8')
        user.password_hash = new_password_hash
        db.session.commit()

        # Security notification
        try:
            notif = PatientNotification(
                email=email,
                title='Security Alert: Password Updated',
                message='Your patient portal password was successfully updated. If you did not make this change, please contact clinic support.',
                category='Milestones',
                action_type='none',
                priority='normal',
                is_read=False
            )
            db.session.add(notif)
            db.session.commit()
        except Exception:
            pass

        return jsonify({'message': 'Password updated successfully'}), 200

    except Exception as e:
        print(f"Error in patient_forgot_password endpoint: {str(e)}")
        return jsonify({'message': f'Failed to update password: {str(e)}'}), 500


#-----------------------------------------------patient notifications-------------------------------------------

@app.route('/get_patient_notifications', methods=['GET', 'POST'])
def get_patient_notifications():
    try:
        data = request.get_json(silent=True) or {}
        email = data.get('email') or data.get('Email_ID') or request.args.get('email')

        if not email:
            return jsonify({'notifications': []}), 200

        notifications = PatientNotification.query.filter_by(email=email).order_by(PatientNotification.created_at.desc()).all()

        # If patient has no notifications yet, initialize starter clinical notifications
        if not notifications:
            starter_notifs = [
                PatientNotification(
                    email=email,
                    title='Daily Recovery Session Ready',
                    message='Your Day 1 mindfulness exercise is ready. Take 10 minutes to center your thoughts and reduce tension.',
                    category='Therapy',
                    action_type='start_session',
                    priority='normal',
                    is_read=False
                ),
                PatientNotification(
                    email=email,
                    title='Clinical Support Available',
                    message='Dr. Dinesh and your mental health care team are ready if you need guided assistance with anger reduction.',
                    category='Clinician',
                    action_type='consult_clinic',
                    priority='normal',
                    is_read=False
                ),
                PatientNotification(
                    email=email,
                    title='Afternoon Mood Reflection',
                    message='Notice any feelings of irritation? Logging your reflection in the diary helps recalibrate your emotions.',
                    category='Mindfulness',
                    action_type='write_diary',
                    priority='normal',
                    is_read=False
                ),
                PatientNotification(
                    email=email,
                    title='Anger Scale Calibration Ongoing',
                    message='Your baseline assessment establishes your personalized 13-day cognitive therapy roadmap.',
                    category='Milestones',
                    action_type='view_analytics',
                    priority='normal',
                    is_read=True
                )
            ]
            for sn in starter_notifs:
                db.session.add(sn)
            db.session.commit()
            notifications = starter_notifs

        result = []
        for n in notifications:
            result.append({
                'id': n.id,
                'email': n.email,
                'title': n.title,
                'message': n.message,
                'category': n.category,
                'action_type': n.action_type,
                'priority': n.priority,
                'is_read': n.is_read,
                'created_at': n.created_at.strftime("%Y-%m-%d %H:%M:%S") if n.created_at else ""
            })

        return jsonify({'notifications': result}), 200

    except Exception as e:
        print(f"Error in get_patient_notifications: {str(e)}")
        return jsonify({'notifications': [], 'error': str(e)}), 200

@app.route('/send_patient_notification', methods=['POST'])
def send_patient_notification():
    try:
        data = request.get_json(silent=True) or {}
        email = data.get('email') or data.get('Email_ID')
        title = data.get('title')
        message = data.get('message')
        category = data.get('category', 'Clinician')
        action_type = data.get('action_type', 'consult_clinic')
        priority = data.get('priority', 'normal')

        if not email or not title or not message:
            return jsonify({'error': 'Email, title, and message are required'}), 400

        new_notif = PatientNotification(
            email=email,
            title=title,
            message=message,
            category=category,
            action_type=action_type,
            priority=priority,
            is_read=False
        )
        db.session.add(new_notif)
        db.session.commit()

        return jsonify({'message': 'Notification sent successfully', 'id': new_notif.id}), 200

    except Exception as e:
        print(f"Error in send_patient_notification: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/mark_notification_read', methods=['POST'])
def mark_notification_read():
    try:
        data = request.get_json(silent=True) or {}
        notif_id = data.get('id')
        email = data.get('email') or data.get('Email_ID')

        if notif_id:
            notif = PatientNotification.query.get(notif_id)
            if notif:
                notif.is_read = True
                db.session.commit()
                return jsonify({'message': 'Marked as read'}), 200
        elif email:
            PatientNotification.query.filter_by(email=email).update({'is_read': True})
            db.session.commit()
            return jsonify({'message': 'All notifications marked as read'}), 200

        return jsonify({'message': 'No id or email provided'}), 400

    except Exception as e:
        print(f"Error in mark_notification_read: {str(e)}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
        # Ensure doctor table has new profile columns if already created in MySQL
        try:
            with db.engine.connect() as conn:
                columns_to_add = [
                    ("age", "INT NULL DEFAULT 38"),
                    ("gender", "VARCHAR(20) NULL DEFAULT 'Male'"),
                    ("experience", "VARCHAR(50) NULL DEFAULT '10 Years'"),
                    ("contact", "VARCHAR(30) NULL DEFAULT '+91 98765 43210'"),
                    ("status", "VARCHAR(20) NULL DEFAULT 'Active'")
                ]
                for col_name, col_def in columns_to_add:
                    try:
                        conn.execute(text(f"ALTER TABLE doctor ADD COLUMN {col_name} {col_def}"))
                        conn.commit()
                    except Exception:
                        pass
        except Exception as e:
            print("Note on doctor table alteration:", e)
        print("Successfully connected to the XAMPP MySQL database.")
    app.run(debug=True, host='0.0.0.0', port=8080)




# {
#   "Name": "Your Name",
#   "Mobile_No": "1234567890",
#   "Email_ID": "your_email@example.com",
#   "Password": "your_password",
#   "Confirm_Password": "your_password"
# }

#-----------------------------------------------patient forgot password-------------------------------------------
