# Quick CORS Fix for Firebase Storage

## The Problem
Your web app can't load images from Firebase Storage due to CORS (Cross-Origin Resource Sharing) restrictions.

## Quick Fix (5 minutes)

### Option 1: Google Cloud Console (Easiest - No Installation Required)

1. **Go to Google Cloud Console**:
   - Visit: https://console.cloud.google.com/storage/browser?project=hope-elearning-52e9b
   - Or: https://console.cloud.google.com → Select project "hope-elearning-52e9b" → Storage → Browser

2. **Find your bucket**:
   - Look for: `hope-elearning-52e9b.firebasestorage.app`
   - Click on the bucket name

3. **Configure CORS**:
   - Click the **"Configuration"** tab
   - Scroll down to **"CORS configuration"**
   - Click **"Edit CORS configuration"**
   - Delete any existing content
   - Paste this JSON:
   ```json
   [
     {
       "origin": ["https://hope-elearning-52e9b.web.app", "https://hope-elearning-52e9b.firebaseapp.com", "http://localhost:*"],
       "method": ["GET", "HEAD", "PUT", "POST", "DELETE", "OPTIONS"],
       "responseHeader": ["Content-Type", "Authorization", "x-goog-*", "Content-Length"],
       "maxAgeSeconds": 3600
     }
   ]
   ```
   - Click **"Save"**

4. **Wait 2-3 minutes** for changes to propagate

5. **Test**: Refresh your web app and try loading images again

### Option 2: Install gsutil and Run Command

If you prefer command line:

1. **Install Google Cloud SDK**:
   ```bash
   # macOS
   brew install google-cloud-sdk
   
   # Or download from: https://cloud.google.com/sdk/docs/install
   ```

2. **Authenticate and apply**:
   ```bash
   gcloud auth login
   gcloud config set project hope-elearning-52e9b
   gsutil cors set cors.json gs://hope-elearning-52e9b.firebasestorage.app
   ```

## What This Does

This configuration allows your web app (`https://hope-elearning-52e9b.web.app`) to:
- ✅ Load images from Firebase Storage
- ✅ Upload images to Firebase Storage
- ✅ Display images in assessments and lessons

## Verification

After applying, check browser console - the CORS error should be gone!

