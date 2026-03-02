# Maternal Healthcare App

A comprehensive, dual-interface mobile application designed to bridge the gap between expectant mothers and their healthcare providers. Built with **Flutter**, this platform facilitates remote monitoring of maternal vitals, fetal health data, and automated clinical workflows to ensure continuous care and timely medical interventions.

This repository serves as the software interface for the **Design and Implementation of a Frequency Generator for Fetal Heart Rate Detection** project.

---

# Features

# Patient Interface

## Secure Authentication
- Phone number verification using **Firebase Authentication (OTP)**
- Automatic role assignment

## Health Dashboard
- Manage personal health metrics:
  - Weight
  - Date of Birth
- View assigned primary healthcare provider

## Real-Time Vitals Tracking

Monitor and log:

- Blood Pressure
- Heart Rate
- Fetal Heart Rate (FHR)

## Immunization Tracker

- Real-time vaccination schedule
- Read-only secure sync
- Automated SMS reminder drafting

## Shared Medical Records

Secure access via cloud integration:

- Ultrasound reports
- Prescriptions
- Medical documents

---

# Healthcare Provider Interface

## Verified Onboarding

Secure registration requiring:

- Medical License ID
- Specialization

## Patient Management

- View only assigned patients
- Role-based access control

## Clinical Actions Engine

- Mark vaccinations as administered
- Instant sync with patient application

## Machine Learning Diagnostics

Integrated **TensorFlow Lite model**

Detects fetal presentation:

- Cephalic Position
- Breech Position

Provides:

- Confidence score
- Offline inference capability

## Centralized Document Access

- Upload medical records
- View patient reports
- Cloud-based access

---

# Technical Architecture

# Core Stack

| Layer | Technology |
|------|------------|
| Frontend | Flutter & Dart |
| Backend | Firebase |
| Authentication | Firebase Phone Auth |
| Database | Cloud Firestore |
| State Management | Provider |
| Machine Learning | TensorFlow Lite |

---

# Security and Data Flow

## Role-Based Routing

Authentication Wrapper automatically routes users:

- Patient Interface
- Doctor Interface

Based on Firestore role.

## Data Isolation

Firestore security ensures:

- Doctor can access only assigned patients
- Uses secure query filtering (`arrayContains`)

---

# Getting Started

# Prerequisites

- Flutter SDK (3.10.0 or higher)
- Android Studio or VS Code
- Firebase Project configured

---

# Installation

## Clone Repository

```bash
git clone https://github.com/yourusername/maternalhealthcare_app.git
```

## Navigate to Project

```bash
cd maternalhealthcare_app
```

## Install Dependencies

```bash
flutter pub get
```

## Firebase Setup

Place files:

Android:

```
android/app/google-services.json
```

iOS:

```
ios/Runner/GoogleService-Info.plist
```

## Run App

```bash
flutter run
```

---

# Build Release APK

```bash
flutter build apk --release
```

---

# Machine Learning Integration

Uses:

- TensorFlow Lite
- Offline image classification
- Real-time fetal position detection

Optimized with:

- ProGuard
- R8 Minifier

---

# Project Highlights

- Dual user system
- Real-time vitals monitoring
- Machine learning powered fetal diagnostics
- Firebase cloud backend
- Secure authentication
- Role-based system
- Offline ML capability

---

# Tech Concepts Demonstrated

- Flutter Development
- Firebase Integration
- Cloud Firestore
- TensorFlow Lite Integration
- Authentication Systems
- State Management
- Healthcare Application Architecture

---

# Future Improvements

- Live device integration for fetal heart rate sensor
- Doctor video consultation
- AI risk prediction
- Emergency alert system
- Web dashboard

---

GitHub: https://github.com/abhishekraooo
