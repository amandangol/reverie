# Reverie - Your Digital Memory Keeper

<img src="assets/icon/icon.png" alt="ReverieLogo" width="150" height="150"/>

Reverie is a beautiful and intuitive mobile application that helps you capture, organize, and relive your precious memories through photos, videos, and journal entries. Built with Flutter, it offers a seamless experience across iOS and Android platforms.

## 🚀 Getting Started

### 📱 Download APK
Currently, Reverie is available for Android devices only. You can download the APK from:

<div align="center">
  <a href="https://github.com/amandangol/reverie/releases/latest">
    <img src="https://img.shields.io/badge/GitHub-Release-blue?style=for-the-badge&logo=github" alt="GitHub Release"/>
  </a>
  <a href="https://drive.google.com/file/d/your-file-id/view">
    <img src="https://img.shields.io/badge/Google_Drive-Download-orange?style=for-the-badge&logo=googledrive" alt="Google Drive"/>
  </a>
</div>

### 🖼️ Reverie Glimpses

 <img src="https://github.com/user-attachments/assets/b519a5c5-a73d-4097-af1c-85bf8fa9d921" alt="Gallery App Drawer" width="200" height="400" />  <img src="https://github.com/user-attachments/assets/579e0273-c119-40bb-978b-0bfdd47c80e3" alt="Journal Home" width="200" height="400" />    <img src="https://github.com/user-attachments/assets/d18a275d-ace9-4e6c-827b-7dd7c9e4316b" alt="Journal Detail" width="200" height="400" />  <img src="https://github.com/user-attachments/assets/adb08fe5-f531-4de8-ab68-4291598144ab" alt="Gallery Albums" width="200" height="400" />  <img src="https://github.com/user-attachments/assets/2c4d3396-152a-47c1-98dd-4c51f36428dc" alt="Journal Edit Detail" width="200" height="400" />  <img src="https://github.com/user-attachments/assets/dd248617-e442-481c-b91a-2d385a02be0d" alt="Object Detection" width="200" height="400" />  <img src="https://github.com/user-attachments/assets/7c97d312-1bf3-4a98-8eda-cbf67b6c6594" alt="Flashback Memories" width="200" height="400" />   <img src="https://github.com/user-attachments/assets/be101790-7f45-4373-9678-ba12400d0696" alt="Google Drive Backup" width="200" height="400" />

## 🌟 Features

### 📸 Gallery & Media
- Beautiful gallery view of your photos and videos
- Smart organization with albums and collections
- Video library for easy access to your video memories
- Favorites collection for quick access to special moments
- Built-in camera for capturing photos and videos
  - High-quality photo capture
  - Video recording up to 10 minutes
  - Quick access from gallery
  - Instant saving to gallery
- Photo editing capabilities
  - Filters and effects
  - Basic adjustments (brightness, contrast, etc.)
  - Crop and rotate
  - Text and sticker overlays
- Google Drive integration for secure backup and restoration
  - One-click backup of selected albums
  - Automatic organization in Google Drive
  - Easy restoration of backed-up content
  - Secure authentication with Google accounts
-  Search & Organization
  - Quick search across all media files
  - Filter by date, type, and tags
  - Sort albums by name, date, or size

### 📝 Journal & Memories
- Create rich journal entries with photos and videos
- Track your mood and emotional journey
- Calendar view to browse entries by date
- Add tags and categories for better organization
- AI-powered content generation to help express your thoughts
- Multi-language support for journal entries
  - Translate entries to 40+ languages
  - Real-time translation
  - Language-specific formatting
  - Easy language switching
  - Flag indicators for translated content
- Efficient Journal Management
  - Quick search through journal entries
  - Sort entries by date, mood, or tags
  - Filter entries by content type
  - Advanced text search within entries
  - Export and share functionality

### ⏳ Flashbacks & Calendar
- Relive past memories with the flashbacks feature
- Time-based memory organization
- Easy navigation through your memory timeline

### 📅 Recap & Memories
- Monthly memory recaps with beautiful timeline view
- Smart date-based grouping of memories
- Quick month navigation with visual calendar
- Memory count tracking for each month
- Beautiful grid layout for memory browsing

### 🤖 AI-Powered Features
- Smart image analysis and description generation
- AI-assisted journal writing
- Object Labeling for image
- Text recognition in images
- Personalized content suggestions

### 🔄 Backup & Sync
- Secure Google Drive integration
- Selective album backup
- Progress tracking during backup
- Easy restoration process
- Account-specific backup management
- Automatic backup status indicators
- Secure authentication with Google accounts

## 🎥 Demo Videos

### 📸 Gallery & Media Features

- [Gallery Overview](https://github.com/user-attachments/assets/355e92dc-b1bc-478f-aa45-31ba4281e4f3)

- [Photo Editing](https://github.com/user-attachments/assets/3ef6a2ef-9cc5-49df-8314-726f5ffb2418)

- [Album Management](https://github.com/user-attachments/assets/3ba9dbfe-99ba-47d4-9e7b-7bae64d19020)

- [Camera Preview](https://github.com/user-attachments/assets/547013b3-dfec-4fad-aa5b-cf810667d348)

### 📝 Journal & Memories

- [Journal Features](https://github.com/user-attachments/assets/34eef0bc-1a1d-4496-8b4c-e6c7d3447f35)

- [Journal Sharing](https://github.com/user-attachments/assets/3e0c854c-6553-4554-975f-ed5ffb96b1a9)

- [Memories & Recaps](https://github.com/user-attachments/assets/5ce43d20-28f8-400e-9f37-1a0299b06936)

### 🤖 AI Features

- [AI Capabilities](https://github.com/user-attachments/assets/10b73108-14ec-4c87-81e1-4b15be1aac2b)

### 🔄 Backup & Additional Features

- [Google Drive Backup](https://github.com/user-attachments/assets/5bdaf89a-a6c5-4342-bd6c-caa202604784)

- [Additional Information](https://github.com/user-attachments/assets/7284e09d-d26e-4756-b388-c02d7804c4f8)


### Prerequisites
- Flutter SDK (version 3.4.0 or higher)
- Dart SDK (version 3.4.0 or higher)
- Android Studio / Xcode for emulators
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/amandangol/reverie.git
cd reverie
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Building for Production

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

## 🛠️ Technical Details

### Architecture
- Built with Flutter for android (currently) compatibility
- Uses Provider for state management
- Implements Material Design 3 for modern UI
- Follows clean architecture principles
- Google Drive API integration for backup functionality

### Key Dependencies
- `provider`: State management
- `shared_preferences`: Local storage
- `photo_manager`: Media handling
- `photo_manager_image_provider`: Image loading
- `url_launcher`: External link handling
- `google_sign_in`: Google authentication
- `googleapis`: Google Drive API integration
- `image_picker`: Camera and gallery access
- `google_mlkit_translation`: Translation services
- `pro_image_editor`: Advanced photo editing
- `translator`: Multi-language support
- `table_calendar`: Calendar view for memories
- `just_audio`: Background music for slideshows
- `pdf`: PDF generation for journal entries


## 🔒 Privacy & Security

Reverie takes your privacy seriously:
- All data is stored locally on your device by default
- Optional Google Drive backup with secure authentication
- No cloud synchronization without explicit permission
- Secure media handling
- Optional data export functionality
- Account-specific backup management
- Secure token management for Google Drive access

## 🤝 Contributing

We welcome contributions! Please read our [Contributing Guidelines](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- The open-source community for their invaluable tools and libraries

## 📞 Support

If you encounter any issues or have questions:
- Open an issue in the GitHub repository
- Contact me personally at icrextha@gmail.com
- Join our community forum

## 🌟 Why Choose Reverie?

1. **Beautiful Design**: Modern, intuitive interface that makes memory-keeping a joy
2. **Privacy-Focused**: Your memories stay on your device with optional cloud backup
3. **AI-Enhanced**: Smart features that make organizing memories easier
4. **Cross-Platform**: Seamless experience on Android for now
5. **Regular Updates**: Continuous improvements and new features
6. **Secure Backup**: Reliable Google Drive integration for your memories
7. **Multi-language Support**: Translate your memories to share with anyone
8. **Built-in Camera**: Capture moments directly in the app

## 📱 App Screenshots

### 🖼️ Gallery & Media

<div align="center">
  <img src="https://github.com/user-attachments/assets/f0bc085a-8cee-47f9-b2a2-3457379847d7" alt="Gallery Home" width="200" height="400" />
  <img src="https://github.com/user-attachments/assets/b519a5c5-a73d-4097-af1c-85bf8fa9d921" alt="Gallery App Drawer" width="200" height="400" />
  <img src="https://github.com/user-attachments/assets/adb08fe5-f531-4de8-ab68-4291598144ab" alt="Gallery Albums" width="200" height="400" />
  <img src="https://github.com/user-attachments/assets/f44ef417-249b-4cde-b6d5-cc78ae557664" alt="Gallery Setting" width="200" height="400" />
  <img src="https://github.com/user-attachments/assets/071593c4-5182-4797-bc6c-61109a028d8f" alt="Media Detail View" width="200" height="400" />
  <img src="https://github.com/user-attachments/assets/857b2ec1-a7b5-4605-b4e1-795e5d4f3a42" alt="Gallery Videos" width="200" height="400" />
  <img src="https://github.com/user-attachments/assets/8a106b96-232c-402d-9292-ba0db9067ef7" alt="Gallery Camera" width="200" height="400" />
</div>

---

### 📔 Journal

<div align="center">
  <img src="https://github.com/user-attachments/assets/579e0273-c119-40bb-978b-0bfdd47c80e3" alt="Journal Home" width="200" height="400" />
  <img src="https://github.com/user-attachments/assets/d18a275d-ace9-4e6c-827b-7dd7c9e4316b" alt="Journal Detail" width="200" height="400" />
  <img src="https://github.com/user-attachments/assets/166e9445-6fac-412e-a8cd-bf23ff30e205" alt="Journal Calendar" width="200" height="400" />
  <img src="https://github.com/user-attachments/assets/2c4d3396-152a-47c1-98dd-4c51f36428dc" alt="Journal Detail" width="200" height="400" />
  <img src="https://github.com/user-attachments/assets/a64bb383-6208-4d0d-bd2b-f776a41f5389" alt="Journal Detail" width="200" height="400" />
  <img src="https://github.com/user-attachments/assets/0adaa6c9-e9e0-4ee9-8309-a3edf5ae1353" alt="Journal Translation" width="200" height="400" />
</div>

---

### 🤖 AI & Media Info

<div align="center">
  <img src="https://github.com/user-attachments/assets/0ae82b7c-d5bb-4c12-b064-3342d071ade9" alt="Image Analysis" width="200" height="400" />
  <img src="https://github.com/user-attachments/assets/dd248617-e442-481c-b91a-2d385a02be0d" alt="Object Detection" width="200" height="400" />
  <img src="https://github.com/user-attachments/assets/62a031ff-54a9-4f3e-8a03-ced391dc6df1" alt="Text Recognition" width="200" height="400" />
</div>

<div align="center">
  <img src="https://github.com/user-attachments/assets/cf826926-93f4-4cec-86ec-9d8d240a4274" alt="Media Info" width="200" height="400" />
  <img src="https://github.com/user-attachments/assets/19a27b60-4d50-4d3e-a0ed-b239943a943d" alt="Media Journal" width="200" height="400" />
</div>

### 🌟 Flashbacks & Monthly Recap

<div align="center">
  <img src="https://github.com/user-attachments/assets/2e7bb359-0f69-4b9f-8e2a-4569db0c1e34" alt="Flashback Memories" width="200" height="400" />
  <img src="https://github.com/user-attachments/assets/7c97d312-1bf3-4a98-8eda-cbf67b6c6594" alt="Flashback Memories" width="200" height="400" />
  </div>

---

### ☁️ Backup & Quick Actions

<div align="center">
  <img src="https://github.com/user-attachments/assets/be101790-7f45-4373-9678-ba12400d0696" alt="Google Drive Backup" width="200" height="400" />
  <img src="https://github.com/user-attachments/assets/7f3f4a5f-17dc-4cab-84fe-1e12e0844533" alt="Quick Screen" width="200" height="400" />
</div>
---

Made with ❤️ by amandangol AKA 4m.4n
