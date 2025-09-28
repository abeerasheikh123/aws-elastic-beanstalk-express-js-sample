# Use Node.js 16 LTS as base image
FROM node:16

# Create app directory
WORKDIR /usr/src/app

# Copy package.json and package-lock.json first (for better caching)
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy the rest of the application code
COPY . .

# Expose port (the sample Express app listens on 3000)
EXPOSE 3000

# Start the application
CMD ["node", "app.js"]
