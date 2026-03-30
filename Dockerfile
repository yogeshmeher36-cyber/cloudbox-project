FROM nginx:alpine

# Copy the HTML application into the nginx web root
COPY src/ /usr/share/nginx/html/

# Expose port 80 for HTTP traffic
EXPOSE 80

# Start nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
