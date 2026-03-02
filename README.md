# Maternal Healthcare App 

A comprehensive, dual-interface Flutter application designed to bridge the gap between expectant mothers and their healthcare providers. The app facilitates remote monitoring of maternal vitals and fetal health data, ensuring continuous care and timely medical interventions.

This repository serves as the software interface for the **Design and Implementation of a Frequency Generator for Fetal Heart Rate Detection** project. 

## 🌟 Key Features

### For Patients
* **Secure Authentication:** Phone number verification via Firebase Auth.
* **Personalized Dashboard:** View assigned consulting doctor and personal health profile.
* **Real-Time Vitals Tracking:** Log and monitor Blood Pressure and Heart Rate.
* **Fetal Data Monitoring:** Seamlessly record Fetal Heart Rate (FHR) readings.

### For Doctors
* **Whitelist Verification:** Secure onboarding requiring a valid Medical License ID to claim a profile.
* **Patient Management:** Dedicated dashboard displaying only the patients explicitly assigned to the logged-in doctor.
* **Remote Monitoring:** Direct access to real-time updates on patient vitals and fetal health histories.

## 🛠 Tech Stack
* **Frontend:** [Flutter](https://flutter.dev/) & Dart
* **Backend (BaaS):** [Firebase](https://firebase.google.com/) (Migrated from Supabase)
* **Authentication:** Firebase Phone Authentication (OTP)
* **Database:** Cloud Firestore (NoSQL Document Database)
* **State Management:** Provider pattern