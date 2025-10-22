# Use an official Node.js runtime as base image
FROM node:18-alpine

# Set working directory inside container
WORKDIR /usr/src/app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install --production

# Copy the rest of your app
COPY . .

# Expose the internal port your app listens on
EXPOSE 8080

# Command to start your app
CMD ["node", "index.js"]
