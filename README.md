# IRA - AI-Assisted Clinical Mental Health & Anger Management Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?logo=python)](https://python.org)
[![Flask](https://img.shields.io/badge/Flask-3.0-000000?logo=flask)](https://flask.palletsprojects.com)
[![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?logo=mysql)](https://mysql.com)
[![HuggingFace](https://img.shields.io/badge/HuggingFace-DistilBERT-FFD21E?logo=huggingface)](https://huggingface.co)

**IRA** is a comprehensive, full-stack digital mental health platform designed to help patients assess, understand, and regulate anger and emotional escalation through evidence-based Cognitive Behavioral Therapy (CBT) exercises, real-time AI sentiment tracking, and clinician-guided triage.

---

## Architecture Overview

`
IRA-version1/
│
├── frontend/                     # Cross-platform Mobile App (Flutter)
│   ├── lib/
│   │   ├── Authpage/             # Patient & Doctor Authentication portals
│   │   ├── PatientScreens/       # Assessment, 13-Day Curriculum, Diary, Games, Consultation
│   │   ├── DoctorScreens/        # Clinical Workstation, Cohort Analytics, Patient Details
│   │   ├── theme/                # Custom Medical Design System (AppTheme & AppColors)
│   │   └── urls.dart             # Centralized Backend Endpoint Configuration
│   ├── assets/                   # Video thumbnails, audio, and UI illustrations
│   └── pubspec.yaml              # Flutter Dependencies
│
├── backend/                      # RESTful API & Machine Learning Engine (Python/Flask)
│   ├── app.py                    # Core Flask Service, Endpoints, and Database Models
│   ├── requirements.txt          # Python Dependencies
│   ├── schema.sql                # Complete MySQL Database Schema
│   ├── doctor_profiles/          # Doctor profile avatars and clinical assets
│   └── uploadedimages/           # Patient profile and activity uploads
│
├── .gitignore                    # Production Git Ignore configuration
└── README.md                     # Platform Documentation
`

---

## Key Features

### 1. Patient Portal
* **21-Question Clinical Assessment**: Evaluates anger severity using standardized psychometric scaling (Minimal, Mild, Moderate, Severe/Critical).
* **13-Day Therapeutic Curriculum**: Structured daily video therapy sessions, mindful breathing, and cognitive recalibration.
* **Mindful Sensory Games**: De-escalation games including Fruit Ninja, Sensory Touch Points, and Expressive Drawing Canvas.
* **Thought Diary with AI Sentiment**: Captures daily emotional triggers and analyzes cognitive valence.
* **Live Clinician Consultation Page**: Real-time status indicator showing whether the attending clinician is **ACTIVE** or **INACTIVE / OFF-DUTY**, with direct phone dialer and 24/7 crisis emergency line access (Tele-MANAS: 14416).

### 2. Clinician Workstation
* **Patient Cohort Management**: Comprehensive directory of registered patients, risk categorization, and assessment scores.
* **Live Clinical Alerts & Triage**: Push notifications alerting doctors to critical score escalations and negative sentiment entries.
* **AI Sentiment Review**: Deep-learning sentiment breakdown (POSITIVE vs NEGATIVE) of patient diary entries.
* **Doctor Profile Management**: Full clinician credential management (Name, Age, Gender, Experience, Contact, Availability Status).

### 3. Machine Learning & NLP Pipeline
* **Model**: **DistilBERT** (distilbert-base-uncased-finetuned-sst-2-english) via Hugging Face Transformers.
* **Fallback**: Lexicon-based **TextBlob Sentiment Analyzer** for seamless offline capability.

---

## Release Milestones

* **1.0.0 - Core Patient Assessment & Therapy Engine**
  * 21-Question Anger Scale Calibration
  * 13-Day Therapy Plan, Mindful Games, and Basic Diary
* **2.0.0 - Doctor Clinical Workstation & AI Sentiment Integration**
  * Clinician Dashboard & Cohort Monitoring
  * DistilBERT Sentiment Pipeline & Triage Notifications
* **3.0.0 - Doctor Dynamic Profile & Real-Time Availability Sync**
  * Doctor Profile Edit Portal (Name, Age, Gender, Experience, Contact, Status)
  * Live Active/Inactive Clinician Status on Patient Consultation Page
  * Pixel Overflow & Responsive UI Fixes

---

## Quick Start Guide

### Backend Setup (Python / Flask)
`ash
cd backend
python -m venv venv
venv\Scripts\activate          # On Windows
pip install -r requirements.txt
python app.py
`
*Backend runs on http://127.0.0.1:8080 by default.*

### Frontend Setup (Flutter)
`ash
cd frontend
flutter pub get
flutter run
`

---

## License & Attribution
Developed for the IRA Mental Health & Behavioral Wellness Initiative.
