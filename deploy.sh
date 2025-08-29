#!/bin/bash

echo "Building Flutter web app..."
flutter build web

echo "Preparing for Vercel deployment..."
# Copy the built files to a deploy directory
rm -rf deploy
mkdir deploy
cp -r build/web/* deploy/

echo "Deploy directory created with contents:"
ls -la deploy/

echo "Now you can deploy the 'deploy' directory to Vercel"
echo "Or update vercel.json to point to 'deploy' instead of 'build/web'"
