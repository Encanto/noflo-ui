FROM node:lts-alpine as builder

RUN apk add --update git python

# Install dependencies
WORKDIR /data
COPY . /data
RUN npm install

# Build from source
RUN npm run build

# Set up server image
FROM nginx:1.21

COPY --from=builder /data/browser /usr/share/nginx/html
