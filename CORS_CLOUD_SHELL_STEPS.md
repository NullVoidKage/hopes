# Configure CORS Using Google Cloud Shell (Easiest Method)

## Step-by-Step Instructions

### Step 1: Open Google Cloud Shell

1. Go to: https://console.cloud.google.com/home/dashboard?project=hope-elearning-52e9b
2. Look for the **Cloud Shell icon** in the top right (looks like `>_` or a terminal icon)
3. Click it to open Cloud Shell (it will open at the bottom of the page)

### Step 2: Create the CORS Configuration File

In the Cloud Shell terminal, type:

```bash
cat > cors.json << 'EOF'
[
  {
    "origin": ["https://hope-elearning-52e9b.web.app", "https://hope-elearning-52e9b.firebaseapp.com", "http://localhost:*"],
    "method": ["GET", "HEAD", "PUT", "POST", "DELETE", "OPTIONS"],
    "responseHeader": ["Content-Type", "Authorization", "x-goog-*", "Content-Length"],
    "maxAgeSeconds": 3600
  }
]
EOF
```

Press Enter. This creates the `cors.json` file in Cloud Shell.

### Step 3: Apply CORS Configuration

Run this command:

```bash
gsutil cors set cors.json gs://hope-elearning-52e9b.firebasestorage.app
```

### Step 4: Verify It Worked

Check that CORS was applied:

```bash
gsutil cors get gs://hope-elearning-52e9b.firebasestorage.app
```

You should see the JSON configuration you just set.

### Step 5: Test

1. Wait 2-3 minutes for changes to propagate
2. Go to your web app: https://hope-elearning-52e9b.web.app
3. Try uploading or viewing an image
4. Check browser console (F12) - CORS errors should be gone!

## That's It! 🎉

Your Firebase Storage bucket now allows requests from your web app.

