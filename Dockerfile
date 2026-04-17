# Use Nginx to serve the static Flutter Web build
FROM nginx:stable-alpine

# Copy a custom nginx configuration to handle SPA routing and well-known files
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the build output to Nginx's default public directory
# Note: The GitHub Action runs 'flutter build web' before this step
COPY build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
