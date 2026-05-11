# CelRon Preventive Maintenance - User Manual & Facility Guide

## 1. Introduction
The CelRon Preventive Maintenance (PM) platform is an enterprise-grade industrial tool designed to transition machinery maintenance from reactive "break-fix" models to proactive, AI-driven diagnostics. 

---

## 2. Core Modules

### 2.1 Service Visit Management
*   **Job Creation**: Capture project references, customer site details, and service dates.
*   **Rapid Duplication**: Use the "Duplicate" button in the Maintenance History to clone previous quarterly inspections, saving up to 80% of data entry time.
*   **Full CRUD**: Edit, delete, and manage visits directly from the main dashboard.

### 2.2 Asset Inspection Workflow
Each machine (Motor/Pump) follows a standardized inspection process:
*   **Standardized Checklists**: Verify mechanical and electrical components (Loose bolts, winding resistance, insulation, etc.).
*   **Dual-Metric Vibration Analysis**:
    *   **Vibration (g)**: Measures high-frequency acceleration for Bearing Health.
    *   **ISO Velocity (mm/s)**: Measures overall machine stability according to ISO 10816-3.
*   **Live Engineering Converter**: Enter 'g' values, and the system automatically calculates the ISO Velocity based on the 50Hz/3000RPM standard.

---

## 3. The Quad-Mode AI Diagnostic Suite
The "AI Industrial Scan" uses Google Gemini Vision to provide expert-level diagnostics in the field.

| Mode | Purpose | What to Capture |
|---|---|---|
| **VISUAL** | Physical Audit | Photos of machine body, seals, and mounting hardware. Detects Rust, Leaks, and Loose Bolts. |
| **THERMAL** | Energy Health | Thermal (FLIR) images of bearings and terminal boxes. Detects Hotspots and Overheating. |
| **GRAPH** | Signal Analysis | Screenshots of WitMotion vibration trends. Extracts data and analyzes waveforms for harmonics. |
| **ELECTRICAL**| Load Audit | Photos of Amperage readings or Power Analyzers. Detects Ampere Surges and Phase Imbalance (Sludge detection). |

### 3.1 AI Conclusion & Verdict Engine
The **"Final AI Summary & Verdict"** feature provides a synthesized technical paragraph based on the entire inspection profile.
*   **Expert Persona**: Each result is prepared by a virtual **"Senior Preventive Maintenance Engineer"** specialized in **API 610/ISO 10816** standards.
*   **Data Synthesis**: The engine correlates Vibration (g & velocity), Thermal data, Electrical Load (Amperes), and Mechanical integrity (Leaks, Fasteners, Bolts/Nuts).
*   **Professional Output**: Generates a technical 50-100 word verdict that is automatically embedded into the final PDF certificate for professional client presentation.

---

## 4. Understanding Machine Health Badges
The app provides instant "Traffic Light" feedback:
*   **GREEN (NORMAL)**: Machine operating within safe ISO and bearing limits.
*   **ORANGE (MARGINAL)**: Early signs of wear. Recommended action provided in the Advice Box.
*   **RED (CRITICAL)**: High risk of failure. Urgent maintenance required.

---

## 5. Professional Reporting
*   **Continuous Print (PDF)**: Generates a complete site report with a professional CelRon cover page, site details, and all asset inspections in one document.
*   **Visit Report**: A high-level summary of the entire service visit for client sign-off.
*   **AI Findings**: AI diagnostic results are automatically formatted for inclusion in the final PDF certificate.

---

## 6. Technical Support & Compliance
*   **ISO 10816-3 Compliance**: All velocity readings are categorized by machine kW class (Class I to IV).
*   **Offline Capability**: Perform inspections in remote locations; data syncs automatically when reconnected to the network.
*   **GitHub Synchronization**: All code and diagnostic logic are version-controlled for enterprise audit trails.

---
*Developed for CelRon Preventive Maintenance by Antigravity AI.*
