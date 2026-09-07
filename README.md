
# 💸 SpendWise

> **Smart expense tracking for students — track, understand, and improve your spending.**

SpendWise is a student-focused personal finance app designed to make expense tracking simple, intelligent, and useful.

It combines **manual expense tracking, OCR-based payment screenshot scanning, expense categorization, monthly budgeting, spending alerts, and an AI-powered financial coach** in one application.

---

## ✨ Features

### 📊 Smart Expense Tracking

- Add expenses manually with amount, category, date, and description.
- View all transactions in one place.
- Edit transactions when details change.
- Delete transactions when they are no longer needed.
- Expenses are linked to the user's account and stored securely.

### 📸 OCR Expense Scanning

SpendWise can extract transaction information from payment screenshots using OCR.

The system can identify information such as:

- 💰 Amount
- 🏪 Merchant
- 📅 Date
- 💳 Payment details

This reduces the need to manually enter every transaction.

### 🏷️ Expense Categorization

Expenses can be organized into useful spending categories such as:

- 🍔 Food
- 🚌 Transport
- 🛍️ Shopping
- 💡 Bills
- 🎬 Entertainment
- 📦 Other

Categorization helps students understand where their money is going.

### 💰 Monthly Budget

- Set a monthly spending budget during account setup.
- Track spending against the budget.
- View spending progress.
- Edit the monthly budget anytime from Profile.
- Monitor remaining budget.

### 🚨 Smart Spending Alerts

SpendWise provides dynamic alerts based on spending behaviour, including:

- Approaching the monthly budget
- Projected overspending
- High spending in a category
- Missing expense entries

Alerts automatically reflect changes when transactions are added or deleted.

### 🤖 AI Financial Coach

SpendWise includes an AI-powered conversational financial coach.

Users can ask questions such as:

> "How am I doing this month?"

> "Where am I spending too much?"

> "How much did I spend last month?"

The AI Coach uses available budget and transaction information to provide personalized spending insights.

### 👤 Profile & Settings

Users can:

- Edit their monthly budget
- Manage notification preferences
- View privacy & security information
- Access help and FAQs
- Log out securely

---

## 🛠️ Tech Stack

| Technology | Purpose |
|---|---|
| **Flutter** | Mobile application development |
| **Dart** | Application programming |
| **Firebase Authentication** | User authentication |
| **Cloud Firestore** | Expense and budget data storage |
| **Firebase AI Logic** | AI integration |
| **Gemini** | AI-powered financial insights |
| **Firebase App Check** | Application protection |
| **Google ML Kit OCR** | Text recognition from payment screenshots |

---

## 🏗️ Architecture

```text
SpendWise
│
├── Authentication
│   └── Firebase Authentication
│
├── Expense Management
│   ├── Manual Entry
│   ├── Edit / Delete
│   └── Cloud Firestore
│
├── OCR
│   ├── Payment Screenshot
│   ├── Text Recognition
│   └── Transaction Parsing
│
├── Budget & Analytics
│   ├── Monthly Budget
│   ├── Category Spending
│   ├── Spending Alerts
│   └── Spending Projections
│
├── AI Coach
│   ├── Gemini
│   ├── Transaction Context
│   └── Personalized Insights
│
└── Profile
    ├── Budget Settings
    ├── Notification Preferences
    ├── Privacy & Security
    └── Help & Support
````

---

## 📱 Core User Flow

```text
Sign Up
   ↓
Set Monthly Budget
   ↓
Dashboard
   ↓
Add Expense
   ├── Manual Entry
   │
   └── OCR Screenshot
          ↓
     Extract Transaction
          ↓
     Categorize Expense
          ↓
     Update Spending
          ↓
     Budget & Alerts
          ↓
     AI Coach Insights
```

---

## 🚀 Getting Started

### Prerequisites

Make sure you have the following installed:

* Flutter SDK
* Dart SDK
* Android Studio
* VS Code or another Flutter-compatible IDE
* A Firebase project configured for the application

### Installation

Clone the repository:

```bash
git clone https://github.com/Purvaambre/SpendWise.git
```

Move into the project directory:

```bash
cd SpendWise
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

---

## 🔥 Firebase Configuration

SpendWise uses Firebase for:

* User authentication
* Cloud data storage
* AI integration
* Application protection

The project is configured for Firebase and Android development.

For local development, ensure the required Firebase configuration is available before running the application.

---

## 🎯 Why SpendWise?

Students often know **how much money they have**, but not necessarily **where their money is going**.

Traditional expense trackers can require users to manually enter every transaction, which can become tedious.

SpendWise focuses on reducing that effort while providing useful financial insights.

### The idea is simple:

**Track → Categorize → Understand → Get Insights → Spend Better**

By combining OCR, budgeting, alerts, and AI, SpendWise turns everyday transactions into meaningful information that can help students make better spending decisions.

---

## 🌟 What Makes SpendWise Different?

SpendWise is more than a basic expense tracker.

### 📸 Less Manual Work

Payment screenshots can be processed using OCR to extract transaction details.

### 🧠 More Than Just Numbers

The AI Coach allows users to ask questions about their spending in natural language.

### 🚨 Proactive Awareness

Budget and spending alerts help users notice potential problems before they become bigger issues.

### 🎓 Designed for Students

The app focuses on simplicity, quick expense entry, understandable insights, and practical budgeting.

---

## 📌 Project Status

SpendWise currently includes:

* ✅ User authentication
* ✅ Manual expense tracking
* ✅ OCR expense scanning
* ✅ Transaction parsing
* ✅ Expense categorization
* ✅ Monthly budgeting
* ✅ Budget editing
* ✅ Dynamic spending alerts
* ✅ Spending projections
* ✅ Transaction editing
* ✅ Transaction deletion
* ✅ AI financial coach
* ✅ Historical spending insights
* ✅ Notification preferences
* ✅ Privacy & security section
* ✅ Help & support section
* ✅ Firebase integration

---

## 👥 Team

### Purva Ambre

GitHub: [@Purvaambre](https://github.com/Purvaambre)

### Mahati Badhe

GitHub: [@Mahatibadhe05](https://github.com/Mahatibadhe05)

---

## 💜 Built With

Built with **Flutter, Firebase, Gemini, and a focus on making personal finance easier for students.**

---

## 📄 License

This project was created as a student/hackathon project.

```
