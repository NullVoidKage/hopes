# Firebase Storage CORS Configuration

## Problem
When accessing Firebase Storage images from a web app, you may encounter CORS errors:
```
Access to XMLHttpRequest at 'https://firebasestorage.googleapis.com/...' from origin 'https://hope-elearning-52e9b.web.app' has been blocked by CORS policy
```

## Solution
Configure CORS on your Firebase Storage bucket to allow requests from your web app.

## Method 1: Using gsutil (Recommended)

1. **Install Google Cloud SDK** (if not already installed):
   ```bash
   # macOS
   brew install google-cloud-sdk
   
   # Or download from: https://cloud.google.com/sdk/docs/install
   ```

2. **Authenticate with Google Cloud**:
   ```bash
   gcloud auth login
   ```

3. **Set your project**:
   ```bash
   gcloud config set project hope-elearning-52e9b
   ```

4. **Apply CORS configuration**:
   ```bash
   gsutil cors set cors.json gs://hope-elearning-52e9b.firebasestorage.app
   ```

5. **Verify CORS configuration**:
   ```bash
   gsutil cors get gs://hope-elearning-52e9b.firebasestorage.app
   ```

## Method 2: Using Firebase Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/storage/browser)
2. Select your project: `hope-elearning-52e9b`
3. Find your storage bucket: `hope-elearning-52e9b.firebasestorage.app`
4. Click on the bucket name
5. Go to the "Configuration" tab
6. Scroll to "CORS configuration"
7. Click "Edit CORS configuration"
8. Paste the contents of `cors.json`:
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
9. Click "Save"

## Method 3: Using Firebase CLI (Alternative)

If you have Firebase CLI with Storage emulator support, you can also configure this via:
```bash
firebase storage:rules:deploy
```

However, CORS configuration is typically done via gsutil or Google Cloud Console.

## Verification

After applying CORS, test by:
1. Opening your web app: https://hope-elearning-52e9b.web.app
2. Try uploading/displaying an image
3. Check browser console - CORS errors should be gone

## Troubleshooting

- **Still getting CORS errors?** Wait a few minutes for changes to propagate
- **Multiple origins?** Add them to the `origin` array in `cors.json`
- **Local development?** The config includes `http://localhost:*` for local testing

