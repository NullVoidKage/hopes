# Simple CORS Configuration Steps

## Method 1: Copy-Paste Each Command Separately

In Google Cloud Shell, run these commands **one at a time** (press Enter after each):

### Step 1: Create the file
```bash
echo '[{"origin":["https://hope-elearning-52e9b.web.app","https://hope-elearning-52e9b.firebaseapp.com","http://localhost:*"],"method":["GET","HEAD","PUT","POST","DELETE","OPTIONS"],"responseHeader":["Content-Type","Authorization","x-goog-*","Content-Length"],"maxAgeSeconds":3600}]' > cors.json
```

### Step 2: Verify the file was created
```bash
cat cors.json
```

You should see the JSON output.

### Step 3: Apply CORS
```bash
gsutil cors set cors.json gs://hope-elearning-52e9b.firebasestorage.app
```

### Step 4: Verify it worked
```bash
gsutil cors get gs://hope-elearning-52e9b.firebasestorage.app
```

---

## Method 2: Use Nano Editor (Easier for Copy-Paste)

### Step 1: Create and edit the file
```bash
nano cors.json
```

### Step 2: Paste this content (Ctrl+V or Cmd+V):
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

### Step 3: Save and exit
- Press `Ctrl+X` (or `Cmd+X` on Mac)
- Press `Y` to confirm
- Press `Enter` to save

### Step 4: Apply CORS
```bash
gsutil cors set cors.json gs://hope-elearning-52e9b.firebasestorage.app
```

### Step 5: Verify
```bash
gsutil cors get gs://hope-elearning-52e9b.firebasestorage.app
```

---

## Method 3: Direct One-Line Command (Fastest)

Just copy and paste this entire command:

```bash
echo '[{"origin":["https://hope-elearning-52e9b.web.app","https://hope-elearning-52e9b.firebaseapp.com","http://localhost:*"],"method":["GET","HEAD","PUT","POST","DELETE","OPTIONS"],"responseHeader":["Content-Type","Authorization","x-goog-*","Content-Length"],"maxAgeSeconds":3600}]' > cors.json && gsutil cors set cors.json gs://hope-elearning-52e9b.firebasestorage.app && gsutil cors get gs://hope-elearning-52e9b.firebasestorage.app
```

This will:
1. Create the cors.json file
2. Apply the CORS configuration
3. Show you the result

---

## Troubleshooting

**If "gsutil: command not found":**
```bash
gcloud components install gsutil
```

**If permission errors:**
```bash
gcloud auth login
gcloud config set project hope-elearning-52e9b
```

**To check if it worked:**
Wait 2-3 minutes, then refresh your web app and try loading an image. Check browser console (F12) - CORS errors should be gone!

