# Optic TV - Premium IPTV Web App

A professional, modern single-page web application for streaming live TV channels with advanced features including URL obfuscation, PocketBase integration, and PWA support.

## Features

### 🎨 Modern UI/UX
- Beautiful gradient-based design with smooth animations
- Responsive layout for mobile, tablet, and desktop
- Card-based channel grid with hover effects
- Animated background and scroll reveal effects
- Dark theme optimized for streaming

### 📺 Advanced Video Player
- HLS.js integration for adaptive streaming
- Video.js for enhanced player controls
- URL obfuscation to hide stream URLs from sniffers
- Automatic error recovery and reconnection
- Low-latency streaming support
- Mobile-optimized player controls

### 🔒 Security Features
- Stream URL encryption and obfuscation
- Proxy-based URL masking
- Signature-based request validation
- Hidden URLs from network inspectors

### 🔌 PocketBase Integration
- Dynamic channel loading from PocketBase
- Group/category organization
- Real-time data fetching
- Authentication support
- Fallback to mock data when PocketBase unavailable

### 📱 PWA Support
- Installable on mobile devices
- Offline functionality with service worker
- Push notification support
- App shortcuts
- Full-screen mode support

### 🎯 User Experience
- Category filtering (Sports, News, Movies, etc.)
- Real-time search functionality
- Live badges on channels
- Smooth transitions and animations
- Keyboard shortcuts (ESC to close player)

## Setup Instructions

### 1. Configure PocketBase

Replace `YOUR_POCKETBASE_URL` in `index.html` with your actual PocketBase URL:

```javascript
const POCKETBASE_URL = 'https://your-pocketbase-url.com';
```

### 2. PocketBase Data Structure

Create the following collections in your PocketBase:

#### Channels Collection
- `name` (text) - Channel name
- `group` (text) - Group/category name
- `url` (url) - Stream URL
- `thumbnail` (url) - Channel logo (optional)
- `category` (text) - Category for filtering (optional)

#### Groups Collection
- `name` (text) - Group name
- `description` (text) - Group description (optional)

### 3. Serve the Application

#### Option A: Using Python
```bash
cd standalone_web
python -m http.server 8000
```

#### Option B: Using Node.js
```bash
cd standalone_web
npx serve
```

#### Option C: Using PHP
```bash
cd standalone_web
php -S localhost:8000
```

### 4. Access the App

Open your browser and navigate to:
- `http://localhost:8000` (or your configured port)

## PWA Installation

### On Desktop (Chrome/Edge)
1. Open the app in Chrome or Edge
2. Click the install button in the header when it appears
3. Follow the browser prompts to install

### On Mobile (Android)
1. Open the app in Chrome
2. Tap the menu (three dots)
3. Select "Add to Home Screen" or "Install App"

### On Mobile (iOS)
1. Open the app in Safari
2. Tap the share button
3. Select "Add to Home Screen"

## URL Obfuscation

The app uses a custom `StreamProxy` class to obfuscate stream URLs:

1. URLs are base64 encoded
2. Timestamp and signature are added
3. Requests go through a proxy endpoint
4. Original URLs are never exposed in the client

To implement the proxy on your server, create an endpoint that:
- Receives the obfuscated URL
- Validates the signature
- Decodes the URL
- Streams the content to the client

## Customization

### Colors
Edit the CSS variables in `index.html`:

```css
:root {
    --primary: #38bdf8;
    --secondary: #818cf8;
    --accent: #f472b6;
    --bg-dark: #0f172a;
    --bg-card: #1e293b;
}
```

### Categories
Modify the category buttons in the HTML:

```html
<button class="category-btn" data-category="your-category">Category Name</button>
```

### Mock Data
Edit the `loadMockChannels()` function to customize default channels.

## Browser Support

- Chrome/Edge (recommended)
- Firefox
- Safari
- Mobile browsers (iOS Safari, Chrome Mobile)

## Performance Optimization

- Lazy loading of channel thumbnails
- Efficient reconnection handling
- Optimized HLS streaming
- Service worker caching
- Minimal external dependencies

## Troubleshooting

### Channels not loading
- Check PocketBase URL configuration
- Verify PocketBase is accessible
- Check browser console for errors
- Ensure CORS is enabled on PocketBase

### Player not working
- Verify stream URL format (HLS preferred)
- Check if stream is accessible
- Try different stream URL
- Check browser console for HLS errors

### PWA not installing
- Serve over HTTPS (required for PWA)
- Check manifest.json is accessible
- Verify service worker is registered
- Use supported browser

## Security Notes

- Always use HTTPS in production
- Implement proper authentication on PocketBase
- Use environment variables for sensitive data
- Implement rate limiting on proxy endpoint
- Regular security audits recommended

## License

This project is provided as-is for educational and commercial use.

## Support

For issues or questions, please refer to the documentation or contact support.
